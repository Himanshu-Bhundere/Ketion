import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/search_result.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final AppDatabase _database;

  SearchRepositoryImpl(this._database);

  @override
  Future<Result<List<SearchResult>>> searchNotes(String query, {String? typeFilter}) async {
    try {
      // Sanitize the query to treat it as pure text, not FTS syntax.
      // Escape double quotes and wrap in quotes for a phrase match.
      // We append a * for prefix matching.
      final sanitizedQuery = '"${query.replaceAll('"', '""')}"*';

      final String whereClause = typeFilter != null 
          ? 'search_fts MATCH ? AND entityType = ?'
          : 'search_fts MATCH ?';
          
      final variables = typeFilter != null 
          ? [Variable.withString(sanitizedQuery), Variable.withString(typeFilter)]
          : [Variable.withString(sanitizedQuery)];

      final rows = await _database.customSelect(
        '''
        SELECT 
          entityId, 
          pageId, 
          entityType, 
          snippet(search_fts, 3, '<mark>', '</mark>', '...', 64) as snippet
        FROM search_fts
        WHERE $whereClause
        ORDER BY rank
        LIMIT 50
        ''',
        variables: variables,
      ).get();

      final results = rows.map((row) {
        return SearchResult(
          entityId: row.read<String>('entityId'),
          pageId: row.read<String?>('pageId'),
          entityType: row.read<String>('entityType'),
          snippet: row.read<String>('snippet'),
        );
      }).toList();

      return Success(results);
    } catch (e) {
      return Error(StorageFailure('Failed to search notes: $e'));
    }
  }

  @override
  Future<Result<void>> rebuildIndex() async {
    try {
      await _database.rebuildSearchIndex();
      return const Success(null);
    } catch (e) {
      return Error(StorageFailure('Failed to rebuild search index: $e'));
    }
  }
}
