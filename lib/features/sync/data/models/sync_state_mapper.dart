import 'package:drift/drift.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/sync/domain/entities/sync_state_entity.dart';

class SyncStateMapper {
  static SyncStateEntity fromData(SyncState data) {
    return SyncStateEntity(
      deviceId: data.deviceId,
      provider: data.provider,
      lastSyncedVersion: data.lastSyncedVersion,
      lastSyncTime: data.lastSyncTime,
      remoteSyncCursor: data.remoteSyncCursor,
    );
  }

  static SyncStatesCompanion toCompanion(SyncStateEntity entity) {
    return SyncStatesCompanion(
      deviceId: Value(entity.deviceId),
      provider: Value(entity.provider),
      lastSyncedVersion: Value(entity.lastSyncedVersion),
      lastSyncTime: Value(entity.lastSyncTime),
      remoteSyncCursor: Value(entity.remoteSyncCursor),
    );
  }
}
