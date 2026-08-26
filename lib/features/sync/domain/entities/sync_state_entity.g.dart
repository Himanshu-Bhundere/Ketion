// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_state_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SyncStateEntityImpl _$$SyncStateEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$SyncStateEntityImpl(
      deviceId: json['deviceId'] as String,
      provider: json['provider'] as String,
      lastSyncedVersion: (json['lastSyncedVersion'] as num?)?.toInt() ?? 0,
      lastSyncTime: json['lastSyncTime'] == null
          ? null
          : DateTime.parse(json['lastSyncTime'] as String),
      remoteSyncCursor: json['remoteSyncCursor'] as String?,
    );

Map<String, dynamic> _$$SyncStateEntityImplToJson(
        _$SyncStateEntityImpl instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'provider': instance.provider,
      'lastSyncedVersion': instance.lastSyncedVersion,
      'lastSyncTime': instance.lastSyncTime?.toIso8601String(),
      'remoteSyncCursor': instance.remoteSyncCursor,
    };
