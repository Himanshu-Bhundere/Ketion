import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/pages/data/repositories/page_repository_impl.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as domain;
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/core/utils/logger.dart';

void main() {
  late AppDatabase database;
  late PageRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    final syncQueue = SyncQueueRepositoryImpl(database);
    repository = PageRepositoryImpl(database, syncQueue, AppLogger());
  });

  tearDown(() async {
    await database.close();
  });

  group('PageRepositoryImpl - Atomicity & Sync Queue', () {
    test('createPage creates page, initial block and sync_queue entries atomically', () async {
      final newPage = domain.Page(
        id: 'page1',
        title: 'Test Page',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createPage(newPage);

      // Verify Page exists and version is 1
      final pageInDb = await (database.select(database.pages)
            ..where((t) => t.id.equals('page1')))
          .getSingle();
      expect(pageInDb.title, 'Test Page');
      expect(pageInDb.version, 1);

      // Verify Initial Block exists
      final blocksInDb = await (database.select(database.blocks)
            ..where((t) => t.pageId.equals('page1')))
          .get();
      expect(blocksInDb.length, 1);
      final initialBlock = blocksInDb.first;
      expect(initialBlock.type, 'text');
      expect(initialBlock.version, 1);

      // Verify sync_queue entries exist
      final queueItems = await database.select(database.syncQueue).get();
      // Should have 2 entries: 1 for page create, 1 for block create
      expect(queueItems.length, 2);
      
      final pageQueueItem = queueItems.firstWhere((item) => item.entityTable == 'pages');
      expect(pageQueueItem.entityId, 'page1');
      expect(pageQueueItem.operation, 'create');
      expect(pageQueueItem.status, 'pending');

      final blockQueueItem = queueItems.firstWhere((item) => item.entityTable == 'blocks');
      expect(blockQueueItem.entityId, initialBlock.id);
      expect(blockQueueItem.operation, 'create');
      expect(blockQueueItem.status, 'pending');
    });

    test('updatePage bumps version and creates sync_queue entry', () async {
      final page = domain.Page(
        id: 'page1',
        title: 'Test Page',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createPage(page);

      final updatedPage = page.copyWith(title: 'Updated Page');
      await repository.updatePage(updatedPage);

      final pageInDb = await (database.select(database.pages)
            ..where((t) => t.id.equals('page1')))
          .getSingle();
      expect(pageInDb.title, 'Updated Page');
      expect(pageInDb.version, 2);

      final queueItems = await (database.select(database.syncQueue)
            ..where((t) => t.entityId.equals('page1')))
          .get();
      
      // Coalesced into a single 'create' due to sync queue coalescing logic
      expect(queueItems.length, 1);
      expect(queueItems.first.operation, 'create');
      
      // Check payload contains updated title
      final payload = jsonDecode(queueItems.first.payload!) as Map<String, dynamic>;
      expect(payload['title'], 'Updated Page');
      expect(payload['version'], 2);
    });
  });
}
