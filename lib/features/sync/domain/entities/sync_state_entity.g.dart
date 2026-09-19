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
      lastDriveCursor: json['lastDriveCursor'] as String?,
      lastSyncTime: json['lastSyncTime'] == null
          ? null
          : DateTime.parse(json['lastSyncTime'] as String),
    );

Map<String, dynamic> _$$SyncStateEntityImplToJson(
        _$SyncStateEntityImpl instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'provider': instance.provider,
      'lastDriveCursor': instance.lastDriveCursor,
      'lastSyncTime': instance.lastSyncTime?.toIso8601String(),
    };
