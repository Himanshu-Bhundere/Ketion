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
      lastAppliedGeneration:
          (json['lastAppliedGeneration'] as num?)?.toInt() ?? 0,
      pageCursor: json['pageCursor'] as String?,
      lastSyncTime: json['lastSyncTime'] == null
          ? null
          : DateTime.parse(json['lastSyncTime'] as String),
    );

Map<String, dynamic> _$$SyncStateEntityImplToJson(
        _$SyncStateEntityImpl instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'provider': instance.provider,
      'lastAppliedGeneration': instance.lastAppliedGeneration,
      'pageCursor': instance.pageCursor,
      'lastSyncTime': instance.lastSyncTime?.toIso8601String(),
    };
