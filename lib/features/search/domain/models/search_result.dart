class SearchResult {
  final String entityId;
  final String? pageId;
  final String entityType;
  final String snippet;

  final String? pageTitle;
  final String? blockType;
  final DateTime? modifiedAt;
  final String? breadcrumb;

  const SearchResult({
    required this.entityId,
    this.pageId,
    required this.entityType,
    required this.snippet,
    this.pageTitle,
    this.blockType,
    this.modifiedAt,
    this.breadcrumb,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchResult &&
        other.entityId == entityId &&
        other.pageId == pageId &&
        other.entityType == entityType &&
        other.snippet == snippet &&
        other.pageTitle == pageTitle &&
        other.blockType == blockType &&
        other.modifiedAt == modifiedAt &&
        other.breadcrumb == breadcrumb;
  }

  @override
  int get hashCode {
    return entityId.hashCode ^
        pageId.hashCode ^
        entityType.hashCode ^
        snippet.hashCode ^
        pageTitle.hashCode ^
        blockType.hashCode ^
        modifiedAt.hashCode ^
        breadcrumb.hashCode;
  }
}
