import 'package:freezed_annotation/freezed_annotation.dart';

part 'editor_selection.freezed.dart';

@freezed
class TextSelection with _$TextSelection {
  const factory TextSelection({
    required String blockId,
    required int start,
    required int end,
  }) = _TextSelection;
}

@freezed
class DocumentSelection with _$DocumentSelection {
  const factory DocumentSelection({
    required String startBlockId,
    required int startOffset,
    required String endBlockId,
    required int endOffset,
  }) = _DocumentSelection;
}

@freezed
sealed class EditorSelection with _$EditorSelection {
  const factory EditorSelection.text(TextSelection selection) = EditorTextSelection;
  const factory EditorSelection.document(DocumentSelection selection) = EditorDocumentSelection;
  const factory EditorSelection.block(List<String> blockIds) = EditorBlockSelection;
}
