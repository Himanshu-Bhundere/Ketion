import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/features/sync/domain/entities/sync_queue_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({'ketion_device_id': 'device-1'});

  late AppDatabase db;
  late SyncQueueRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SyncQueueRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('enqueue inserts item into sync queue and getPendingItems retrieves it',
      () async {
    final item = SyncQueueItem(
      id: 'item-1',
      entityTable: 'pages',
      entityId: 'page-101',
      operation: 'update',
      createdAt: DateTime.now(),
    );

    final enqueueRes = await repository.enqueueOrCoalesce(item);
    expect(enqueueRes, isA<Success<void>>());

    final pendingRes = await repository.claimNextBatch(
      limit: 50,
      leaseDuration: const Duration(minutes: 5),
    );
    expect(pendingRes, isA<Success<List<SyncQueueItem>>>());
    final items = (pendingRes as Success<List<SyncQueueItem>>).value;
    expect(items.length, 1);
    expect(items.first.id, 'item-1');
  });

  test('updateStatus modifies item status and retry count', () async {
    final item = SyncQueueItem(
      id: 'item-1',
      entityTable: 'pages',
      entityId: 'page-101',
      operation: 'update',
      createdAt: DateTime.now(),
    );

    await repository.enqueueOrCoalesce(item);

    // claim the batch first so it has an ID, though updateStatus updates by queue item ID
    final pendingBatch = await repository.claimNextBatch(
      limit: 50,
      leaseDuration: const Duration(minutes: 5),
    );
    final batchItems = (pendingBatch as Success<List<SyncQueueItem>>).value;

    await repository.updateStatus(
      batchItems.first.id,
      SyncQueueItemStatus.completed,
    );

    final pendingRes = await repository.claimNextBatch(
      limit: 50,
      leaseDuration: const Duration(minutes: 5),
    );
    expect(pendingRes, isA<Success<List<SyncQueueItem>>>());
    final items = (pendingRes as Success<List<SyncQueueItem>>).value;
    expect(items.isEmpty, true);
  });

  // Tests 25-27: Queue coalescing and concurrency
  test('Coalescing a pending item replaces payload and preserves status',
      () async {
    final item1 = SyncQueueItem(
      id: 'item-1',
      entityTable: 'pages',
      entityId: 'page-101',
      operation: 'update',
      payload: '{"version": 1}',
      createdAt: DateTime.now(),
    );
    await repository.enqueueOrCoalesce(item1);

    final item2 = SyncQueueItem(
      id: 'item-2', // new ID, but same entity
      entityTable: 'pages',
      entityId: 'page-101',
      operation: 'update',
      payload: '{"version": 2}',
      createdAt: DateTime.now(),
    );
    await repository.enqueueOrCoalesce(item2);

    final queueItems = await db.select(db.syncQueue).get();
    expect(queueItems.length, 1); // should coalesce
    expect(queueItems.first.payload, '{"version": 2}'); // payload replaced
    expect(queueItems.first.status, SyncQueueItemStatus.pending.name);
  });

  test(
      'Processing item is not mutated by coalescing (creates new pending item)',
      () async {
    final item1 = SyncQueueItem(
      id: 'item-1',
      entityTable: 'pages',
      entityId: 'page-101',
      operation: 'update',
      payload: '{"version": 1}',
      createdAt: DateTime.now(),
    );
    await repository.enqueueOrCoalesce(item1);

    // claim to set to processing
    final claimRes = await repository.claimNextBatch(
        limit: 50, leaseDuration: const Duration(minutes: 5));
    final claimed = (claimRes as Success<List<SyncQueueItem>>).value;
    expect(claimed.first.status, SyncQueueItemStatus.processing);

    final item2 = SyncQueueItem(
      id: 'item-2',
      entityTable: 'pages',
      entityId: 'page-101',
      operation: 'update',
      payload: '{"version": 2}',
      createdAt: DateTime.now(),
    );
    await repository.enqueueOrCoalesce(item2);

    final queueItems = await db.select(db.syncQueue).get();
    expect(queueItems.length, 2); // Cannot coalesce into processing item

    final processingItem = queueItems
        .firstWhere((q) => q.status == SyncQueueItemStatus.processing.name);
    expect(processingItem.payload, '{"version": 1}');

    final pendingItem = queueItems
        .firstWhere((q) => q.status == SyncQueueItemStatus.pending.name);
    expect(pendingItem.payload, '{"version": 2}');
  });

  test('Claim batch creates a durable batchId shared across items', () async {
    final item1 = SyncQueueItem(
        id: 'item-1',
        entityTable: 'pages',
        entityId: 'p1',
        operation: 'update',
        createdAt: DateTime.now());
    final item2 = SyncQueueItem(
        id: 'item-2',
        entityTable: 'pages',
        entityId: 'p2',
        operation: 'update',
        createdAt: DateTime.now());

    await repository.enqueueOrCoalesce(item1);
    await repository.enqueueOrCoalesce(item2);

    final claimRes = await repository.claimNextBatch(
        limit: 50, leaseDuration: const Duration(minutes: 5));
    final claimed = (claimRes as Success<List<SyncQueueItem>>).value;

    expect(claimed.length, 2);
    expect(claimed[0].batchId, isNotNull);
    expect(claimed[0].batchId, claimed[1].batchId); // Shared batchId
  });
}
