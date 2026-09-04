import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_model.freezed.dart';

@freezed
class ExportDocument with _$ExportDocument {
  const factory ExportDocument({
    required String title,
    required List<DocumentNode> nodes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExportDocument;
}

@freezed
sealed class DocumentNode with _$DocumentNode {
  const factory DocumentNode.paragraph({
    required List<DocumentTextSpan> spans,
  }) = DocParagraph;

  const factory DocumentNode.heading({
    required int level,
    required List<DocumentTextSpan> spans,
  }) = DocHeading;

  const factory DocumentNode.list({
    required String listType, // 'bullet', 'numbered', 'checklist', 'toggle'
    required bool checked,
    required List<DocumentTextSpan> spans,
  }) = DocList;

  const factory DocumentNode.image({
    required String attachmentId,
    String? caption,
  }) = DocImage;

  const factory DocumentNode.file({
    required String attachmentId,
    String? caption,
  }) = DocFile;
}

@freezed
class DocumentTextSpan with _$DocumentTextSpan {
  const factory DocumentTextSpan({
    required String text,
    @Default(false) bool bold,
    @Default(false) bool italic,
    @Default(false) bool underline,
    @Default(false) bool strikethrough,
    @Default(false) bool code,
    String? link,
    String? pageLink,
  }) = _DocumentTextSpan;
}
