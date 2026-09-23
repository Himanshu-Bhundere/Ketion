import 'package:drift/drift.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/data/models/sync_queue_item_mapper.dart';
import 'package:ketion/features/sync/domain/entities/sync_queue_item.dart';
import 'package:ketion/features/sync/domain/repositories/sync_queue_repository.dart';

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
      final existingResult = await findPendingItem(item.entityTable, item.entityId);
      final existing = (existingResult is Success<SyncQueueItem?>) ? existingResult.value : null;

      if (existing != null) {
        // Coalesce
        if (existing.operation == 'create' && item.operation == 'delete') {
          // Create -> Delete collapse: remove entirely
          final statement = _db.delete(_db.syncQueue)..where((tbl) => tbl.id.equals(existing.id));
          await statement.go();
          return const Success(null);
        }

        String op = existing.operation;
        if (op == 'create' && item.operation == 'update') {
          op = 'create';
        } else {
          op = item.operation;
        }

        final statement = _db.update(_db.syncQueue)..where((tbl) => tbl.id.equals(existing.id));
        await statement.write(
          SyncQueueCompanion(
            operation: Value(op),
            payload: Value(item.payload),
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
  Future<Result<List<SyncQueueItem>>> getPendingItems({int limit = 50}) async {
    try {
      return await _db.transaction(() async {
        final now = DateTime.now().toUtc();
        
        // Reclaim stale processing items atomically
        final reclaimStatement = _db.update(_db.syncQueue)
          ..where((tbl) => tbl.status.equals(SyncQueueItemStatus.processing.name) &
                           tbl.leaseUntil.isSmallerThanValue(now),);
        await reclaimStatement.write(
          SyncQueueCompanion(
            status: Value(SyncQueueItemStatus.pending.name),
            leaseUntil: const Value.absent(),
          ),
        );

        final query = _db.select(_db.syncQueue)
          ..where((tbl) =>
            (tbl.status.equals(SyncQueueItemStatus.pending.name) |
             tbl.status.equals(SyncQueueItemStatus.waiting.name)) &
            (tbl.nextRetryAt.isNull() | tbl.nextRetryAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ])
          ..limit(limit);

        final rows = await query.get();
        return Success(rows.map(SyncQueueItemMapper.fromData).toList());
      });
    } catch (e) {
      return Error(StorageFailure('Failed to fetch pending sync items: $e'));
    }
  }

  @override
  Future<Result<SyncQueueItem?>> findPendingItem(String table, String entityId) async {
    try {
      final query = _db.select(_db.syncQueue)
        ..where((tbl) =>
            tbl.status.equals(SyncQueueItemStatus.pending.name) &
            tbl.entityTable.equals(table) &
            tbl.entityId.equals(entityId),)
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
          lastAttemptAt:
              lastAttemptAt != null ? Value(lastAttemptAt) : const Value.absent(),
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
