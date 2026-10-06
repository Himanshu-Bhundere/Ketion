import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ketion/core/database/app_database.dart' hide Block;
import 'package:ketion/features/search/data/repositories/search_repository_impl.dart';
import 'package:ketion/features/blocks/data/repositories/block_repository_impl.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/search/domain/models/search_result.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'dart:convert';

void main() {
  late AppDatabase database;
  late SearchRepositoryImpl searchRepository;
  late SyncQueueRepositoryImpl syncQueueRepository;
  late BlockRepositoryImpl blockRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    searchRepository = SearchRepositoryImpl(database, appLogger);
    syncQueueRepository = SyncQueueRepositoryImpl(database);
    blockRepository =
        BlockRepositoryImpl(database, syncQueueRepository, appLogger);
  });

  tearDown(() async {
    await database.close();
  });

  test('FTS Lifecycle Test: Block update triggers search index', () async {
    // 1. Create a page
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page1',
            title: const drift.Value('Initial Page'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    // 2. Create a block
    final block = Block(
      id: 'block1',
      pageId: 'page1',
      type: 'paragraph',
      position: 0.0,
      data: jsonEncode({
        'spans': [
          {'text': 'Initial body content for testing search lifecycle'},
        ],
      }),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
    );
    await blockRepository.createBlock(block);

    // 3. Search for initial text
    final result1 = await searchRepository.searchNotes('lifecycle');
    expect(result1, isA<Success<List<SearchResult>>>());
    var searchResults = (result1 as Success<List<SearchResult>>).value;
    expect(searchResults.length, 1);
    expect(searchResults.first.snippet, contains('lifecycle'));

    // 4. Update the block
    final updatedBlock = block.copyWith(
      data: jsonEncode({
        'spans': [
          {'text': 'Updated body content with something entirely new'},
        ],
      }),
      version: 2,
    );
    await blockRepository.updateBlock(
      updatedBlock,
      expectedVersion: updatedBlock.version - 1,
    );

    // 5. Search for old text (should be gone)
    final result2 = await searchRepository.searchNotes('lifecycle');
    expect(result2, isA<Success<List<SearchResult>>>());
    searchResults = (result2 as Success<List<SearchResult>>).value;
    expect(searchResults.length, 0);

    // 6. Search for new text (should be found)
    final result3 = await searchRepository.searchNotes('entirely new');
    expect(result3, isA<Success<List<SearchResult>>>());
    searchResults = (result3 as Success<List<SearchResult>>).value;
    expect(searchResults.length, 1);
    expect(searchResults.first.snippet, contains('entirely'));
    expect(searchResults.first.snippet, contains('new'));
  });

  test('Ranking Tests: Title > Heading > Body > Tag weighting', () async {
    // We will create multiple matches for the same keyword 'ranktest'
    // in different elements and see their order.

    // Page 1: Tag match
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page_tag',
            title: const drift.Value('Some page without keyword'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await database.into(database.tags).insert(
          TagsCompanion.insert(
            id: 'tag1',
            name: 'ranktest',
          ),
        );
    await database.into(database.pageTags).insert(
          PageTagsCompanion.insert(
            pageId: 'page_tag',
            tagId: 'tag1',
          ),
        );

    // Page 2: Body match
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page_body',
            title: const drift.Value('Another page without keyword'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await blockRepository.createBlock(
      Block(
        id: 'block_body',
        pageId: 'page_body',
        type: 'paragraph',
        position: 0.0,
        data: jsonEncode({
          'spans': [
            {'text': 'This is a ranktest body'},
          ],
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      ),
    );

    // Page 3: Heading match
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page_heading',
            title: const drift.Value('Yet another page'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await blockRepository.createBlock(
      Block(
        id: 'block_heading',
        pageId: 'page_heading',
        type: 'header',
        position: 0.0,
        data: jsonEncode({
          'spans': [
            {'text': 'This is a ranktest header'},
          ],
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      ),
    );

    // Page 4: Title match
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page_title',
            title: const drift.Value('This ranktest is in title'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    // Wait a tiny bit just in case timestamps are identical and it orders by date
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final result = await searchRepository.searchNotes('ranktest');
    expect(result, isA<Success<List<SearchResult>>>());
    final searchResults = (result as Success<List<SearchResult>>).value;

    // We expect 4 results. The order should be: Title, Heading, Body, Tag.
    expect(searchResults.length, 4);

    expect(
      searchResults[0].entityId,
      'page_title',
      reason: 'Title should rank first',
    );
    expect(
      searchResults[1].entityId,
      'block_heading',
      reason: 'Heading should rank second',
    );
    expect(
      searchResults[2].entityId,
      'block_body',
      reason: 'Body should rank third',
    );
    expect(searchResults[3].entityId, 'tag1', reason: 'Tag should rank fourth');
  });

  test('Collection Search Lifecycle: Insert, search, rename, delete', () async {
    // 1. Insert collection
    await database.into(database.collections).insert(
          CollectionsCompanion.insert(
            id: 'col1',
            name: 'Project Roadmap',
            createdAt: const drift.Value.absent(),
            updatedAt: const drift.Value.absent(),
            deleted: const drift.Value(false),
          ),
        );

    // 2. Search exact and prefix match
    final resExact = await searchRepository.searchNotes('Roadmap');
    expect(resExact, isA<Success<List<SearchResult>>>());
    final exactMatches = (resExact as Success<List<SearchResult>>).value;
    expect(exactMatches.length, 1);
    expect(exactMatches.first.entityId, 'col1');
    expect(exactMatches.first.matchType, MatchType.collection);
    expect(exactMatches.first.breadcrumb, 'Project Roadmap');

    final resPrefix = await searchRepository.searchNotes('Road');
    expect(resPrefix, isA<Success<List<SearchResult>>>());
    final prefixMatches = (resPrefix as Success<List<SearchResult>>).value;
    expect(prefixMatches.length, 1);
    expect(prefixMatches.first.entityId, 'col1');

    // 3. Search with typeFilter
    final resFilter = await searchRepository.searchNotes('Roadmap', typeFilter: 'collection');
    expect(resFilter, isA<Success<List<SearchResult>>>());
    expect((resFilter as Success<List<SearchResult>>).value.length, 1);

    final resFilterMismatch = await searchRepository.searchNotes('Roadmap', typeFilter: 'page');
    expect(resFilterMismatch, isA<Success<List<SearchResult>>>());
    expect((resFilterMismatch as Success<List<SearchResult>>).value.length, 0);

    // 4. Update collection name
    await (database.update(database.collections)
          ..where((tbl) => tbl.id.equals('col1')))
        .write(const CollectionsCompanion(name: drift.Value('Product Backlog')));

    final resOld = await searchRepository.searchNotes('Roadmap');
    expect((resOld as Success<List<SearchResult>>).value.length, 0);

    final resNew = await searchRepository.searchNotes('Backlog') as Success<List<SearchResult>>;
    expect(resNew.value.length, 1);
    expect(resNew.value.first.breadcrumb, 'Product Backlog');

    // 5. Soft-delete collection
    await (database.update(database.collections)
          ..where((tbl) => tbl.id.equals('col1')))
        .write(const CollectionsCompanion(deleted: drift.Value(true)));

    final resDeleted = await searchRepository.searchNotes('Backlog');
    expect((resDeleted as Success<List<SearchResult>>).value.length, 0);
  });
}
