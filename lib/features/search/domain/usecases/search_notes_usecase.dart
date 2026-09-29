import '../../../../core/utils/result.dart';
import '../models/search_result.dart';
import '../repositories/search_repository.dart';

class SearchNotesUseCase {
  final SearchRepository _repository;

  SearchNotesUseCase(this._repository);

  Future<Result<List<SearchResult>>> call(
    String query, {
    String? typeFilter,
  }) async {
    if (query.trim().isEmpty) {
      return const Success([]);
    }

    return _repository.searchNotes(query.trim(), typeFilter: typeFilter);
  }
}
