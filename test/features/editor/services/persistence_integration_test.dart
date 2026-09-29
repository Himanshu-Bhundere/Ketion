import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/blocks/data/repositories/block_repository_impl.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/core/utils/logger.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ketion/features/editor/services/editor_persistence_coordinator.dart';
import 'package:ketion/features/editor/services/editor_persistence_gateway.dart';
import 'package:ketion/features/editor/services/editor_persistence_mutations.dart';

void main() {
  late AppDatabase database;
  late BlockRepositoryImpl repository;
  late EditorPersistenceCoordinator coordinator;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    final syncQueue = SyncQueueRepositoryImpl(database);
    repository = BlockRepositoryImpl(database, syncQueue, AppLogger());

    final gateway = RepositoryEditorPersistenceGateway(repository: repository);
    coordinator = EditorPersistenceCoordinator(gateway: gateway);

    // Setup page
    await database.into(database.pages).insert(
          PagesCompanion.insert(
            id: 'page1',
            title: const drift.Value('Test Page'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('EditorPersistenceCoordinator & Repository Integration', () {
    test('roundtrip: enqueue insert, wait, and read back from sqlite', () async {
      final insert = InsertBlockMutation(
        pageId: 'page1',
        blockId: 'block1',
        type: 'text',
        data: 'Hello',
        position: 1.0,
        expectedVersion: 1,
        createdAt: DateTime.now(),
      );

      final persisted = coordinator.enqueue(insert);
      expect(persisted, isTrue);

      await coordinator.flush();

      final blockResult = await repository.getBlock('block1');
      expect(blockResult.isSuccess, isTrue);
      
      final block = blockResult.valueOrNull!;
      expect(block.data, 'Hello');
      expect(block.version, 1);
    });

    test('rapid structural edits complete serially and coalesce where possible', () async {
      coordinator.enqueue(InsertBlockMutation(
        pageId: 'page1',
        blockId: 'block1',
        type: 'text',
        data: 'Init',
        position: 1.0,
        expectedVersion: 1,
        createdAt: DateTime.now(),
      ),);

      coordinator.enqueue(UpdateBlockMutation(
        pageId: 'page1',
        blockId: 'block1',
        data: 'Init A',
        type: 'text',
        position: 1.0,
        expectedVersion: 1,
        blockCreatedAt: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
      ),);
      
      coordinator.enqueue(UpdateBlockMutation(
        pageId: 'page1',
        blockId: 'block1',
        data: 'Init B',
        type: 'text',
        position: 1.0,
        expectedVersion: 2,
        blockCreatedAt: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
      ),);
      
      coordinator.enqueue(SplitBlockMutation(
        pageId: 'page1',
        originalBlockId: 'block1',
        originalData: 'Init ',
        expectedVersion: 2,
        originalBlockCreatedAt: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
        originalPosition: 1.0,
        newBlockId: 'block2',
        newData: 'B',
        newType: 'text',
        newPosition: 2.0,
      ),);

      await coordinator.flush();

      final block1 = (await repository.getBlock('block1')).valueOrNull!;
      final block2 = (await repository.getBlock('block2')).valueOrNull!;

      expect(block1.data, 'Init ');
      expect(block2.data, 'B');
      expect(block1.version, 3); // 1 create + 1 coalesced update + 1 split update
    });

    test('failure handles cleanly without breaking subsequent mutations', () async {
      // Intentionally insert a block that doesn't exist via Update
      final f1 = coordinator.enqueue(UpdateBlockMutation(
        pageId: 'page1',
        blockId: 'non_existent_block',
        data: 'Fail',
        type: 'text',
        position: 1.0,
        expectedVersion: 1,
        blockCreatedAt: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
      ),);

      expect(f1, isTrue);
      
      await coordinator.flush();
      
      expect(coordinator.hasFailedMutations, isTrue);

      // Now insert a real block
      final f2 = coordinator.enqueue(InsertBlockMutation(
        pageId: 'page1',
        blockId: 'block_new',
        type: 'text',
        data: 'Success',
        position: 1.0,
        expectedVersion: 1,
        createdAt: DateTime.now(),
      ),);

      expect(f2, isTrue);

      await coordinator.flush();

      final block = (await repository.getBlock('block_new')).valueOrNull;
      expect(block, isNotNull);
      expect(block!.data, 'Success');
    });
  });
}
