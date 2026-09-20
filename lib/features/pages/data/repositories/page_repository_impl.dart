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
import '../models/page_mapper.dart';

class PageRepositoryImpl implements PageRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;
  final AppLogger _logger;

  PageRepositoryImpl(this._db, this._syncQueue, this._logger);

  @override
  Future<Result<void>> createPage(domain.Page page) async {
    try {
      final newPage = page.copyWith(version: 1, updatedAt: DateTime.now());
      await _db.transaction(() async {
        await _db.into(_db.pages).insert(newPage.toCompanion());
        await _syncQueue.enqueueOrCoalesce(SyncQueueItem(
          id: const Uuid().v7(),
          entityTable: 'pages',
          entityId: newPage.id,
          operation: 'create',
          payload: jsonEncode(newPage.toJson()),
          createdAt: DateTime.now().toUtc(),
        ));
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
      final newPage = page.copyWith(
        version: page.version + 1,
        updatedAt: DateTime.now().toUtc(),
      );
      await _db.transaction(() async {
        final updatedRows = await (_db.update(_db.pages)
              ..where((t) => t.id.equals(newPage.id)))
            .write(newPage.toCompanion());
        if (updatedRows > 0) {
          await _syncQueue.enqueueOrCoalesce(SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'pages',
            entityId: newPage.id,
            operation: 'update',
            payload: jsonEncode(newPage.toJson()),
            createdAt: DateTime.now().toUtc(),
          ));
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

      final newPage = page.copyWith(
        deleted: true,
        version: page.version + 1,
        updatedAt: DateTime.now().toUtc(),
      );

      await _db.transaction(() async {
        final updatedRows = await (_db.update(_db.pages)
              ..where((t) => t.id.equals(id)))
            .write(newPage.toCompanion());
        
        if (updatedRows > 0) {
          await _syncQueue.enqueueOrCoalesce(SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'pages',
            entityId: id,
            operation: 'delete',
            payload: jsonEncode(newPage.toJson()),
            createdAt: DateTime.now().toUtc(),
          ));
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
