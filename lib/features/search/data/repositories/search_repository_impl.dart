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
  Future<Result<List<SearchResult>>> searchNotes(String query) async {
    try {
      final rows = await _database.customSelect(
        '''
        SELECT 
          f.id, 
          f.pageId, 
          f.type, 
          snippet(blocks_fts, 3, '<mark>', '</mark>', '...', 64) as snippet
        FROM blocks_fts f
        INNER JOIN blocks b ON f.id = b.id
        INNER JOIN pages p ON b.page_id = p.id
        WHERE blocks_fts MATCH ?
          AND b.deleted = 0
          AND p.deleted = 0
        ORDER BY rank
        LIMIT 50
        ''',
        variables: [Variable.withString(query)],
      ).get();

      final results = rows.map((row) {
        return SearchResult(
          blockId: row.read<String>('id'),
          pageId: row.read<String>('pageId'),
          blockType: row.read<String>('type'),
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
