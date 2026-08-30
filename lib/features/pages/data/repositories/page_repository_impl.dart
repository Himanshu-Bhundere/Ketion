import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/page.dart' as domain;
import '../../domain/repositories/page_repository.dart';
import '../../../sync/domain/repositories/sync_queue_repository.dart';
import '../../../sync/domain/entities/sync_queue_item.dart';
import '../../../blocks/domain/entities/block.dart' as block_domain;
import '../../../blocks/data/models/block_mapper.dart';
import '../models/page_mapper.dart';

class PageRepositoryImpl implements PageRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;
  final AppLogger _logger;

  PageRepositoryImpl(this._db, this._syncQueue, this._logger);

  Future<void> _enqueueOrThrow(SyncQueueItem item) async {
    final result = await _syncQueue.enqueueOrCoalesce(item);
    if (result is Error<void>) {
      throw result.failure;
    }
  }

  @override
  Future<Result<void>> createPage(domain.Page page) async {
    try {
      final now = DateTime.now().toUtc();
      final newPage = page.copyWith(
        version: 1,
        createdAt: now,
        updatedAt: now,
      );
      final initialBlock = block_domain.Block(
        id: const Uuid().v7(),
        pageId: newPage.id,
        type: 'text',
        position: 0,
        data: jsonEncode({'runtimeType': 'text', 'spans': <dynamic>[], 'headingLevel': 0}),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        version: 1,
      );

      await _db.transaction(() async {
        await _db.into(_db.pages).insert(newPage.toCompanion());
        await _db.into(_db.blocks).insert(initialBlock.toCompanion());

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'pages',
            entityId: newPage.id,
            operation: 'create',
            payload: jsonEncode(newPage.toJson()),
            batchId: null,
            version: newPage.version,
            updatedAt: newPage.updatedAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );

        await _enqueueOrThrow(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'blocks',
            entityId: initialBlock.id,
            operation: 'create',
            payload: jsonEncode(initialBlock.toJson()),
            batchId: null,
            version: initialBlock.version,
            updatedAt: initialBlock.updatedAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to create page', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<domain.Page>> getPage(String id) async {
    try {
      final pageRecord = await (_db.select(_db.pages)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (pageRecord == null) {
        return const Error(StorageFailure('Page not found'));
      }
      return Success(pageRecord.toDomain());
    } catch (e, stackTrace) {
      _logger.e('Failed to get page', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updatePage(domain.Page page) async {
    try {
      await _db.transaction(() async {
        final existingRecord = await (_db.select(_db.pages)
              ..where((t) => t.id.equals(page.id)))
            .getSingleOrNull();
        if (existingRecord == null) {
          throw Exception('Page not found');
        }

        final newVersion = existingRecord.version + 1;
        final newPage = page.copyWith(
          version: newVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        final updatedRows = await (_db.update(_db.pages)
              ..where((t) => t.id.equals(newPage.id)))
            .write(newPage.toCompanion());

        if (updatedRows > 0) {
          await _enqueueOrThrow(
            SyncQueueItem(
              id: const Uuid().v7(),
              entityTable: 'pages',
              entityId: newPage.id,
              operation: 'update',
              payload: jsonEncode(newPage.toJson()),
              batchId: null,
              version: newPage.version,
              updatedAt: newPage.updatedAt,
              createdAt: DateTime.now().toUtc(),
            ),
          );
        }
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to update page', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deletePage(String id) async {
    try {
      final pageRecord = await getPage(id);
      if (pageRecord is Error) {
        return const Success(null);
      }
      final page = (pageRecord as Success<domain.Page>).value;

      await _db.transaction(() async {
        final existingRecord = await (_db.select(_db.pages)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (existingRecord == null) {
          return;
        }

        final newVersion = existingRecord.version + 1;
        final newPage = page.copyWith(
          deleted: true,
          version: newVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        final updatedRows = await (_db.update(_db.pages)
              ..where((t) => t.id.equals(id)))
            .write(newPage.toCompanion());

        if (updatedRows > 0) {
          await _enqueueOrThrow(
            SyncQueueItem(
              id: const Uuid().v7(),
              entityTable: 'pages',
              entityId: id,
              operation: 'delete',
              payload: jsonEncode(newPage.toJson()),
              batchId: null,
              version: newPage.version,
              updatedAt: newPage.updatedAt,
              createdAt: DateTime.now().toUtc(),
            ),
          );
        }
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to delete page', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Page>>> getRecentPages() async {
    try {
      final records = await (_db.select(_db.pages)
            ..where((t) => t.deleted.equals(false))
            ..where((t) => t.isArchived.equals(false))
            ..where((t) => t.isTemplate.equals(false))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.updatedAt,
                    mode: OrderingMode.desc,
                  ),
            ])
            ..limit(20))
          .get();
      return Success(records.map((r) => r.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get recent pages', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Page>>> getFavoritePages() async {
    try {
      final records = await (_db.select(_db.pages)
            ..where((t) => t.isFavorite.equals(true))
            ..where((t) => t.deleted.equals(false))
            ..where((t) => t.isTemplate.equals(false))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.updatedAt,
                    mode: OrderingMode.desc,
                  ),
            ]))
          .get();
      return Success(records.map((r) => r.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get favorite pages', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Page>>> getChildPages(String parentId) async {
    try {
      final records = await (_db.select(_db.pages)
            ..where((t) => t.parentPageId.equals(parentId))
            ..where((t) => t.deleted.equals(false))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.createdAt,
                    mode: OrderingMode.asc,
                  ),
            ]))
          .get();
      return Success(records.map((r) => r.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get child pages', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Page>>> getTemplatePages() async {
    try {
      final records = await (_db.select(_db.pages)
            ..where((t) => t.isTemplate.equals(true))
            ..where((t) => t.deleted.equals(false))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.updatedAt,
                    mode: OrderingMode.desc,
                  ),
            ]))
          .get();
      return Success(records.map((r) => r.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get template pages', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }
}
