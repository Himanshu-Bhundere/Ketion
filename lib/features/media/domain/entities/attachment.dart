import 'package:freezed_annotation/freezed_annotation.dart';
import 'attachment_upload_status.dart';

part 'attachment.freezed.dart';
part 'attachment.g.dart';

@freezed
class Attachment with _$Attachment {
  const factory Attachment({
    required String id,
    required String blockId,
    String? driveFileId,
    String? localPath,
    required String mimeType,
    String? checksumSha256,
    required int fileSize,
    int? width,
    int? height,
    int? duration,
    String? thumbnailPath,
    @Default(AttachmentUploadStatus.pending) AttachmentUploadStatus uploadStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(1) int version,
    @Default(false) bool deleted,
    @Default(false) bool isPinnedOffline,
  }) = _Attachment;

  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);
}
