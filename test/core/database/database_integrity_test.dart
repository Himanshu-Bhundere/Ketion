import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('Cascade Deletes: Verify deleting a Page deletes all Blocks', () async {
    // 1. Insert a page
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page1',
            title: const drift.Value('Test Page FTS'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    // 2. Insert blocks
    await database.into(database.blocks).insert(
          BlocksCompanion.insert(
            id: 'block1',
            pageId: 'page1',
            type: 'text',
            position: 1.0,
            data: 'Content',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await database.into(database.blocks).insert(
          BlocksCompanion.insert(
            id: 'block2',
            pageId: 'page1',
            parentBlockId: const drift.Value('block1'),
            type: 'text',
            position: 2.0,
            data: 'Child Content',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    // Verify blocks exist
    var blocks = await database.select(database.blocks).get();
    expect(blocks.length, 2);

    // 3. Delete page
    await (database.delete(database.pages)
          ..where((tbl) => tbl.id.equals('page1')))
        .go();

    // Verify blocks deleted via CASCADE
    blocks = await database.select(database.blocks).get();
    expect(blocks.length, 0);
  });

  test(
      'Hierarchical Block Integrity: Verify deleting a parent Block cascades to child Blocks',
      () async {
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page1',
            title: const drift.Value('Test Page FTS'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await database.into(database.blocks).insert(
          BlocksCompanion.insert(
            id: 'block1',
            pageId: 'page1',
            type: 'text',
            position: 1.0,
            data: 'Content',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await database.into(database.blocks).insert(
          BlocksCompanion.insert(
            id: 'block2',
            pageId: 'page1',
            parentBlockId: const drift.Value('block1'),
            type: 'text',
            position: 2.0,
            data: 'Child Content',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    // 3. Delete parent block
    await (database.delete(database.blocks)
          ..where((tbl) => tbl.id.equals('block1')))
        .go();

    // Verify child block deleted via CASCADE
    var blocks = await database.select(database.blocks).get();
    expect(blocks.length, 0);
  });
}
