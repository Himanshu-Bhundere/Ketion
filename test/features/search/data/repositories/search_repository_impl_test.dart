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
}
