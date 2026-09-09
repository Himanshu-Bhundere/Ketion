import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/search/data/repositories/search_repository_impl.dart';
import 'package:ketion/core/utils/result.dart';

void main() {
  late AppDatabase database;
  late SearchRepositoryImpl searchRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    searchRepository = SearchRepositoryImpl(database);
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
    
    expect(result, isA<Success>());
    final searchResults = (result as Success).value;
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
    expect((result as Success).value.length, 1);
    
    // Soft delete it
    await (database.update(database.pages)..where((tbl) => tbl.id.equals('page2')))
        .write(const PagesCompanion(deleted: drift.Value(true)));
        
    // Verify it no longer exists in search
    result = await searchRepository.searchNotes('Secret');
    expect((result as Success).value.length, 0);
  });
}
