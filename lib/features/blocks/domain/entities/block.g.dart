// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BlockImpl _$$BlockImplFromJson(Map<String, dynamic> json) => _$BlockImpl(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      parentBlockId: json['parentBlockId'] as String?,
      type: json['type'] as String,
      position: (json['position'] as num).toDouble(),
      data: json['data'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      deleted: json['deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$BlockImplToJson(_$BlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pageId': instance.pageId,
      'parentBlockId': instance.parentBlockId,
      'type': instance.type,
      'position': instance.position,
      'data': instance.data,
      'version': instance.version,
      'deleted': instance.deleted,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
