import '../../../../core/utils/result.dart';
import '../models/search_result.dart';
import '../repositories/search_repository.dart';

class SearchNotesUseCase {
  final SearchRepository _repository;

  SearchNotesUseCase(this._repository);

  Future<Result<List<SearchResult>>> call(String query, {String? typeFilter}) async {
    if (query.trim().isEmpty) {
      return const Success([]);
    }

    // Process query to match FTS syntax (e.g. wildcard prefix) if needed,
    // or just pass it directly. A simple wildcard appender:
    final sanitized = query.trim().replaceAll('"', '""');
    final ftsQuery = '"$sanitized"*'; // simple prefix search

    return _repository.searchNotes(ftsQuery, typeFilter: typeFilter);
  }
}
