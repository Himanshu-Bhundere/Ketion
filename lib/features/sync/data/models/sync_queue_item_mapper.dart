import 'package:drift/drift.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/sync/domain/entities/sync_queue_item.dart';

class SyncQueueItemMapper {
  static SyncQueueItem fromData(SyncQueueData data) {
    return SyncQueueItem(
      id: data.id,
      entityTable: data.entityTable,
      entityId: data.entityId,
      operation: data.operation,
      payload: data.payload,
      createdAt: data.createdAt,
      status: data.status,
      retryCount: data.retryCount,
      errorMessage: data.errorMessage,
    );
  }

  static SyncQueueCompanion toCompanion(SyncQueueItem entity) {
    return SyncQueueCompanion(
      id: Value(entity.id),
      entityTable: Value(entity.entityTable),
      entityId: Value(entity.entityId),
      operation: Value(entity.operation),
      payload: Value(entity.payload),
      createdAt: Value(entity.createdAt),
      status: Value(entity.status),
      retryCount: Value(entity.retryCount),
      errorMessage: Value(entity.errorMessage),
    );
  }
}
