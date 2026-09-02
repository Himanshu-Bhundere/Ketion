class SearchResult {
  final String entityId;
  final String? pageId;
  final String entityType;
  final String snippet;

  // Future enhancements could include page title, rank score, etc.
  const SearchResult({
    required this.entityId,
    this.pageId,
    required this.entityType,
    required this.snippet,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchResult &&
        other.entityId == entityId &&
        other.pageId == pageId &&
        other.entityType == entityType &&
        other.snippet == snippet;
  }

  @override
  int get hashCode {
    return entityId.hashCode ^
        pageId.hashCode ^
        entityType.hashCode ^
        snippet.hashCode;
  }
}
