import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment.freezed.dart';
part 'attachment.g.dart';

@freezed
class Attachment with _$Attachment {
  const factory Attachment({
    required String id,
    required String pageId,
    required String blockId,
    required String fileName,
    required String mimeType,
    required int size,
    required String sha256,
    required String relativePath,
    String? thumbnailPath,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool deleted,
  }) = _Attachment;

  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);
}
