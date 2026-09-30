import 'package:drift/drift.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/data/models/sync_queue_item_mapper.dart';
import 'package:ketion/features/sync/domain/entities/sync_queue_item.dart';
import 'package:ketion/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:uuid/uuid.dart';

class SyncQueueRepositoryImpl implements SyncQueueRepository {
  final AppDatabase _db;

  SyncQueueRepositoryImpl(this._db);

  @override
  Future<Result<void>> enqueue(SyncQueueItem item) async {
    try {
      await _db
          .into(_db.syncQueue)
          .insertOnConflictUpdate(SyncQueueItemMapper.toCompanion(item));
      return const Success(null);
    } catch (e) {
      return Error(StorageFailure('Failed to enqueue sync item: $e'));
    }
  }

  @override
  Future<Result<void>> enqueueOrCoalesce(SyncQueueItem item) async {
    try {
      final existingResult =
          await findPendingItem(item.entityTable, item.entityId);
      final existing = (existingResult is Success<SyncQueueItem?>)
          ? existingResult.value
          : null;

      if (existing != null) {
        String op = existing.operation;
        if (op == 'create' && item.operation == 'delete') {
          await (_db.delete(_db.syncQueue)
                ..where((tbl) => tbl.id.equals(existing.id)))
              .go();
          return const Success(null);
        } else if (op == 'create' && item.operation == 'update') {
          op = 'create';
        } else {
          op = item.operation; // If item is delete, it becomes delete.
        }

        final statement = _db.update(_db.syncQueue)
          ..where((tbl) => tbl.id.equals(existing.id));
        await statement.write(
          SyncQueueCompanion(
            operation: Value(op),
            payload: Value(item.payload),
            status: Value(SyncQueueItemStatus.pending.name),
            attemptCount: const Value(0),
            nextRetryAt: const Value(null),
            version: Value(item.version),
            updatedAt: Value(item.updatedAt),
          ),
        );
        return const Success(null);
      } else {
        return await enqueue(item);
      }
    } catch (e) {
      return Error(StorageFailure('Failed to enqueueOrCoalesce: $e'));
    }
  }

  @override
  Future<Result<List<SyncQueueItem>>> claimNextBatch({
    int limit = 50,
    required Duration leaseDuration,
  }) async {
    try {
      return await _db.transaction(() async {
        final now = DateTime.now().toUtc();
        final leaseUntil = now.add(leaseDuration);

        // Reclaim stale processing items atomically
        final reclaimStatement = _db.update(_db.syncQueue)
          ..where(
            (tbl) =>
                tbl.status.equals(SyncQueueItemStatus.processing.name) &
                tbl.leaseUntil.isSmallerThanValue(now),
          );
        await reclaimStatement.write(
          SyncQueueCompanion(
            status: Value(SyncQueueItemStatus.pending.name),
            leaseUntil: const Value.absent(),
          ),
        );

        // Try to find an existing batch that is waiting to be retried
        final waitingQuery = _db.select(_db.syncQueue)
          ..where(
            (tbl) =>
                tbl.status.equals(SyncQueueItemStatus.waiting.name) &
                tbl.batchId.isNotNull() &
                (tbl.nextRetryAt.isNull() |
                    tbl.nextRetryAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ])
          ..limit(1);

        final firstWaiting = await waitingQuery.getSingleOrNull();

        List<SyncQueueData> items = [];
        String targetBatchId;

        if (firstWaiting != null) {
          targetBatchId = firstWaiting.batchId!;
          // Select all items belonging to this existing batch
          final batchQuery = _db.select(_db.syncQueue)
            ..where((tbl) => tbl.batchId.equals(targetBatchId));
          items = await batchQuery.get();
        } else {
          // No existing waiting batch, form a new one from pending items
          final pendingQuery = _db.select(_db.syncQueue)
            ..where(
              (tbl) =>
                  tbl.status.equals(SyncQueueItemStatus.pending.name) &
                  tbl.batchId.isNull() &
                  (tbl.nextRetryAt.isNull() |
                      tbl.nextRetryAt.isSmallerOrEqualValue(now)),
            )
            ..orderBy([
              (tbl) => OrderingTerm(
                    expression: tbl.createdAt,
                    mode: OrderingMode.asc,
                  ),
            ])
            ..limit(limit);

          items = await pendingQuery.get();
          targetBatchId = const Uuid().v7();
        }

        if (items.isEmpty) {
          return const Success([]);
        }

        final ids = items.map((e) => e.id).toList();

        final statement = _db.update(_db.syncQueue)
          ..where((tbl) => tbl.id.isIn(ids));
        await statement.write(
          SyncQueueCompanion.custom(
            status: const Variable('processing'),
            batchId: Variable(targetBatchId),
            attemptCount: _db.syncQueue.attemptCount + const Constant(1),
            leaseUntil: Variable.withDateTime(leaseUntil),
          ),
        );

        final updatedQuery = _db.select(_db.syncQueue)
          ..where((tbl) => tbl.id.isIn(ids));
        final updatedRows = await updatedQuery.get();

        return Success(updatedRows.map(SyncQueueItemMapper.fromData).toList());
      });
    } catch (e) {
      return Error(StorageFailure('Failed to claim next batch: $e'));
    }
  }

  @override
  Future<Result<SyncQueueItem?>> findPendingItem(
    String table,
    String entityId,
  ) async {
    try {
      final query = _db.select(_db.syncQueue)
        ..where(
          (tbl) =>
              (tbl.status.equals(SyncQueueItemStatus.pending.name) |
                  tbl.status.equals(SyncQueueItemStatus.waiting.name)) &
              tbl.entityTable.equals(table) &
              tbl.entityId.equals(entityId),
        )
        ..limit(1);
      final result = await query.getSingleOrNull();
      if (result != null) {
        return Success(SyncQueueItemMapper.fromData(result));
      }
      return const Success(null);
    } catch (e) {
      return Error(StorageFailure('Failed to find pending item: $e'));
    }
  }

  @override
  Future<Result<void>> updateStatus(
    String id,
    SyncQueueItemStatus status, {
    int? attemptCount,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    DateTime? leaseUntil,
    String? lastError,
  }) async {
    try {
      final statement = _db.update(_db.syncQueue)
        ..where((tbl) => tbl.id.equals(id));
      await statement.write(
        SyncQueueCompanion(
          status: Value(status.name),
          attemptCount:
              attemptCount != null ? Value(attemptCount) : const Value.absent(),
          lastAttemptAt: lastAttemptAt != null
              ? Value(lastAttemptAt)
              : const Value.absent(),
          nextRetryAt:
              nextRetryAt != null ? Value(nextRetryAt) : const Value.absent(),
          leaseUntil:
              leaseUntil != null ? Value(leaseUntil) : const Value.absent(),
          lastError:
              lastError != null ? Value(lastError) : const Value.absent(),
        ),
      );
      return const Success(null);
    } catch (e) {
      return Error(StorageFailure('Failed to update sync item status: $e'));
    }
  }

  @override
  Future<Result<void>> clearCompleted() async {
    try {
      final statement = _db.delete(_db.syncQueue)
        ..where((tbl) => tbl.status.equals(SyncQueueItemStatus.completed.name));
      await statement.go();
      return const Success(null);
    } catch (e) {
      return Error(StorageFailure('Failed to clear completed sync items: $e'));
    }
  }
}
