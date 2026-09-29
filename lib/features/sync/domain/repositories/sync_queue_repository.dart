import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/domain/entities/sync_queue_item.dart';

abstract class SyncQueueRepository {
  /// Enqueue a new sync operation
  Future<Result<void>> enqueue(SyncQueueItem item);

  /// Enqueue a new sync operation or coalesce with an existing pending one
  Future<Result<void>> enqueueOrCoalesce(SyncQueueItem item);

  /// Atomically claim a batch of items for processing and assign them a batchId
  Future<Result<List<SyncQueueItem>>> claimNextBatch({
    int limit = 50,
    required Duration leaseDuration,
  });

  /// Find an existing pending item for an entity
  Future<Result<SyncQueueItem?>> findPendingItem(String table, String entityId);

  /// Update the status of a sync item
  Future<Result<void>> updateStatus(
    String id,
    SyncQueueItemStatus status, {
    int? attemptCount,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    DateTime? leaseUntil,
    String? lastError,
  });

  /// Clear completed items
  Future<Result<void>> clearCompleted();
}
