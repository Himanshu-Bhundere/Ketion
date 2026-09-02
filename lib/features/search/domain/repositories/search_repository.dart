import '../../../../core/utils/result.dart';
import '../models/search_result.dart';

abstract class SearchRepository {
  /// Searches the blocks FTS table and returns a list of results.
  ///
  /// The [query] is passed directly to the FTS MATCH operator.
  Future<Result<List<SearchResult>>> searchNotes(String query, {String? typeFilter});

  /// Rebuilds the search index manually (useful during migrations or restore).
  Future<Result<void>> rebuildIndex();
}
