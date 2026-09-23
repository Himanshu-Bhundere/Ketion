import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/page.dart' as domain;
import '../../domain/repositories/page_repository.dart';
import '../models/page_mapper.dart';

class PageRepositoryImpl implements PageRepository {
  final AppDatabase _db;
  final AppLogger _logger;

  PageRepositoryImpl(this._db, this._logger);

  @override
  Future<Result<void>> createPage(domain.Page page) async {
    try {
      final newPage = page.copyWith(version: 1, updatedAt: DateTime.now());
      await _db.transaction(() async {
        await _db.into(_db.pages).insert(newPage.toCompanion());
        await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
          id: const Uuid().v7(),
          entityTable: 'pages',
          entityId: newPage.id,
          operation: 'create',
          payload: Value(jsonEncode(newPage.toJson())),
          createdAt: DateTime.now(),
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
        updatedAt: DateTime.now(),
      );
      await _db.transaction(() async {
        final updatedRows = await (_db.update(_db.pages)
              ..where((t) => t.id.equals(newPage.id)))
            .write(newPage.toCompanion());
        if (updatedRows > 0) {
          await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
            id: const Uuid().v7(),
            entityTable: 'pages',
            entityId: newPage.id,
            operation: 'update',
            payload: Value(jsonEncode(newPage.toJson())),
            createdAt: DateTime.now(),
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
      await _db.transaction(() async {
        final deletedRows =
            await (_db.delete(_db.pages)..where((t) => t.id.equals(id))).go();
        if (deletedRows > 0) {
          await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
            id: const Uuid().v7(),
            entityTable: 'pages',
            entityId: id,
            operation: 'delete',
            payload: const Value(null),
            createdAt: DateTime.now(),
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
