import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/blocks/data/repositories/block_repository_impl.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart' as domain;
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:ketion/features/sync/domain/entities/sync_queue_item.dart';
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/features/editor/domain/models/drop_intent.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ketion/features/blocks/data/models/block_mapper.dart';
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/core/utils/result.dart';

// Wrapper to simulate failures during sync queue enqueue
class FaultySyncQueueRepository implements SyncQueueRepository {
  final SyncQueueRepository _inner;
  bool shouldFail = false;

  FaultySyncQueueRepository(this._inner);

  @override
  Future<Result<void>> enqueue(SyncQueueItem item) async {
    if (shouldFail) return const Error(StorageFailure('Simulated failure'));
    return _inner.enqueue(item);
  }

  @override
  Future<Result<void>> enqueueOrCoalesce(SyncQueueItem item) async {
    if (shouldFail) return const Error(StorageFailure('Simulated coalescing failure'));
    return _inner.enqueueOrCoalesce(item);
  }

  @override
  Future<Result<List<SyncQueueItem>>> claimNextBatch({
    int limit = 50,
    required Duration leaseDuration,
  }) => _inner.claimNextBatch(limit: limit, leaseDuration: leaseDuration);

  @override
  Future<Result<SyncQueueItem?>> findPendingItem(String table, String entityId) => _inner.findPendingItem(table, entityId);

  @override
  Future<Result<void>> updateStatus(
    String id,
    SyncQueueItemStatus status, {
    int? attemptCount,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    DateTime? leaseUntil,
    String? lastError,
  }) => _inner.updateStatus(id, status, attemptCount: attemptCount, lastAttemptAt: lastAttemptAt, nextRetryAt: nextRetryAt, leaseUntil: leaseUntil, lastError: lastError);

  @override
  Future<Result<void>> clearCompleted() => _inner.clearCompleted();
}

