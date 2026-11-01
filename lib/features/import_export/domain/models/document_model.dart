import 'dart:typed_data';
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
    @Default(0) int depth,
    String? parentKey,
    @Default(false) bool isNestedUnderToggle,
  }) = DocParagraph;

  const factory DocumentNode.heading({
    required int level,
    required List<DocumentTextSpan> spans,
    @Default(0) int depth,
    String? parentKey,
    @Default(false) bool isNestedUnderToggle,
  }) = DocHeading;

  const factory DocumentNode.list({
    required String listType, // 'bullet', 'numbered', 'checklist', 'toggle'
    required bool checked,
    required List<DocumentTextSpan> spans,
    @Default(0) int depth,
    String? parentKey,
    @Default(false) bool isNestedUnderToggle,
  }) = DocList;

  const factory DocumentNode.image({
    required String attachmentId,
    String? caption,
    String? fileName,
    Uint8List? imageBytes,
    @Default(true) bool isAvailable,
    @Default(0) int depth,
    String? parentKey,
    @Default(false) bool isNestedUnderToggle,
  }) = DocImage;

  const factory DocumentNode.file({
    required String attachmentId,
    String? caption,
    String? fileName,
    String? mimeType,
    int? fileSize,
    @Default('File') String fileTypeLabel,
    @Default(true) bool isAvailable,
    @Default(0) int depth,
    String? parentKey,
    @Default(false) bool isNestedUnderToggle,
  }) = DocFile;

  const factory DocumentNode.callout({
    required String icon,
    required String color,
    required List<DocumentTextSpan> spans,
    @Default(0) int depth,
    String? parentKey,
    @Default(false) bool isNestedUnderToggle,
  }) = DocCallout;

  const factory DocumentNode.table({
    required int columnCount,
    required List<List<String>> rows,
    @Default(0) int depth,
    String? parentKey,
    @Default(false) bool isNestedUnderToggle,
  }) = DocTable;

  const factory DocumentNode.divider({
    @Default(0) int depth,
    String? parentKey,
    @Default(false) bool isNestedUnderToggle,
  }) = DocDivider;

  const factory DocumentNode.code({
    required String code,
    required String language,
    @Default(0) int depth,
    String? parentKey,
    @Default(false) bool isNestedUnderToggle,
  }) = DocCode;
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
