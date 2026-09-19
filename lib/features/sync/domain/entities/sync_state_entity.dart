import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_state_entity.freezed.dart';
part 'sync_state_entity.g.dart';

@freezed
class SyncStateEntity with _$SyncStateEntity {
  const factory SyncStateEntity({
    required String deviceId,
    required String provider,
    String? lastDriveCursor,
    DateTime? lastSyncTime,
  }) = _SyncStateEntity;

  factory SyncStateEntity.fromJson(Map<String, dynamic> json) =>
      _$SyncStateEntityFromJson(json);
}
