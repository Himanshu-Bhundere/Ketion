import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/tag.dart' as domain;
import '../../domain/repositories/tag_repository.dart';
import '../../../sync/domain/repositories/sync_queue_repository.dart';
import '../../../sync/domain/entities/sync_queue_item.dart';
import '../models/tag_mapper.dart';

class TagRepositoryImpl implements TagRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;
  final AppLogger _logger;

  TagRepositoryImpl(this._db, this._syncQueue, this._logger);

  @override
  Future<Result<void>> createTag(domain.Tag tag) async {
    try {
      final newTag =
          tag.copyWith(version: 1, updatedAt: DateTime.now().toUtc());
      await _db.transaction(() async {
        await _db.into(_db.tags).insert(newTag.toCompanion());
        await _syncQueue.enqueueOrCoalesce(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'tags',
            entityId: newTag.id,
            operation: 'create',
            payload: jsonEncode(newTag.toJson()),
            batchId: null,
            version: newTag.version,
            updatedAt: newTag.updatedAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to create tag', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<domain.Tag>> getTag(String id) async {
    try {
      final tagRecord = await (_db.select(_db.tags)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (tagRecord == null) {
        return const Error(StorageFailure('Tag not found'));
      }
      return Success(tagRecord.toDomain());
    } catch (e, stackTrace) {
      _logger.e('Failed to get tag', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateTag(domain.Tag tag) async {
    try {
      await _db.transaction(() async {
        final existingRecord = await (_db.select(_db.tags)
              ..where((t) => t.id.equals(tag.id)))
            .getSingleOrNull();
        if (existingRecord == null) {
          throw Exception('Tag not found');
        }

        final newVersion = existingRecord.version + 1;
        final newTag = tag.copyWith(
          version: newVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        final updatedRows = await (_db.update(_db.tags)
              ..where((t) => t.id.equals(newTag.id)))
            .write(newTag.toCompanion());
        if (updatedRows > 0) {
          await _syncQueue.enqueueOrCoalesce(
            SyncQueueItem(
              id: const Uuid().v7(),
              entityTable: 'tags',
              entityId: newTag.id,
              operation: 'update',
              payload: jsonEncode(newTag.toJson()),
              batchId: null,
              version: newTag.version,
              updatedAt: newTag.updatedAt,
              createdAt: DateTime.now().toUtc(),
            ),
          );
        }
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to update tag', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTag(String id) async {
    try {
      final tagRecord = await getTag(id);
      if (tagRecord is Error) {
        return const Success(null);
      }
      final tag = (tagRecord as Success<domain.Tag>).value;

      await _db.transaction(() async {
        final existingRecord = await (_db.select(_db.tags)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (existingRecord == null) {
          return;
        }

        final newVersion = existingRecord.version + 1;
        final newTag = tag.copyWith(
          deleted: true,
          version: newVersion,
          updatedAt: DateTime.now().toUtc(),
        );

        final updatedRows = await (_db.update(_db.tags)
              ..where((t) => t.id.equals(id)))
            .write(newTag.toCompanion());

        if (updatedRows > 0) {
          await _syncQueue.enqueueOrCoalesce(
            SyncQueueItem(
              id: const Uuid().v7(),
              entityTable: 'tags',
              entityId: id,
              operation: 'delete',
              payload: jsonEncode(newTag.toJson()),
              batchId: null,
              version: newTag.version,
              updatedAt: newTag.updatedAt,
              createdAt: DateTime.now().toUtc(),
            ),
          );
        }
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to delete tag', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Tag>>> getAllTags() async {
    try {
      final records = await (_db.select(_db.tags)
            ..where((t) => t.deleted.equals(false)))
          .get();
      return Success(records.map((r) => r.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get all tags', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Tag>>> getTagsForPage(String pageId) async {
    try {
      final query = _db.select(_db.pageTags).join([
        innerJoin(_db.tags, _db.tags.id.equalsExp(_db.pageTags.tagId)),
      ])
        ..where(
          _db.pageTags.pageId.equals(pageId) & _db.tags.deleted.equals(false),
        );
      final rows = await query.get();
      final tags = rows.map((r) => r.readTable(_db.tags).toDomain()).toList();
      return Success(tags);
    } catch (e, stackTrace) {
      _logger.e('Failed to get tags for page', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> assignTagToPage(String pageId, String tagId) async {
    try {
      await _db.transaction(() async {
        await _db.into(_db.pageTags).insert(
              PageTagsCompanion.insert(pageId: pageId, tagId: tagId),
              mode: InsertMode.insertOrIgnore,
            );
        await _syncQueue.enqueueOrCoalesce(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'page_tags',
            entityId: '$pageId:$tagId',
            operation: 'create',
            payload: jsonEncode({'pageId': pageId, 'tagId': tagId}),
            batchId: null,
            version: 1,
            updatedAt: DateTime.now().toUtc(),
            createdAt: DateTime.now().toUtc(),
          ),
        );
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to assign tag to page', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> removeTagFromPage(String pageId, String tagId) async {
    try {
      await _db.transaction(() async {
        await (_db.delete(_db.pageTags)
              ..where((t) => t.pageId.equals(pageId) & t.tagId.equals(tagId)))
            .go();
        await _syncQueue.enqueueOrCoalesce(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'page_tags',
            entityId: '$pageId:$tagId',
            operation: 'delete',
            payload: jsonEncode({'pageId': pageId, 'tagId': tagId}),
            batchId: null,
            version: 1,
            updatedAt: DateTime.now().toUtc(),
            createdAt: DateTime.now().toUtc(),
          ),
        );
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to remove tag from page', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> setPageTags(String pageId, List<String> tagIds) async {
    try {
      await _db.transaction(() async {
        final existingRecords = await (_db.select(_db.pageTags)
              ..where((t) => t.pageId.equals(pageId)))
            .get();
        final currentTagIds = existingRecords.map((r) => r.tagId).toSet();
        final targetTagIds = tagIds.toSet();

        final toRemove = currentTagIds.difference(targetTagIds);
        for (final tagId in toRemove) {
          await (_db.delete(_db.pageTags)
                ..where((t) => t.pageId.equals(pageId) & t.tagId.equals(tagId)))
              .go();
          await _syncQueue.enqueueOrCoalesce(
            SyncQueueItem(
              id: const Uuid().v7(),
              entityTable: 'page_tags',
              entityId: '$pageId:$tagId',
              operation: 'delete',
              payload: jsonEncode({'pageId': pageId, 'tagId': tagId}),
              batchId: null,
              version: 1,
              updatedAt: DateTime.now().toUtc(),
              createdAt: DateTime.now().toUtc(),
            ),
          );
        }

        final toAdd = targetTagIds.difference(currentTagIds);
        for (final tagId in toAdd) {
          await _db.into(_db.pageTags).insert(
                PageTagsCompanion.insert(pageId: pageId, tagId: tagId),
                mode: InsertMode.insertOrIgnore,
              );
          await _syncQueue.enqueueOrCoalesce(
            SyncQueueItem(
              id: const Uuid().v7(),
              entityTable: 'page_tags',
              entityId: '$pageId:$tagId',
              operation: 'create',
              payload: jsonEncode({'pageId': pageId, 'tagId': tagId}),
              batchId: null,
              version: 1,
              updatedAt: DateTime.now().toUtc(),
              createdAt: DateTime.now().toUtc(),
            ),
          );
        }
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to set page tags', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }
}
