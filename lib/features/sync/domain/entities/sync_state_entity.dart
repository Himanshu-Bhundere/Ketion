import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_state_entity.freezed.dart';
part 'sync_state_entity.g.dart';

@freezed
class SyncStateEntity with _$SyncStateEntity {
  const factory SyncStateEntity({
    required String deviceId,
    required String provider,
    @Default(0) int lastSyncedVersion,
    DateTime? lastSyncTime,
    String? remoteSyncCursor,
  }) = _SyncStateEntity;

  factory SyncStateEntity.fromJson(Map<String, dynamic> json) => _$SyncStateEntityFromJson(json);
}
