class EditorOpenTarget {
  final String pageId;
  final String? targetBlockId;
  final int? textOffset;

  const EditorOpenTarget({
    required this.pageId,
    this.targetBlockId,
    this.textOffset,
  });
}
