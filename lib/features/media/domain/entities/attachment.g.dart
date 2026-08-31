// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttachmentImpl _$$AttachmentImplFromJson(Map<String, dynamic> json) =>
    _$AttachmentImpl(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      blockId: json['blockId'] as String,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      size: (json['size'] as num).toInt(),
      sha256: json['sha256'] as String,
      relativePath: json['relativePath'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deleted: json['deleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$AttachmentImplToJson(_$AttachmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pageId': instance.pageId,
      'blockId': instance.blockId,
      'fileName': instance.fileName,
      'mimeType': instance.mimeType,
      'size': instance.size,
      'sha256': instance.sha256,
      'relativePath': instance.relativePath,
      'thumbnailPath': instance.thumbnailPath,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deleted': instance.deleted,
    };
