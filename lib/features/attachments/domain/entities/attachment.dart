import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment.freezed.dart';
part 'attachment.g.dart';

@freezed
class Attachment with _$Attachment {
  const factory Attachment({
    required String id,
    String? driveFileId,
    String? localPath,
    String? mimeType,
    String? checksumSha256,
    int? fileSize,
    int? width,
    int? height,
    int? duration,
    String? thumbnailPath,
    String? uploadStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int version,
    @Default(false) bool deleted,
  }) = _Attachment;

  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);
}
