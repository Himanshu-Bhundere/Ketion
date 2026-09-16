import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/domain/entities/sync_queue_item.dart';

abstract class SyncQueueRepository {
  /// Enqueue a new sync operation
  Future<Result<void>> enqueue(SyncQueueItem item);

  /// Get pending sync operations
  Future<Result<List<SyncQueueItem>>> getPendingItems({int limit = 50});

  /// Find an existing pending item for an entity
  Future<Result<SyncQueueItem?>> findPendingItem(String table, String entityId);

  /// Update the status of a sync item
  Future<Result<void>> updateStatus(
    String id,
    SyncQueueItemStatus status, {
    int? attemptCount,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    String? lastError,
  });

  /// Clear completed items
  Future<Result<void>> clearCompleted();
}
