import '../entities/attachment.dart';

/// Interface for the service that synchronizes attachments to and from cloud storage (Google Drive).
abstract class AttachmentSyncService {
  /// Uploads an attachment to the cloud.
  Future<void> uploadAttachment(Attachment attachment);

  /// Downloads an attachment from the cloud.
  Future<void> downloadAttachment(Attachment attachment);

  /// Cancels an ongoing upload or download for an attachment.
  Future<void> cancelSync(String attachmentId);

  /// Automatically syncs all pending uploads and downloads.
  Future<void> syncPendingAttachments();
}
