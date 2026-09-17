import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/blocks/data/repositories/block_repository_impl.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart' as domain;
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/core/utils/logger.dart';
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

  group('BlockRepositoryImpl - Atomicity & Sync Queue', () {
    test('createBlock creates block and sync_queue entry atomically', () async {
      // Setup foreign key constraint requirements
      await database.into(database.pages).insert(
        PagesCompanion.insert(
          id: 'page1',
          title: const drift.Value('Test Page'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final newBlock = domain.Block(
        id: 'block1',
        pageId: 'page1',
        type: 'text',
        data: 'Hello',
        position: 1.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createBlock(newBlock);

      // Verify Block exists and version is 1
      final blockInDb = await (database.select(database.blocks)..where((t) => t.id.equals('block1'))).getSingle();
      expect(blockInDb.data, 'Hello');
      expect(blockInDb.version, 1);

      // Verify sync_queue entry exists
      final queueItems = await database.select(database.syncQueue).get();
      expect(queueItems.length, 1);
      expect(queueItems.first.entityId, 'block1');
      expect(queueItems.first.entityTable, 'blocks');
      expect(queueItems.first.operation, 'create');
      expect(queueItems.first.status, 'pending');
    });

    test('updateBlock bumps version and creates sync_queue entry', () async {
      await database.into(database.pages).insert(
        PagesCompanion.insert(
          id: 'page1',
          title: const drift.Value('Test Page'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final block = domain.Block(
        id: 'block1',
        pageId: 'page1',
        type: 'text',
        data: 'Hello',
        position: 1.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createBlock(block);

      final updatedBlock = block.copyWith(data: 'Hello Updated');
      await repository.updateBlock(updatedBlock);

      final blockInDb = await (database.select(database.blocks)..where((t) => t.id.equals('block1'))).getSingle();
      expect(blockInDb.data, 'Hello Updated');
      expect(blockInDb.version, 2);

      final queueItems = await (database.select(database.syncQueue)..where((t) => t.entityId.equals('block1'))).get();
      expect(queueItems.length, 1); // coalesced update into create
      expect(queueItems.last.operation, 'create');
    });

    test('deleteBlock creates sync_queue entry', () async {
      await database.into(database.pages).insert(
        PagesCompanion.insert(
          id: 'page1',
          title: const drift.Value('Test Page'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final block = domain.Block(
        id: 'block1',
        pageId: 'page1',
        type: 'text',
        data: 'Hello',
        position: 1.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createBlock(block);
      await repository.deleteBlock('block1');

      final blocksInDb = await database.select(database.blocks).get();
      expect(blocksInDb.length, 1);
      expect(blocksInDb.single.deleted, true);

      final queueItems = await (database.select(database.syncQueue)..where((t) => t.entityId.equals('block1'))).get();
      expect(queueItems.length, 1); // 1 create + 1 delete = coalesced to 1 delete
      expect(queueItems.last.operation, 'delete');
    });
  });
}
