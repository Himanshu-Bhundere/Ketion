import '../../../../core/utils/result.dart';
import '../entities/attachment.dart';

abstract class AttachmentRepository {
  Future<Result<Attachment>> saveAttachment(Attachment attachment);
  Future<Result<Attachment?>> getAttachmentById(String id);
  Future<Result<Attachment?>> getAttachmentByChecksum(String checksum);
  Future<Result<void>> deleteAttachment(String id);
}
