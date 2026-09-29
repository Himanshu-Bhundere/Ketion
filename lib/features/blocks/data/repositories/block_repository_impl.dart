import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/utils/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/database/app_database.dart';
import '../../../editor/domain/models/drop_intent.dart';
import '../../../sync/domain/entities/sync_queue_item.dart';
import '../../../sync/domain/repositories/sync_queue_repository.dart';
import '../../domain/entities/block.dart' as domain;
import '../../domain/repositories/block_repository.dart';
import '../models/block_mapper.dart';

class BlockRepositoryImpl implements BlockRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueueRepository;
  final AppLogger _logger;

  BlockRepositoryImpl(
    this._db,
    this._syncQueueRepository,
    this._logger,
  );

  Future<void> _enqueueOrThrow(SyncQueueItem item) async {
    final result = await _syncQueueRepository.enqueueOrCoalesce(item);
    if (result is Error) {
      throw Exception('Failed to enqueue sync item: ${result.failure.message}');
    }
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
      final block = await (_db.select(_db.blocks)..where((t) => t.id.equals(id))).getSingleOrNull();

      if (block == null) {
        return const Error(StorageFailure('Block not found'));
      }

      return Success(block.toDomain());
    } catch (e, stackTrace) {
      _logger.e('Failed to get block', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateBlock(domain.Block block, {required int expectedVersion}) async {
    try {
      await _db.transaction(() async {
        final newVersion = expectedVersion + 1;
        final newBlock = block.copyWith(
          version: newVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        final updatedRows = await (_db.update(_db.blocks)
              ..where((t) => t.id.equals(block.id))
              ..where((t) => t.version.equals(expectedVersion)))
            .write(newBlock.toCompanion());

        if (updatedRows == 0) {
          throw Exception('Concurrency conflict: expected version $expectedVersion for block ${block.id}');
        }

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
  Future<Result<void>> deleteBlock(String id, {required int expectedVersion}) async {
    try {
      await _db.transaction(() async {
        final existingRecord = await (_db.select(_db.blocks)..where((t) => t.id.equals(id))).getSingleOrNull();

        if (existingRecord == null) {
          return; // Already deleted
        }

        if (existingRecord.version != expectedVersion) {
          throw Exception('Concurrency conflict: expected version $expectedVersion for block $id');
        }

        final newVersion = expectedVersion + 1;
        final now = DateTime.now().toUtc();
        
        final updatedRows = await (_db.update(_db.blocks)
              ..where((t) => t.id.equals(id))
              ..where((t) => t.version.equals(expectedVersion)))
            .write(BlocksCompanion(
          version: Value(newVersion),
          updatedAt: Value(now),
          deleted: const Value(true),
        ),);
        
        if (updatedRows == 0) {
           throw Exception('Concurrency conflict: expected version $expectedVersion for block $id');
        }

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: id,
            operation: 'delete',
            payload: jsonEncode({
              'id': id,
              'version': newVersion,
              'updatedAt': now.toIso8601String(),
              'deletedAt': now.toIso8601String(),
            }),
            batchId: null,
            version: newVersion,
            updatedAt: now,
            createdAt: now,
          ),
        );
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
      final blocks = await (_db.select(_db.blocks)
            ..where((t) => t.pageId.equals(pageId))
            ..where((t) => t.deleted.equals(false))
            ..orderBy([
              (t) => OrderingTerm(expression: t.position, mode: OrderingMode.asc),
            ]))
          .get();

      return Success(blocks.map((b) => b.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get blocks for page', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Block>>> getChildBlocks(String parentBlockId) async {
    try {
      final blocks = await (_db.select(_db.blocks)
            ..where((t) => t.parentBlockId.equals(parentBlockId))
            ..where((t) => t.deleted.equals(false))
            ..orderBy([
              (t) => OrderingTerm(expression: t.position, mode: OrderingMode.asc),
            ]))
          .get();

      return Success(blocks.map((b) => b.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get child blocks', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> splitBlock({
    required domain.Block updatedOriginalBlock,
    required int originalExpectedVersion,
    required domain.Block newBlock,
  }) async {
    try {
      await _db.transaction(() async {
        final originalNewVersion = originalExpectedVersion + 1;
        final updatedOriginalWithVersion = updatedOriginalBlock.copyWith(
          version: originalNewVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        final updatedRows = await (_db.update(_db.blocks)
              ..where((t) => t.id.equals(updatedOriginalBlock.id))
              ..where((t) => t.version.equals(originalExpectedVersion)))
            .write(updatedOriginalWithVersion.toCompanion());
            
        if (updatedRows == 0) {
          throw Exception('Concurrency conflict: expected version $originalExpectedVersion for block ${updatedOriginalBlock.id}');
        }

        await _db.into(_db.blocks).insert(newBlock.toCompanion());

        final batchId = const Uuid().v7();
        final now = DateTime.now().toUtc();

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: updatedOriginalWithVersion.id,
            operation: 'update',
            payload: jsonEncode(updatedOriginalWithVersion.toJson()),
            batchId: batchId,
            version: updatedOriginalWithVersion.version,
            updatedAt: updatedOriginalWithVersion.updatedAt,
            createdAt: now,
          ),
        );

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: newBlock.id,
            operation: 'create',
            payload: jsonEncode(newBlock.toJson()),
            batchId: batchId,
            version: newBlock.version,
            updatedAt: newBlock.updatedAt,
            createdAt: now,
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
    required int survivorExpectedVersion,
    required String deletedBlockId,
    required int victimExpectedVersion,
  }) async {
    try {
      await _db.transaction(() async {
        final survivorNewVersion = survivorExpectedVersion + 1;
        final updatedMergedBlock = mergedBlock.copyWith(
          version: survivorNewVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        final survivorUpdatedRows = await (_db.update(_db.blocks)
              ..where((t) => t.id.equals(mergedBlock.id))
              ..where((t) => t.version.equals(survivorExpectedVersion)))
            .write(updatedMergedBlock.toCompanion());
            
        if (survivorUpdatedRows == 0) {
          throw Exception('Concurrency conflict: expected version $survivorExpectedVersion for block ${mergedBlock.id}');
        }

        final victimNewVersion = victimExpectedVersion + 1;
        final now = DateTime.now().toUtc();

        final victimUpdatedRows = await (_db.update(_db.blocks)
              ..where((t) => t.id.equals(deletedBlockId))
              ..where((t) => t.version.equals(victimExpectedVersion)))
            .write(BlocksCompanion(
          version: Value(victimNewVersion),
          updatedAt: Value(now),
          deleted: const Value(true),
        ),);

        if (victimUpdatedRows == 0) {
           throw Exception('Concurrency conflict: expected version $victimExpectedVersion for block $deletedBlockId');
        }

        final batchId = const Uuid().v7();

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: updatedMergedBlock.id,
            operation: 'update',
            payload: jsonEncode(updatedMergedBlock.toJson()),
            batchId: batchId,
            version: updatedMergedBlock.version,
            updatedAt: updatedMergedBlock.updatedAt,
            createdAt: now,
          ),
        );

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: deletedBlockId,
            operation: 'delete',
            payload: jsonEncode({
              'id': deletedBlockId,
              'version': victimNewVersion,
              'updatedAt': now.toIso8601String(),
              'deletedAt': now.toIso8601String(),
            }),
            batchId: batchId,
            version: victimNewVersion,
            updatedAt: now,
            createdAt: now,
          ),
        );
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to merge blocks', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }
  
  @override
  Future<Result<void>> restoreBlock(String id, String data, String? parentBlockId, double position) async {
      try {
      await _db.transaction(() async {
        final existingRecord = await (_db.select(_db.blocks)..where((t) => t.id.equals(id))).getSingleOrNull();

        if (existingRecord == null) {
          return; // Cannot restore if doesn't exist
        }

        final newVersion = existingRecord.version + 1;
        final now = DateTime.now().toUtc();
        
        final updatedRows = await (_db.update(_db.blocks)
              ..where((t) => t.id.equals(id)))
            .write(BlocksCompanion(
          data: Value(data),
          parentBlockId: Value(parentBlockId),
          position: Value(position),
          version: Value(newVersion),
          updatedAt: Value(now), // Clear deletedAt
        ),);
        
        if (updatedRows == 0) {
           throw Exception('Failed to update block for restore');
        }

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: id,
            operation: 'update',
            payload: jsonEncode({
              'id': id,
              'data': data,
              'parentBlockId': parentBlockId,
              'position': position,
              'version': newVersion,
              'updatedAt': now.toIso8601String(),
              'deletedAt': null,
            }),
            batchId: null,
            version: newVersion,
            updatedAt: now,
            createdAt: now,
          ),
        );
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to restore block', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }
  
  @override
  Future<Result<List<domain.Block>>> moveBlock(String sourceBlockId, DropIntent intent) async {
    // moveBlock logic (usually called from moveBlock command directly).
    // The Gateway no longer uses this, but it's part of the repo interface.
    return const Error(StorageFailure('moveBlock not implemented'));
  }
}