void main() {
  late AppDatabase database;
  late BlockRepositoryImpl repository;
  late FaultySyncQueueRepository syncQueue;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    syncQueue = FaultySyncQueueRepository(SyncQueueRepositoryImpl(database));
    repository = BlockRepositoryImpl(database, syncQueue, AppLogger());

    // Setup foreign key constraint requirements
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

  domain.Block createTestBlock(String id, double position, {String? parentId}) {
    return domain.Block(
      id: id,
      pageId: 'page1',
      type: 'text',
      data: 'Block $id',
      position: position,
      parentBlockId: parentId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('2.9.4 Queue Coalescing and Atomic Mutations', () {
    test('moveBlock creates multiple sync entries atomically', () async {
      final block1 = createTestBlock('b1', 1000);
      final block2 = createTestBlock('b2', 2000);
      final block3 = createTestBlock('b3', 3000);

      await repository.createBlock(block1);
      await repository.createBlock(block2);
      await repository.createBlock(block3);

      // Move block 3 before block 1
      final result = await repository.moveBlock('b3', const DropIntent.before('b1'));
      expect(result.isSuccess, true);

      // Verify sync queue has updates for block 3
      final queueItems = await database.select(database.syncQueue).get();
      // Initially 3 creates. Move might create 1 update (if no normalisation needed).
      // Because it coalesces with create, the operation might remain 'create', let's check
      final allB3 = queueItems.where((q) => q.entityId == 'b3').toList();
      expect(allB3.length, 1);
      expect(allB3.first.operation, 'create'); // create + update -> create
    });

    test('splitBlock is atomic and coalesces', () async {
      final block1 = createTestBlock('b1', 1000);
      await repository.createBlock(block1);

      final updatedB1 = block1.copyWith(data: 'Split 1');
      final newB2 = createTestBlock('b2', 2000);

      final result = await repository.splitBlock(
        updatedOriginalBlock: updatedB1,
        newBlock: newB2,
      );
      expect(result.isSuccess, true);

      final queueItems = await database.select(database.syncQueue).get();
      final b1Items = queueItems.where((q) => q.entityId == 'b1').toList();
      final b2Items = queueItems.where((q) => q.entityId == 'b2').toList();

      expect(b1Items.length, 1);
      expect(b1Items.first.operation, 'create'); // Coalesced

      expect(b2Items.length, 1);
      expect(b2Items.first.operation, 'create');
    });

    test('mergeBlocks is atomic and coalesces', () async {
      final block1 = createTestBlock('b1', 1000);
      final block2 = createTestBlock('b2', 2000);
      await repository.createBlock(block1);
      await repository.createBlock(block2);

      final merged = block1.copyWith(data: 'Merged');
      final result = await repository.mergeBlocks(
        mergedBlock: merged,
        deletedBlockId: 'b2',
      );
      expect(result.isSuccess, true);

      final queueItems = await database.select(database.syncQueue).get();
      final b1Items = queueItems.where((q) => q.entityId == 'b1').toList();
      final b2Items = queueItems.where((q) => q.entityId == 'b2').toList();

      expect(b1Items.length, 1);
      expect(b1Items.first.operation, 'create'); // Coalesced

      expect(b2Items.length, 0); // Create + Delete = Remove from queue
    });
  });

  group('2.9.5 Failure / Recovery (Transaction Rollbacks)', () {
    test('splitBlock rolls back if sync enqueue fails', () async {
      final block1 = createTestBlock('b1', 1000);
      await repository.createBlock(block1);

      syncQueue.shouldFail = true;

      final updatedB1 = block1.copyWith(data: 'Split 1');
      final newB2 = createTestBlock('b2', 2000);

      final result = await repository.splitBlock(
        updatedOriginalBlock: updatedB1,
        newBlock: newB2,
      );

      expect(result.isError, true);

      // Verify db is unmodified
      final dbBlock1 = await (database.select(database.blocks)..where((t) => t.id.equals('b1'))).getSingle();
      expect(dbBlock1.data, 'Block b1'); // Unchanged

      final dbBlock2 = await (database.select(database.blocks)..where((t) => t.id.equals('b2'))).getSingleOrNull();
      expect(dbBlock2, isNull);
    });

    test('mergeBlocks rolls back if sync enqueue fails', () async {
      final block1 = createTestBlock('b1', 1000);
      final block2 = createTestBlock('b2', 2000);
      await repository.createBlock(block1);
      await repository.createBlock(block2);

      syncQueue.shouldFail = true;

      final merged = block1.copyWith(data: 'Merged');
      final result = await repository.mergeBlocks(
        mergedBlock: merged,
        deletedBlockId: 'b2',
      );

      expect(result.isError, true);

      // Verify db is unmodified
      final dbBlock1 = await (database.select(database.blocks)..where((t) => t.id.equals('b1'))).getSingle();
      expect(dbBlock1.data, 'Block b1');

      final dbBlock2 = await (database.select(database.blocks)..where((t) => t.id.equals('b2'))).getSingle();
      expect(dbBlock2.deleted, false);
    });

    test('moveBlock rolls back if sync enqueue fails', () async {
      final block1 = createTestBlock('b1', 1000);
      final block2 = createTestBlock('b2', 2000);
      await repository.createBlock(block1);
      await repository.createBlock(block2);

      syncQueue.shouldFail = true;

      final result = await repository.moveBlock('b2', const DropIntent.before('b1'));

      expect(result.isError, true);

      // Verify db is unmodified
      final dbBlock2 = await (database.select(database.blocks)..where((t) => t.id.equals('b2'))).getSingle();
      expect(dbBlock2.position, 2000);
    });
  });

  group('2.9.6 Performance tests', () {
    test('Fetching and moving blocks in a 1000-block document is performant', () async {
      // Create 1000 blocks in batch for setup
      await database.batch((batch) {
        for (int i = 0; i < 1000; i++) {
          final block = createTestBlock('block_$i', i * 1000.0);
          batch.insert(database.blocks, block.toCompanion());
        }
      });

      final stopwatch = Stopwatch()..start();

      // Move block 999 to before block 0
      final result = await repository.moveBlock('block_999', const DropIntent.before('block_0'));
      expect(result.isSuccess, true);

      stopwatch.stop();

      // In-memory sqlite should do this in < 50ms, but we'll assert < 500ms to be safe for CI environments
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      
      final movedBlock = await (database.select(database.blocks)..where((t) => t.id.equals('block_999'))).getSingle();
      expect(movedBlock.position, lessThan(0.0));
    });
  });
}
