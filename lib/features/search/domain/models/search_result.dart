class SearchResult {
  final String blockId;
  final String pageId;
  final String blockType;
  final String snippet;
  
  // Future enhancements could include page title, rank score, etc.

  const SearchResult({
    required this.blockId,
    required this.pageId,
    required this.blockType,
    required this.snippet,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is SearchResult &&
      other.blockId == blockId &&
      other.pageId == pageId &&
      other.blockType == blockType &&
      other.snippet == snippet;
  }

  @override
  int get hashCode {
    return blockId.hashCode ^
      pageId.hashCode ^
      blockType.hashCode ^
      snippet.hashCode;
  }
}
