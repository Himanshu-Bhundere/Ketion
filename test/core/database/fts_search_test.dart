import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ketion/features/blocks/data/models/block_mapper.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart' as domain;

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('Pages and Blocks triggers work with soft deletion', () async {
    // 1. Insert a page
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page1',
            title: const drift.Value('Test Page FTS'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    // 2. Insert a block for the page
    await database.into(database.blocks).insert(
          BlocksCompanion.insert(
            id: 'block1',
            pageId: 'page1',
            type: 'text',
            data: 'This is some important content',
            searchableText: const drift.Value('This is some important content'),
            position: 1.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            deleted: const drift.Value(false),
          ),
        );

    // 3. Verify they are in FTS
    var results = await database.customSelect(
      'SELECT * FROM search_fts WHERE content MATCH ?',
      variables: [drift.Variable.withString('important')],
    ).get();
    expect(results.length, 1);

    // 4. Soft delete the block
    await (database.update(database.blocks)
          ..where((tbl) => tbl.id.equals('block1')))
        .write(const BlocksCompanion(deleted: drift.Value(true)));

    // 5. Verify it is removed from FTS
    results = await database.customSelect(
      'SELECT * FROM search_fts WHERE content MATCH ?',
      variables: [drift.Variable.withString('important')],
    ).get();
    expect(results.length, 0);

    // 6. Restore the block
    await (database.update(database.blocks)
          ..where((tbl) => tbl.id.equals('block1')))
        .write(const BlocksCompanion(deleted: drift.Value(false)));

    // 7. Verify it is back in FTS
    results = await database.customSelect(
      'SELECT * FROM search_fts WHERE content MATCH ?',
      variables: [drift.Variable.withString('important')],
    ).get();
    expect(results.length, 1);

    // 8. Test physical deletion
    await (database.delete(database.blocks)
          ..where((tbl) => tbl.id.equals('block1')))
        .go();
    results = await database.customSelect(
      'SELECT * FROM search_fts WHERE content MATCH ?',
      variables: [drift.Variable.withString('important')],
    ).get();
    expect(results.length, 0);
  });

  test('canonical block serialization reaches FTS through the block mapper',
      () async {
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page2',
            title: const drift.Value('Travel'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    final block = domain.Block(
      id: 'block2',
      pageId: 'page2',
      type: 'text',
      position: 0,
      data:
          '{"spans":[{"text":"Book hotel in Mumbai"}],"headingLevel":0,"runtimeType":"text"}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await database.into(database.blocks).insert(block.toCompanion());
    final rows = await database.customSelect(
      'SELECT * FROM search_fts WHERE content MATCH ?',
      variables: [drift.Variable.withString('Mumbai')],
    ).get();

    expect(rows.map((row) => row.read<String>('entityId')), contains('block2'));
  });
}
