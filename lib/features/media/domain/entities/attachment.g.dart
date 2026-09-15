// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttachmentImpl _$$AttachmentImplFromJson(Map<String, dynamic> json) =>
    _$AttachmentImpl(
      id: json['id'] as String,
      blockId: json['blockId'] as String,
      driveFileId: json['driveFileId'] as String?,
      localPath: json['localPath'] as String?,
      mimeType: json['mimeType'] as String,
      checksumSha256: json['checksumSha256'] as String?,
      fileSize: (json['fileSize'] as num).toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      thumbnailPath: json['thumbnailPath'] as String?,
      uploadStatus: $enumDecodeNullable(
              _$AttachmentUploadStatusEnumMap, json['uploadStatus']) ??
          AttachmentUploadStatus.pending,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: (json['version'] as num?)?.toInt() ?? 1,
      deleted: json['deleted'] as bool? ?? false,
      isPinnedOffline: json['isPinnedOffline'] as bool? ?? false,
    );

Map<String, dynamic> _$$AttachmentImplToJson(_$AttachmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'blockId': instance.blockId,
      'driveFileId': instance.driveFileId,
      'localPath': instance.localPath,
      'mimeType': instance.mimeType,
      'checksumSha256': instance.checksumSha256,
      'fileSize': instance.fileSize,
      'width': instance.width,
      'height': instance.height,
      'duration': instance.duration,
      'thumbnailPath': instance.thumbnailPath,
      'uploadStatus': _$AttachmentUploadStatusEnumMap[instance.uploadStatus]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'version': instance.version,
      'deleted': instance.deleted,
      'isPinnedOffline': instance.isPinnedOffline,
    };

const _$AttachmentUploadStatusEnumMap = {
  AttachmentUploadStatus.pending: 'pending',
  AttachmentUploadStatus.compressing: 'compressing',
  AttachmentUploadStatus.uploading: 'uploading',
  AttachmentUploadStatus.uploaded: 'uploaded',
  AttachmentUploadStatus.failed: 'failed',
  AttachmentUploadStatus.cancelled: 'cancelled',
};
