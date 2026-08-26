// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SyncQueueItemImpl _$$SyncQueueItemImplFromJson(Map<String, dynamic> json) =>
    _$SyncQueueItemImpl(
      id: json['id'] as String,
      entityTable: json['entityTable'] as String,
      entityId: json['entityId'] as String,
      operation: json['operation'] as String,
      payload: json['payload'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'pending',
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$SyncQueueItemImplToJson(_$SyncQueueItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entityTable': instance.entityTable,
      'entityId': instance.entityId,
      'operation': instance.operation,
      'payload': instance.payload,
      'createdAt': instance.createdAt.toIso8601String(),
      'status': instance.status,
      'retryCount': instance.retryCount,
      'errorMessage': instance.errorMessage,
    };
