import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/blocks/data/repositories/block_repository_impl.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart' as domain;
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/features/editor/domain/models/drop_intent.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase database;
  late BlockRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    final syncQueue = SyncQueueRepositoryImpl(database);
    repository = BlockRepositoryImpl(database, syncQueue, AppLogger());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> createPage(String id) async {
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: id,
            title: const drift.Value('Test Page'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> createBlock(String id, String pageId, String? parentBlockId, double position) async {
    final block = domain.Block(
      id: id,
      pageId: pageId,
      parentBlockId: parentBlockId,
      type: 'text',
      data: 'Block $id',
      position: position,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
    );
    await repository.createBlock(block);
  }

  group('BlockRepositoryImpl - Move Tree Tests', () {
    test('Subtree preservation: Move a parent block preserves descendants', () async {
      await createPage('page1');
      
      // Structure:
      // A (pos 1)
      //   B (pos 1)
      //     C (pos 1)
      // D (pos 2)
      
      await createBlock('A', 'page1', null, 1.0);
      await createBlock('B', 'page1', 'A', 1.0);
      await createBlock('C', 'page1', 'B', 1.0);
      await createBlock('D', 'page1', null, 2.0);

      // Move A as child of D
      final result = await repository.moveBlock('A', const DropIntent.child('D'));
      expect(result.isSuccess, isTrue);

      // Verify A's new parent and position
      final blockA = (await repository.getBlock('A')).valueOrNull!;
      expect(blockA.parentBlockId, 'D');

      // Verify B and C's parent and position remain untouched
      final blockB = (await repository.getBlock('B')).valueOrNull!;
      expect(blockB.parentBlockId, 'A');
      expect(blockB.version, 1); // version unchanged because we only update the moved block + siblings

      final blockC = (await repository.getBlock('C')).valueOrNull!;
      expect(blockC.parentBlockId, 'B');
      expect(blockC.version, 1);
    });

    test('Cross-page rejection: Rejects moving to a block on a different page', () async {
      await createPage('page1');
      await createPage('page2');
      
      await createBlock('A', 'page1', null, 1.0);
      await createBlock('B', 'page2', null, 1.0);

      final result = await repository.moveBlock('A', const DropIntent.after('B'));
      
      expect(result.isError, isTrue);
      
      // Verify no DB mutation for block A
      final blockA = (await repository.getBlock('A')).valueOrNull!;
      expect(blockA.pageId, 'page1');
      expect(blockA.position, 1.0);
      expect(blockA.version, 1);

      // Verify no queue entries created for move
      final queueItems = await database.select(database.syncQueue).get();
      // Should only be 2 queue items for the 2 createBlock operations
      expect(queueItems.length, 2);
    });

    test('Move under external mutation: Re-reads authoritative DB state at execution time', () async {
      await createPage('page1');
      
      await createBlock('A', 'page1', null, 1.0);
      await createBlock('B', 'page1', null, 2.0);

      // Simulate external mutation before drop: block B is deleted
      await repository.deleteBlock('B');

      // Try to drop A after B
      final result = await repository.moveBlock('A', const DropIntent.after('B'));
      
      // Target block is deleted, should reject
      expect(result.isError, isTrue);

      final blockA = (await repository.getBlock('A')).valueOrNull!;
      expect(blockA.position, 1.0);
    });
  });
}
