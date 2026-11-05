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
    String? tagFilter,
    String? collectionFilter,
  }) async {
    try {
      final trimmedQuery = query.trim();

      // Case 1: Metadata-only search (query is empty)
      if (trimmedQuery.isEmpty) {
        return await _searchMetadataOnly(
          typeFilter: typeFilter,
          tagFilter: tagFilter,
          collectionFilter: collectionFilter,
        );
      }

      // Case 2: Full-text search with optional filters
      final sanitizedQuery = '"${trimmedQuery.replaceAll('"', '""')}"*';

      final List<Variable> variables = [
        Variable.withString(sanitizedQuery),
      ];

      final List<String> conditions = [
        's.search_fts MATCH ?',
      ];

      if (typeFilter != null && typeFilter.isNotEmpty) {
        conditions.add('s.entityType = ?');
        variables.add(Variable.withString(typeFilter));
      }

      if (tagFilter != null && tagFilter.isNotEmpty) {
        conditions.add('''
          (
            (s.entityType = 'tag' AND (s.entityId = ? OR s.content = ?))
            OR
            (s.pageId IS NOT NULL AND EXISTS (
              SELECT 1 FROM page_tags pt
              JOIN tags t ON t.id = pt.tag_id
              WHERE pt.page_id = s.pageId AND (pt.tag_id = ? OR t.name = ?)
            ))
          )
        ''');
        variables.add(Variable.withString(tagFilter));
        variables.add(Variable.withString(tagFilter));
        variables.add(Variable.withString(tagFilter));
        variables.add(Variable.withString(tagFilter));
      }

      if (collectionFilter != null && collectionFilter.isNotEmpty) {
        conditions.add('''
          (
            (s.entityType = 'collection' AND (s.entityId = ? OR s.content = ?))
            OR
            (s.pageId IS NOT NULL AND EXISTS (
              SELECT 1 FROM page_collections pc
              JOIN collections c ON c.id = pc.collection_id
              WHERE pc.page_id = s.pageId AND (pc.collection_id = ? OR c.name = ?)
            ))
          )
        ''');
        variables.add(Variable.withString(collectionFilter));
        variables.add(Variable.withString(collectionFilter));
        variables.add(Variable.withString(collectionFilter));
        variables.add(Variable.withString(collectionFilter));
      }

      final whereClause = conditions.join(' AND ');

      final sql = '''
        SELECT 
          s.entityId, 
          s.pageId, 
          s.entityType, 
          COALESCE(snippet(search_fts, 3, '<mark>', '</mark>', '...', 64), p.title, s.content, '') as snippet,
          p.title as pageTitle,
          b.type as blockType,
          COALESCE(b.updated_at, p.updated_at, c.updated_at) as modifiedAt,
          COALESCE(c.name, (SELECT name FROM collections WHERE id = (SELECT collection_id FROM page_collections WHERE page_id = s.pageId LIMIT 1))) as breadcrumb,
          CASE 
             WHEN s.entityType = 'page' THEN 100
             WHEN s.entityType = 'collection' THEN 90
             WHEN s.entityType = 'block' AND b.type LIKE 'header%' THEN 80
             WHEN s.entityType = 'block' THEN 50
             WHEN s.entityType = 'tag' THEN 30
             ELSE 10
          END as custom_rank,
          bm25(search_fts) as fts_rank
        FROM search_fts s
        LEFT JOIN pages p ON p.id = s.pageId
        LEFT JOIN blocks b ON b.id = s.entityId AND s.entityType = 'block'
        LEFT JOIN collections c ON c.id = s.entityId AND s.entityType = 'collection'
        WHERE $whereClause
          AND (
            (s.entityType = 'page' AND p.deleted = 0 AND p.is_archived = 0) OR
            (s.entityType = 'block' AND p.deleted = 0 AND p.is_archived = 0 AND b.deleted = 0) OR
            (s.entityType = 'tag') OR
            (s.entityType = 'collection' AND c.deleted = 0)
          )
        ORDER BY custom_rank DESC, fts_rank ASC
        LIMIT 100
      ''';

      final rows = await _database
          .customSelect(
            sql,
            variables: variables,
          )
          .get();

      final results = _mapRowsToResults(rows);
      return Success(results);
    } catch (e, stackTrace) {
      _logger.e('Failed to search notes: $e', e, stackTrace);
      return Error(StorageFailure('Failed to search notes: $e'));
    }
  }

  Future<Result<List<SearchResult>>> _searchMetadataOnly({
    String? typeFilter,
    String? tagFilter,
    String? collectionFilter,
  }) async {
    try {
      final List<Variable> variables = [];
      final List<String> conditions = [
        'p.deleted = 0',
        'p.is_archived = 0',
      ];

      if (tagFilter != null && tagFilter.isNotEmpty) {
        conditions.add('''
          EXISTS (
            SELECT 1 FROM page_tags pt
            JOIN tags t ON t.id = pt.tag_id
            WHERE pt.page_id = p.id AND (pt.tag_id = ? OR t.name = ?)
          )
        ''');
        variables.add(Variable.withString(tagFilter));
        variables.add(Variable.withString(tagFilter));
      }

      if (collectionFilter != null && collectionFilter.isNotEmpty) {
        conditions.add('''
          EXISTS (
            SELECT 1 FROM page_collections pc
            JOIN collections c ON c.id = pc.collection_id
            WHERE pc.page_id = p.id AND (pc.collection_id = ? OR c.name = ?)
          )
        ''');
        variables.add(Variable.withString(collectionFilter));
        variables.add(Variable.withString(collectionFilter));
      }

      final whereClause = conditions.join(' AND ');

      final rows = await _database.customSelect(
        '''
        SELECT 
          p.id as entityId, 
          p.id as pageId, 
          'page' as entityType, 
          p.title as snippet,
          p.title as pageTitle,
          NULL as blockType,
          p.updated_at as modifiedAt,
          (SELECT name FROM collections WHERE id = (SELECT collection_id FROM page_collections WHERE page_id = p.id LIMIT 1)) as breadcrumb,
          100 as custom_rank,
          0.0 as fts_rank
        FROM pages p
        WHERE $whereClause
        ORDER BY p.updated_at DESC
        LIMIT 100
        ''',
        variables: variables,
      ).get();

      final results = _mapRowsToResults(rows);
      return Success(results);
    } catch (e, stackTrace) {
      _logger.e('Failed to search notes by metadata: $e', e, stackTrace);
      return Error(StorageFailure('Failed to search notes by metadata: $e'));
    }
  }

  List<SearchResult> _mapRowsToResults(List<QueryRow> rows) {
    return rows.map((row) {
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
      } else if (entityType == 'collection') {
        matchType = MatchType.collection;
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
