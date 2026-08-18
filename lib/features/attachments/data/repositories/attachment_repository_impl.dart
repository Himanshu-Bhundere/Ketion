import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart' hide Attachment;
import '../../../../core/database/app_database.dart' as db show Attachment;
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/repositories/attachment_repository.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  final AppDatabase _database;

  AttachmentRepositoryImpl(this._database);

  Attachment _fromDb(db.Attachment data) {
    return Attachment(
      id: data.id,
      driveFileId: data.driveFileId,
      localPath: data.localPath,
      mimeType: data.mimeType,
      checksumSha256: data.checksumSha256,
      fileSize: data.fileSize,
      width: data.width,
      height: data.height,
      duration: data.duration,
      thumbnailPath: data.thumbnailPath,
      uploadStatus: data.uploadStatus,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      version: data.version,
      deleted: data.deleted,
    );
  }

  AttachmentsCompanion _toDb(Attachment entity) {
    return AttachmentsCompanion(
      id: Value(entity.id),
      driveFileId: Value(entity.driveFileId),
      localPath: Value(entity.localPath),
      mimeType: Value(entity.mimeType),
      checksumSha256: Value(entity.checksumSha256),
      fileSize: Value(entity.fileSize),
      width: Value(entity.width),
      height: Value(entity.height),
      duration: Value(entity.duration),
      thumbnailPath: Value(entity.thumbnailPath),
      uploadStatus: Value(entity.uploadStatus),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      version: Value(entity.version),
      deleted: Value(entity.deleted),
    );
  }

  @override
  Future<Result<Attachment>> saveAttachment(Attachment attachment) async {
    try {
      await _database.into(_database.attachments).insertOnConflictUpdate(_toDb(attachment));
      return Success(attachment);
    } catch (e) {
      return Error(StorageFailure('Failed to save attachment: $e'));
    }
  }

  @override
  Future<Result<Attachment?>> getAttachmentById(String id) async {
    try {
      final query = _database.select(_database.attachments)..where((tbl) => tbl.id.equals(id));
      final result = await query.getSingleOrNull();
      if (result != null) {
        return Success(_fromDb(result));
      }
      return const Success(null);
    } catch (e) {
      return Error(StorageFailure('Failed to fetch attachment by id: $e'));
    }
  }

  @override
  Future<Result<Attachment?>> getAttachmentByChecksum(String checksum) async {
    try {
      final query = _database.select(_database.attachments)..where((tbl) => tbl.checksumSha256.equals(checksum));
      final result = await query.getSingleOrNull();
      if (result != null) {
        return Success(_fromDb(result));
      }
      return const Success(null);
    } catch (e) {
      return Error(StorageFailure('Failed to fetch attachment by checksum: $e'));
    }
  }

  @override
  Future<Result<void>> deleteAttachment(String id) async {
    try {
      await (_database.update(_database.attachments)..where((tbl) => tbl.id.equals(id))).write(
        AttachmentsCompanion(
          deleted: const Value(true),
          version: const Value(1), // Increment version normally, simplification here
          updatedAt: Value(DateTime.now()),
        ),
      );
      return const Success(null);
    } catch (e) {
      return Error(StorageFailure('Failed to soft delete attachment: $e'));
    }
  }
}
