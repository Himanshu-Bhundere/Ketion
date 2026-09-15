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
      status: SyncQueueItemStatus.values.firstWhere(
        (e) => e.name == data.status,
        orElse: () => SyncQueueItemStatus.pending,
      ),
      attemptCount: data.attemptCount,
      lastAttemptAt: data.lastAttemptAt,
      nextRetryAt: data.nextRetryAt,
      leaseUntil: data.leaseUntil,
      lastError: data.lastError,
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
      status: Value(entity.status.name),
      attemptCount: Value(entity.attemptCount),
      lastAttemptAt: Value(entity.lastAttemptAt),
      nextRetryAt: Value(entity.nextRetryAt),
      leaseUntil: Value(entity.leaseUntil),
      lastError: Value(entity.lastError),
    );
  }
}
