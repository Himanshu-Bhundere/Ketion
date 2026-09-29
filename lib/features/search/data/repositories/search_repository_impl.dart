import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../../../../core/utils/logger.dart';


class SearchRepositoryImpl implements SearchRepository {
  final AppDatabase _database;
  final AppLogger _logger;

  SearchRepositoryImpl(this._database, this._logger);

  @override
  Future<Result<List<SearchResult>>> searchNotes(
    String query, {
    String? typeFilter,
  }) async {
    try {
      // Sanitize the query to treat it as pure text, not FTS syntax.
      // Escape double quotes and wrap in quotes for a phrase match.
      // We append a * for prefix matching.
      final sanitizedQuery = '"${query.replaceAll('"', '""')}"*';

      final String whereClause = typeFilter != null
          ? 's.search_fts MATCH ? AND s.entityType = ?'
          : 's.search_fts MATCH ?';

      final variables = typeFilter != null
          ? [
              Variable.withString(sanitizedQuery),
              Variable.withString(typeFilter),
            ]
          : [Variable.withString(sanitizedQuery)];

      final rows = await _database.customSelect(
        '''
        SELECT 
          s.entityId, 
          s.pageId, 
          s.entityType, 
          snippet(search_fts, 3, '<mark>', '</mark>', '...', 64) as snippet,
          p.title as pageTitle,
          b.type as blockType,
          COALESCE(b.updated_at, p.updated_at) as modifiedAt,
          (SELECT name FROM collections WHERE id = (SELECT collection_id FROM page_collections WHERE page_id = s.pageId LIMIT 1)) as breadcrumb,
          CASE 
             WHEN s.entityType = 'page' THEN 100
             WHEN s.entityType = 'block' AND b.type LIKE 'header%' THEN 80
             WHEN s.entityType = 'block' THEN 50
             WHEN s.entityType = 'tag' THEN 30
             ELSE 10
          END as custom_rank,
          bm25(search_fts) as fts_rank
        FROM search_fts s
        LEFT JOIN pages p ON p.id = s.pageId
        LEFT JOIN blocks b ON b.id = s.entityId AND s.entityType = 'block'
        WHERE $whereClause
          AND (
            (s.entityType = 'page' AND p.deleted = 0 AND p.is_archived = 0) OR
            (s.entityType = 'block' AND p.deleted = 0 AND p.is_archived = 0 AND b.deleted = 0) OR
            (s.entityType = 'tag')
          )
        ORDER BY custom_rank DESC, fts_rank ASC
        LIMIT 100
        ''',
        variables: variables,
      ).get();

      final results = rows.map((row) {
        final parsedModifiedAt = row.readNullable<DateTime>('modifiedAt');
        final entityType = row.read<String>('entityType');
        final blockType = row.readNullable<String>('blockType');

        MatchType matchType = MatchType.unknown;
        if (entityType == 'page') {
          matchType = MatchType.pageTitle;
        } else if (entityType == 'block') {
          matchType = MatchType.blockContent;
        } else if (entityType == 'tag') {
          matchType = MatchType.tag;
        }

        return SearchResult(
          entityId: row.read<String>('entityId'),
          pageId: row.read<String?>('pageId'),
          entityType: entityType,
          snippet: row.read<String>('snippet'),
          matchType: matchType,
          pageTitle: row.readNullable<String>('pageTitle'),
          blockType: blockType,
          modifiedAt: parsedModifiedAt,
          breadcrumb: row.readNullable<String>('breadcrumb'),
        );
      }).toList();

      return Success(results);
    } catch (e, stackTrace) {
      _logger.e('Failed to search notes: $e', e, stackTrace);
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
