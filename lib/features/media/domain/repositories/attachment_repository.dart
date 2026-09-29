import 'package:file_picker/file_picker.dart';
import '../entities/attachment.dart';

/// Repository for managing media attachments.
abstract class AttachmentRepository {
  /// Saves a new attachment from a local source file.
  Future<Attachment> saveAttachment({
    required String pageId,
    required String blockId,
    required PlatformFile sourceFile,
    required String mimeType,
  });

  /// Retrieves an attachment by its ID.
  Future<Attachment?> getAttachment(String id);

  /// Retrieves all attachments for a specific page.
  Future<List<Attachment>> getAttachmentsForPage(String pageId);

  /// Deletes an attachment by marking it as deleted in the DB and removing the file.
  Future<void> deleteAttachment(String id);

  /// Resolves the absolute path for an attachment's relative path.
  Future<String> resolveAttachmentPath(Attachment attachment);

  /// Performs garbage collection to remove physical files that are no longer referenced
  /// by any non-deleted attachment in the database.
  Future<void> garbageCollectOrphanedFiles();

  /// Updates the sync status and drive file ID for an attachment.
  Future<void> updateAttachmentSyncStatus(
    String id,
    String uploadStatus, {
    String? driveFileId,
    String? localPath,
  });

  /// Retrieves all attachments that are pending upload or failed.
  Future<List<Attachment>> getPendingUploads();

  /// Retrieves all attachments that are pending download (have a driveFileId but no local file).
  Future<List<Attachment>> getPendingDownloads();
}
