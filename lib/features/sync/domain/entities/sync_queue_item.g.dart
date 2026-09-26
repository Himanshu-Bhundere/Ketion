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
      batchId: json['batchId'] as String?,
      version: (json['version'] as num?)?.toInt(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status:
          $enumDecodeNullable(_$SyncQueueItemStatusEnumMap, json['status']) ??
              SyncQueueItemStatus.pending,
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt'] as String),
      nextRetryAt: json['nextRetryAt'] == null
          ? null
          : DateTime.parse(json['nextRetryAt'] as String),
      leaseUntil: json['leaseUntil'] == null
          ? null
          : DateTime.parse(json['leaseUntil'] as String),
      lastError: json['lastError'] as String?,
    );

Map<String, dynamic> _$$SyncQueueItemImplToJson(_$SyncQueueItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entityTable': instance.entityTable,
      'entityId': instance.entityId,
      'operation': instance.operation,
      'payload': instance.payload,
      'batchId': instance.batchId,
      'version': instance.version,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'status': _$SyncQueueItemStatusEnumMap[instance.status]!,
      'attemptCount': instance.attemptCount,
      'lastAttemptAt': instance.lastAttemptAt?.toIso8601String(),
      'nextRetryAt': instance.nextRetryAt?.toIso8601String(),
      'leaseUntil': instance.leaseUntil?.toIso8601String(),
      'lastError': instance.lastError,
    };

const _$SyncQueueItemStatusEnumMap = {
  SyncQueueItemStatus.pending: 'pending',
  SyncQueueItemStatus.processing: 'processing',
  SyncQueueItemStatus.waiting: 'waiting',
  SyncQueueItemStatus.failed: 'failed',
  SyncQueueItemStatus.completed: 'completed',
};
