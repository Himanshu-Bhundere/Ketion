import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/attachment.dart' as domain;
import '../../domain/entities/attachment_upload_status.dart';

extension AttachmentMapper on db.AttachmentData {
  domain.Attachment toDomain() {
    return domain.Attachment(
      id: id,
      blockId: blockId,
      driveFileId: driveFileId,
      localPath: localPath,
      mimeType: mimeType,
      checksumSha256: checksumSha256,
      fileSize: fileSize,
      width: width,
      height: height,
      duration: duration,
      thumbnailPath: thumbnailPath,
      uploadStatus: AttachmentUploadStatus.fromString(uploadStatus),
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      deleted: deleted,
      isPinnedOffline: isPinnedOffline,
    );
  }
}

extension DomainAttachmentMapper on domain.Attachment {
  db.AttachmentsCompanion toCompanion() {
    return db.AttachmentsCompanion.insert(
      id: id,
      blockId: blockId,
      driveFileId: drift.Value(driveFileId),
      localPath: drift.Value(localPath),
      mimeType: mimeType,
      checksumSha256: drift.Value(checksumSha256),
      fileSize: fileSize,
      width: drift.Value(width),
      height: drift.Value(height),
      duration: drift.Value(duration),
      thumbnailPath: drift.Value(thumbnailPath),
      uploadStatus: drift.Value(uploadStatus.value),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
      version: drift.Value(version),
      deleted: drift.Value(deleted),
      isPinnedOffline: drift.Value(isPinnedOffline),
    );
  }
}
