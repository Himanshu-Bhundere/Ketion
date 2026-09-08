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
  Future<Result<List<SyncQueueItem>>> getPendingItems({int limit = 50}) async {
    try {
      final query = _db.select(_db.syncQueue)
        ..where((tbl) => tbl.status.equals('pending'))
        ..orderBy([
          (tbl) =>
              OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
        ])
        ..limit(limit);

      final rows = await query.get();
      return Success(rows.map(SyncQueueItemMapper.fromData).toList());
    } catch (e) {
      return Error(StorageFailure('Failed to fetch pending sync items: $e'));
    }
  }

  @override
  Future<Result<void>> updateStatus(
    String id,
    String status, {
    int? attemptCount,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    String? lastError,
  }) async {
    try {
      final statement = _db.update(_db.syncQueue)
        ..where((tbl) => tbl.id.equals(id));
      await statement.write(
        SyncQueueCompanion(
          status: Value(status),
          attemptCount:
              attemptCount != null ? Value(attemptCount) : const Value.absent(),
          lastAttemptAt:
              lastAttemptAt != null ? Value(lastAttemptAt) : const Value.absent(),
          nextRetryAt:
              nextRetryAt != null ? Value(nextRetryAt) : const Value.absent(),
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
        ..where((tbl) => tbl.status.equals('completed'));
      await statement.go();
      return const Success(null);
    } catch (e) {
      return Error(StorageFailure('Failed to clear completed sync items: $e'));
    }
  }
}
