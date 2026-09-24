import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/collection.dart' as domain;
import '../../domain/repositories/collection_repository.dart';
import '../../../sync/domain/repositories/sync_queue_repository.dart';
import '../../../sync/domain/entities/sync_queue_item.dart';
import '../models/collection_mapper.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;
  final AppLogger _logger;

  CollectionRepositoryImpl(this._db, this._syncQueue, this._logger);

  @override
  Future<Result<void>> createCollection(domain.Collection collection) async {
    try {
      final newCollection =
          collection.copyWith(version: 1, updatedAt: DateTime.now().toUtc());
      await _db.transaction(() async {
        await _db.into(_db.collections).insert(newCollection.toCompanion());
        await _syncQueue.enqueueOrCoalesce(SyncQueueItem(
          id: const Uuid().v7(),
          entityTable: 'collections',
          entityId: newCollection.id,
          operation: 'create',
          payload: jsonEncode(newCollection.toJson()),
          createdAt: DateTime.now().toUtc(),
        ),);
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to create collection', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<domain.Collection>> getCollection(String id) async {
    try {
      final collectionRecord = await (_db.select(_db.collections)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (collectionRecord == null) {
        return const Error(StorageFailure('Collection not found'));
      }
      return Success(collectionRecord.toDomain());
    } catch (e, stackTrace) {
      _logger.e('Failed to get collection', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateCollection(domain.Collection collection) async {
    try {
      final newCollection = collection.copyWith(
        version: collection.version + 1,
        updatedAt: DateTime.now().toUtc(),
      );
      await _db.transaction(() async {
        final updatedRows = await (_db.update(_db.collections)
              ..where((t) => t.id.equals(newCollection.id)))
            .write(newCollection.toCompanion());
        if (updatedRows > 0) {
          await _syncQueue.enqueueOrCoalesce(SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'collections',
            entityId: newCollection.id,
            operation: 'update',
            payload: jsonEncode(newCollection.toJson()),
            createdAt: DateTime.now().toUtc(),
          ),);
        }
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to update collection', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteCollection(String id) async {
    try {
      final collectionRecord = await getCollection(id);
      if (collectionRecord is Error) {
        return const Success(null);
      }
      final collection = (collectionRecord as Success<domain.Collection>).value;

      final newCollection = collection.copyWith(
        deleted: true,
        version: collection.version + 1,
        updatedAt: DateTime.now().toUtc(),
      );

      await _db.transaction(() async {
        final updatedRows = await (_db.update(_db.collections)
              ..where((t) => t.id.equals(id)))
            .write(newCollection.toCompanion());

        if (updatedRows > 0) {
          await _syncQueue.enqueueOrCoalesce(SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'collections',
            entityId: id,
            operation: 'delete',
            payload: jsonEncode(newCollection.toJson()),
            createdAt: DateTime.now().toUtc(),
          ),);
        }
      });
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to delete collection', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Collection>>> getAllCollections() async {
    try {
      final records = await (_db.select(_db.collections)
            ..where((t) => t.deleted.equals(false)))
          .get();
      return Success(records.map((r) => r.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get all collections', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }
}
