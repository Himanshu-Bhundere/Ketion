import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/domain/entities/sync_state_entity.dart';

abstract class SyncStateRepository {
  /// Get the current sync state for a device and provider
  Future<Result<SyncStateEntity?>> getSyncState(String deviceId, String provider);

  /// Save or update the sync state
  Future<Result<void>> saveSyncState(SyncStateEntity state);
}
