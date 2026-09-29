import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/block.dart' as domain;
import '../../domain/repositories/block_repository.dart';
import '../../../sync/domain/repositories/sync_queue_repository.dart';
import '../../../sync/domain/entities/sync_queue_item.dart';
import '../../../editor/domain/models/drop_intent.dart';
import '../../../editor/domain/services/block_tree_service.dart';
import '../models/block_mapper.dart';

class BlockRepositoryImpl implements BlockRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;
  final AppLogger _logger;

  BlockRepositoryImpl(this._db, this._syncQueue, this._logger);

  Future<void> _enqueueOrThrow(SyncQueueItem item) async {
    final result = await _syncQueue.enqueueOrCoalesce(item);
    if (result is Error<void>) throw result.failure;
  }

  @override
  Future<Result<void>> createBlock(domain.Block block) async {
    try {
      await _db.transaction(() async {
        await _db.into(_db.blocks).insert(block.toCompanion());
        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: block.id,
            operation: 'create',
            payload: jsonEncode(block.toJson()),
            batchId: null,
            version: block.version,
            updatedAt: block.updatedAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to create block', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<domain.Block>> getBlock(String id) async {
    try {
      final blockRecord = await (_db.select(_db.blocks)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (blockRecord == null) {
        return const Error(StorageFailure('Block not found'));
      }
      return Success(blockRecord.toDomain());
    } catch (e, stackTrace) {
      _logger.e('Failed to get block', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateBlock(domain.Block block) async {
    try {
      await _db.transaction(() async {
        final existingRecord = await (_db.select(_db.blocks)
              ..where((t) => t.id.equals(block.id)))
            .getSingleOrNull();
        if (existingRecord == null) {
          throw Exception('Block not found');
        }

        final newVersion = existingRecord.version + 1;
        final newBlock = block.copyWith(
          version: newVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        await _db
            .into(_db.blocks)
            .insertOnConflictUpdate(newBlock.toCompanion());

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: newBlock.id,
            operation: 'update',
            payload: jsonEncode(newBlock.toJson()),
            batchId: null,
            version: newBlock.version,
            updatedAt: newBlock.updatedAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to update block', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteBlock(String id) async {
    try {
      final blockRecord = await getBlock(id);
      if (blockRecord.isError) {
        return const Success(null);
      }
      final block = (blockRecord as Success<domain.Block>).value;

      await _db.transaction(() async {
        final existingRecord = await (_db.select(_db.blocks)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (existingRecord == null) {
          return;
        }

        final newVersion = existingRecord.version + 1;
        final newBlock = block.copyWith(
          deleted: true,
          version: newVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        final updatedRows = await (_db.update(_db.blocks)
              ..where((t) => t.id.equals(id)))
            .write(newBlock.toCompanion());

        if (updatedRows > 0) {
          await _enqueueOrThrow(
            SyncQueueItem(
              id: const Uuid().v7(),
              entityTable: 'blocks',
              entityId: id,
              operation: 'delete',
              payload: jsonEncode(newBlock.toJson()),
              batchId: null,
              version: newBlock.version,
              updatedAt: newBlock.updatedAt,
              createdAt: DateTime.now().toUtc(),
            ),
          );
        }
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to delete block', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Block>>> getBlocksForPage(String pageId) async {
    try {
      final records = await (_db.select(_db.blocks)
            ..where((t) => t.pageId.equals(pageId))
            ..where((t) => t.deleted.equals(false))
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.position, mode: OrderingMode.asc),
            ]))
          .get();
      return Success(records.map((r) => r.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get blocks for page', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Block>>> getChildBlocks(
    String parentBlockId,
  ) async {
    try {
      final records = await (_db.select(_db.blocks)
            ..where((t) => t.parentBlockId.equals(parentBlockId))
            ..where((t) => t.deleted.equals(false))
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.position, mode: OrderingMode.asc),
            ]))
          .get();
      return Success(records.map((r) => r.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get child blocks', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Block>>> moveBlock(
      String sourceBlockId, DropIntent intent,) async {
    try {
      final result = await _db.transaction(() async {
        final sourceRecord = await (_db.select(_db.blocks)
              ..where((t) => t.id.equals(sourceBlockId)))
            .getSingleOrNull();
        if (sourceRecord == null) {
          return const Error<List<domain.Block>>(
              StorageFailure('Source block not found'),);
        }
        final sourceBlockDomain = sourceRecord.toDomain();
        if (sourceBlockDomain.deleted) {
          return const Error<List<domain.Block>>(
              StorageFailure('Source block is deleted'),);
        }

        final targetId = intent.when(
          before: (id) => id,
          after: (id) => id,
          child: (id) => id,
          unnest: (id) => id,
        );

        final targetRecord = await (_db.select(_db.blocks)
              ..where((t) => t.id.equals(targetId)))
            .getSingleOrNull();
        if (targetRecord == null) {
          return const Error<List<domain.Block>>(StorageFailure('Target block not found'));
        }
        final targetBlockDomain = targetRecord.toDomain();
        if (targetBlockDomain.deleted) {
          return const Error<List<domain.Block>>(StorageFailure('Target block is deleted'));
        }

        if (sourceBlockDomain.pageId != targetBlockDomain.pageId) {
          return const Error<List<domain.Block>>(StorageFailure('Cannot move blocks between pages'));
        }

        // Fetch parent chain of target to check for cycles and unnest
        final parentChain = <domain.Block>[];
        String? currentParentId = targetBlockDomain.parentBlockId;
        while (currentParentId != null) {
          final parentRecord = await (_db.select(_db.blocks)
                ..where((t) => t.id.equals(currentParentId!)))
              .getSingleOrNull();
          if (parentRecord != null) {
            parentChain.add(parentRecord.toDomain());
            currentParentId = parentRecord.parentBlockId;
          } else {
            break;
          }
        }

        // Fetch descendants of source to check max depth
        final descendants = <domain.Block>[];
        Future<void> fetchDescendants(String blockId) async {
          final children = await (_db.select(_db.blocks)
                ..where((t) => t.parentBlockId.equals(blockId))
                ..where((t) => t.deleted.equals(false)))
              .get();
          for (final child in children) {
            descendants.add(child.toDomain());
            await fetchDescendants(child.id);
          }
        }
        await fetchDescendants(sourceBlockId);

        // Fetch destination siblings (only the necessary ones to avoid O(N) memory/time)
        final destinationSiblings = <domain.Block>[];
        
        Future<void> fetchNeighborSiblings(String? parentId, double targetPos) async {
          final beforeQuery = _db.select(_db.blocks)
            ..where((t) => t.pageId.equals(sourceBlockDomain.pageId))
            ..where((t) => parentId == null ? t.parentBlockId.isNull() : t.parentBlockId.equals(parentId))
            ..where((t) => t.deleted.equals(false))
            ..where((t) => t.position.isSmallerThanValue(targetPos))
            ..where((t) => t.id.isNotValue(sourceBlockId))
            ..orderBy([(t) => OrderingTerm(expression: t.position, mode: OrderingMode.desc)])
            ..limit(1);
          final beforeRecord = await beforeQuery.getSingleOrNull();
          if (beforeRecord != null) destinationSiblings.add(beforeRecord.toDomain());

          final afterQuery = _db.select(_db.blocks)
            ..where((t) => t.pageId.equals(sourceBlockDomain.pageId))
            ..where((t) => parentId == null ? t.parentBlockId.isNull() : t.parentBlockId.equals(parentId))
            ..where((t) => t.deleted.equals(false))
            ..where((t) => t.position.isBiggerThanValue(targetPos))
            ..where((t) => t.id.isNotValue(sourceBlockId))
            ..orderBy([(t) => OrderingTerm(expression: t.position, mode: OrderingMode.asc)])
            ..limit(1);
          final afterRecord = await afterQuery.getSingleOrNull();
          if (afterRecord != null) destinationSiblings.add(afterRecord.toDomain());
        }

        Future<void> fetchLastChild(String? parentId) async {
          final lastQuery = _db.select(_db.blocks)
            ..where((t) => t.pageId.equals(sourceBlockDomain.pageId))
            ..where((t) => parentId == null ? t.parentBlockId.isNull() : t.parentBlockId.equals(parentId))
            ..where((t) => t.deleted.equals(false))
            ..where((t) => t.id.isNotValue(sourceBlockId))
            ..orderBy([(t) => OrderingTerm(expression: t.position, mode: OrderingMode.desc)])
            ..limit(1);
          final lastRecord = await lastQuery.getSingleOrNull();
          if (lastRecord != null) destinationSiblings.add(lastRecord.toDomain());
        }

        await intent.when(
          before: (_) => fetchNeighborSiblings(targetBlockDomain.parentBlockId, targetBlockDomain.position),
          after: (_) => fetchNeighborSiblings(targetBlockDomain.parentBlockId, targetBlockDomain.position),
          child: (_) => fetchLastChild(targetBlockDomain.id),
          unnest: (_) async {
            final targetParent = parentChain.firstWhere((b) => b.id == targetBlockDomain.parentBlockId, orElse: () => targetBlockDomain);
            await fetchNeighborSiblings(targetParent.parentBlockId, targetParent.position);
          },
        );

        final minimalBlocksMap = <String, domain.Block>{
          sourceBlockDomain.id: sourceBlockDomain,
          targetBlockDomain.id: targetBlockDomain,
        };
        for (final b in parentChain) {
          minimalBlocksMap[b.id] = b;
        }
        for (final b in descendants) {
          minimalBlocksMap[b.id] = b;
        }
        for (final b in destinationSiblings) {
          minimalBlocksMap[b.id] = b;
        }

        final minimalBlocks = minimalBlocksMap.values.toList();

        final updatedBlocks =
            BlockTreeService.moveBlock(sourceBlockId, intent, minimalBlocks);

        if (updatedBlocks.isEmpty) {
          return const Success<List<domain.Block>>([]);
        }

        final sourceBlock = updatedBlocks.first;
        final targetParentId = sourceBlock.parentBlockId;

        // Check for normalization
        final siblings = minimalBlocks
            .where((b) =>
                b.parentBlockId == targetParentId && b.id != sourceBlockId,)
            .toList();
        siblings.add(sourceBlock);
        siblings.sort((a, b) => a.position.compareTo(b.position));

        bool needsNormalization = false;
        for (int i = 0; i < siblings.length - 1; i++) {
          if (siblings[i + 1].position - siblings[i].position < 0.0001) {
            needsNormalization = true;
            break;
          }
        }

        final blocksToUpdate = <domain.Block>[];
        if (needsNormalization) {
          for (int i = 0; i < siblings.length; i++) {
            final b = siblings[i];
            blocksToUpdate.add(b.copyWith(
              position: i * 1000.0,
              updatedAt: DateTime.now().toUtc(),
              version: b.version + 1,
            ),);
          }
        } else {
          blocksToUpdate.add(sourceBlock.copyWith(
            updatedAt: DateTime.now().toUtc(),
            version: sourceBlock.version + 1,
          ),);
        }

        await _db.batch((batch) {
          for (final block in blocksToUpdate) {
            final companion = block.toCompanion().copyWith(id: const Value.absent());
            batch.update(_db.blocks, companion, where: (t) => t.id.equals(block.id));
          }
        });

        for (final block in blocksToUpdate) {
          await _enqueueOrThrow(
            SyncQueueItem(
              id: const Uuid().v7(),
              entityTable: 'blocks',
              entityId: block.id,
              operation: 'update',
              payload: jsonEncode(block.toJson()),
              batchId: null,
              version: block.version,
              updatedAt: block.updatedAt,
              createdAt: DateTime.now().toUtc(),
            ),
          );
        }

        return Success<List<domain.Block>>(blocksToUpdate);
      });
      return result;
    } catch (e, stackTrace) {
      _logger.e('Failed to move block', e, stackTrace);
      return Error<List<domain.Block>>(StorageFailure(e.toString()));
    }
  }
  @override
  Future<Result<void>> splitBlock({
    required domain.Block updatedOriginalBlock,
    required domain.Block newBlock,
  }) async {
    try {
      await _db.transaction(() async {
        final existingRecord = await (_db.select(_db.blocks)
              ..where((t) => t.id.equals(updatedOriginalBlock.id)))
            .getSingleOrNull();
        if (existingRecord == null) {
          throw Exception('Block not found');
        }

        final newVersion = existingRecord.version + 1;
        final updatedBlock = updatedOriginalBlock.copyWith(
          version: newVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        await _db
            .into(_db.blocks)
            .insertOnConflictUpdate(updatedBlock.toCompanion());

        await _db.into(_db.blocks).insert(newBlock.toCompanion());

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: updatedBlock.id,
            operation: 'update',
            payload: jsonEncode(updatedBlock.toJson()),
            batchId: null,
            version: updatedBlock.version,
            updatedAt: updatedBlock.updatedAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: newBlock.id,
            operation: 'create',
            payload: jsonEncode(newBlock.toJson()),
            batchId: null,
            version: newBlock.version,
            updatedAt: newBlock.updatedAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to split block', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> mergeBlocks({
    required domain.Block mergedBlock,
    required String deletedBlockId,
  }) async {
    try {
      await _db.transaction(() async {
        final existingRecord = await (_db.select(_db.blocks)
              ..where((t) => t.id.equals(mergedBlock.id)))
            .getSingleOrNull();
        if (existingRecord == null) {
          throw Exception('Block not found');
        }

        final newVersion = existingRecord.version + 1;
        final updatedBlock = mergedBlock.copyWith(
          version: newVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        await _db
            .into(_db.blocks)
            .insertOnConflictUpdate(updatedBlock.toCompanion());

        final deletedRecord = await (_db.select(_db.blocks)
              ..where((t) => t.id.equals(deletedBlockId)))
            .getSingleOrNull();
        if (deletedRecord == null) {
          throw Exception('Deleted block not found');
        }
        
        final deletedVersion = deletedRecord.version + 1;
        final deletedBlock = deletedRecord.toDomain().copyWith(
          deleted: true,
          version: deletedVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        await _db
            .into(_db.blocks)
            .insertOnConflictUpdate(deletedBlock.toCompanion());

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: updatedBlock.id,
            operation: 'update',
            payload: jsonEncode(updatedBlock.toJson()),
            batchId: null,
            version: updatedBlock.version,
            updatedAt: updatedBlock.updatedAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: deletedBlock.id,
            operation: 'delete',
            payload: jsonEncode(deletedBlock.toJson()),
            batchId: null,
            version: deletedBlock.version,
            updatedAt: deletedBlock.updatedAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to merge blocks', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }
}
