import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/search/data/repositories/search_repository_impl.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/search/domain/models/search_result.dart';
import 'package:ketion/core/utils/logger.dart';

void main() {
  late AppDatabase database;
  late SearchRepositoryImpl searchRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    searchRepository = SearchRepositoryImpl(database, appLogger);
  });

  tearDown(() async {
    await database.close();
  });

  test('searchNotes sanitizes input and finds matching pages', () async {
    // Insert a page
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page1',
            title: const drift.Value('Hello "World" *test*'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    // Rebuild index just in case the trigger didn't fire due to testing setup
    // But triggers should fire since it's a real DB.

    // Search with special characters
    final result = await searchRepository.searchNotes('World" *test');

    expect(result, isA<Success<List<SearchResult>>>());
    final searchResults = (result as Success<List<SearchResult>>).value;
    expect(searchResults.length, 1);
    expect(searchResults.first.entityId, 'page1');
    expect(searchResults.first.entityType, 'page');
  });

  test('soft deleted records do not appear in search results', () async {
    // Insert a page
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page2',
            title: const drift.Value('Secret Document'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    // Verify it exists in search
    var result = await searchRepository.searchNotes('Secret');
    expect((result as Success<List<SearchResult>>).value.length, 1);

    // Soft delete it
    await (database.update(database.pages)
          ..where((tbl) => tbl.id.equals('page2')))
        .write(const PagesCompanion(deleted: drift.Value(true)));

    // Verify it no longer exists in search
    result = await searchRepository.searchNotes('Secret');
    expect((result as Success<List<SearchResult>>).value.length, 0);
  });

  test('searchNotes returns a body match with the page title and snippet',
      () async {
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page3',
            title: const drift.Value('Travel'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await database.into(database.blocks).insert(
          BlocksCompanion.insert(
            id: 'block3',
            pageId: 'page3',
            type: 'text',
            data: '{}',
            searchableText: const drift.Value('Book hotel in Mumbai'),
            position: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final result = await searchRepository.searchNotes('Mumbai');
    final matches = (result as Success<List<SearchResult>>).value;

    expect(matches, hasLength(1));
    expect(matches.single.entityType, 'block');
    expect(matches.single.pageTitle, 'Travel');
    expect(matches.single.snippet, contains('Mumbai'));

    final pageOnly = await searchRepository.searchNotes(
      'Mumbai',
      typeFilter: 'page',
    );
    expect((pageOnly as Success<List<SearchResult>>).value, isEmpty);
  });

  test(
      'searchNotes supports tag and collection filters, including metadata-only',
      () async {
    // Insert pages
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page_vacation',
            title: const drift.Value('Vacation Plans'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page_work',
            title: const drift.Value('Sprint Retrospective'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    // Insert tag & collection
    await database.into(database.tags).insert(
          TagsCompanion.insert(
            id: 'tag_travel',
            name: 'travel',
            color: const drift.Value('#FF0000'),
            createdAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
    await database.into(database.collections).insert(
          CollectionsCompanion.insert(
            id: 'coll_personal',
            name: 'Personal Life',
            createdAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );

    // Associate tag and collection with page_vacation
    await database.into(database.pageTags).insert(
          PageTagsCompanion.insert(
            pageId: 'page_vacation',
            tagId: 'tag_travel',
          ),
        );
    await database.into(database.pageCollections).insert(
          PageCollectionsCompanion.insert(
            pageId: 'page_vacation',
            collectionId: 'coll_personal',
          ),
        );

    // 1. Search with tag filter
    final tagFiltered = await searchRepository.searchNotes(
      'Vacation',
      tagFilter: 'tag_travel',
    );
    expect(tagFiltered, isA<Success<List<SearchResult>>>());
    final tagMatches = (tagFiltered as Success<List<SearchResult>>).value;
    expect(tagMatches.any((m) => m.pageId == 'page_vacation'), isTrue);

    // 2. Metadata-only search (empty query with tag filter)
    final metaTagSearch = await searchRepository.searchNotes(
      '',
      tagFilter: 'tag_travel',
    );
    expect(metaTagSearch, isA<Success<List<SearchResult>>>());
    final metaTagMatches = (metaTagSearch as Success<List<SearchResult>>).value;
    expect(metaTagMatches.any((m) => m.pageId == 'page_vacation'), isTrue);
    expect(metaTagMatches.any((m) => m.pageId == 'page_work'), isFalse);

    // 3. Metadata-only search with collection filter
    final metaCollSearch = await searchRepository.searchNotes(
      '',
      collectionFilter: 'coll_personal',
    );
    expect(metaCollSearch, isA<Success<List<SearchResult>>>());
    final metaCollMatches =
        (metaCollSearch as Success<List<SearchResult>>).value;
    expect(metaCollMatches.any((m) => m.pageId == 'page_vacation'), isTrue);
    expect(metaCollMatches.any((m) => m.pageId == 'page_work'), isFalse);
  });
}
