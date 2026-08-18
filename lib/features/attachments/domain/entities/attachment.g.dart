// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttachmentImpl _$$AttachmentImplFromJson(Map<String, dynamic> json) =>
    _$AttachmentImpl(
      id: json['id'] as String,
      driveFileId: json['driveFileId'] as String?,
      localPath: json['localPath'] as String?,
      mimeType: json['mimeType'] as String?,
      checksumSha256: json['checksumSha256'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      thumbnailPath: json['thumbnailPath'] as String?,
      uploadStatus: json['uploadStatus'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: (json['version'] as num).toInt(),
      deleted: json['deleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$AttachmentImplToJson(_$AttachmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driveFileId': instance.driveFileId,
      'localPath': instance.localPath,
      'mimeType': instance.mimeType,
      'checksumSha256': instance.checksumSha256,
      'fileSize': instance.fileSize,
      'width': instance.width,
      'height': instance.height,
      'duration': instance.duration,
      'thumbnailPath': instance.thumbnailPath,
      'uploadStatus': instance.uploadStatus,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'version': instance.version,
      'deleted': instance.deleted,
    };
