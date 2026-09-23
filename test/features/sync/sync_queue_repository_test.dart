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

    final enqueueRes = await repository.enqueue(item);
    expect(enqueueRes, isA<Success<void>>());

    final pendingRes = await repository.getPendingItems();
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

    await repository.enqueue(item);
    await repository.updateStatus('item-1', SyncQueueItemStatus.completed);

    final pendingRes = await repository.getPendingItems();
    expect(pendingRes, isA<Success<List<SyncQueueItem>>>());
    final items = (pendingRes as Success<List<SyncQueueItem>>).value;
    expect(items.isEmpty, true);
  });
}
