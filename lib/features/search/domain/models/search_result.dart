enum MatchType {
  pageTitle,
  blockContent,
  tag,
  attachment,
  ocr,
  bookmark,
  unknown,
}

class SearchResult {
  final String entityId;
  final String? pageId;
  final String entityType;
  final String snippet;
  final MatchType matchType;

  final String? pageTitle;
  final String? blockType;
  final DateTime? modifiedAt;
  final String? breadcrumb;

  const SearchResult({
    required this.entityId,
    this.pageId,
    required this.entityType,
    required this.snippet,
    this.matchType = MatchType.unknown,
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
        other.matchType == matchType &&
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
        matchType.hashCode ^
        pageTitle.hashCode ^
        blockType.hashCode ^
        modifiedAt.hashCode ^
        breadcrumb.hashCode;
  }
}

class GroupedSearchResult {
  final String groupId; // pageId or entityId for tags
  final String? pageTitle;
  final SearchResult strongestMatch;
  final int matchCount;
  final List<SearchResult> allMatches;

  GroupedSearchResult({
    required this.groupId,
    this.pageTitle,
    required this.strongestMatch,
    required this.matchCount,
    required this.allMatches,
  });
}
