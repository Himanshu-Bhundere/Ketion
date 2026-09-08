import 'package:drift/drift.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/sync/domain/entities/sync_state_entity.dart';

class SyncStateMapper {
  static SyncStateEntity fromData(SyncStateData data) {
    return SyncStateEntity(
      deviceId: data.deviceId,
      provider: data.provider,
      lastAppliedGeneration: data.lastAppliedGeneration,
      lastSyncTime: data.lastSyncTime,
    );
  }

  static SyncStatesCompanion toCompanion(SyncStateEntity entity) {
    return SyncStatesCompanion(
      deviceId: Value(entity.deviceId),
      provider: Value(entity.provider),
      lastAppliedGeneration: Value(entity.lastAppliedGeneration),
      lastSyncTime: Value(entity.lastSyncTime),
    );
  }
}
