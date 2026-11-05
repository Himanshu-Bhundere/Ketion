import '../../../../core/utils/result.dart';
import '../models/search_result.dart';
import '../repositories/search_repository.dart';

class SearchNotesUseCase {
  final SearchRepository _repository;

  SearchNotesUseCase(this._repository);

  Future<Result<List<SearchResult>>> call(
    String query, {
    String? typeFilter,
    String? tagFilter,
    String? collectionFilter,
  }) async {
    final trimmedQuery = query.trim();
    final hasMetadataFilter = (tagFilter != null && tagFilter.isNotEmpty) ||
        (collectionFilter != null && collectionFilter.isNotEmpty) ||
        (typeFilter != null && typeFilter.isNotEmpty);

    if (trimmedQuery.isEmpty && !hasMetadataFilter) {
      return const Success([]);
    }

    return _repository.searchNotes(
      trimmedQuery,
      typeFilter: typeFilter,
      tagFilter: tagFilter,
      collectionFilter: collectionFilter,
    );
  }
}
