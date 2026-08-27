import 'package:drift/drift.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/data/models/sync_state_mapper.dart';
import 'package:ketion/features/sync/domain/entities/sync_state_entity.dart';
import 'package:ketion/features/sync/domain/repositories/sync_state_repository.dart';

class SyncStateRepositoryImpl implements SyncStateRepository {
  final AppDatabase _db;

  SyncStateRepositoryImpl(this._db);

  @override
  Future<Result<SyncStateEntity?>> getSyncState(String deviceId, String provider) async {
    try {
      final query = _db.select(_db.syncStates)
        ..where((tbl) => tbl.deviceId.equals(deviceId) & tbl.provider.equals(provider));

      final row = await query.getSingleOrNull();
      if (row == null) return const Success(null);
      return Success(SyncStateMapper.fromData(row));
    } catch (e) {
      return Error(StorageFailure('Failed to fetch sync state: $e'));
    }
  }

  @override
  Future<Result<void>> saveSyncState(SyncStateEntity state) async {
    try {
      await _db.into(_db.syncStates).insertOnConflictUpdate(SyncStateMapper.toCompanion(state));
      return const Success(null);
    } catch (e) {
      return Error(StorageFailure('Failed to save sync state: $e'));
    }
  }
}
