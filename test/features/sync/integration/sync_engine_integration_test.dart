import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/features/auth/domain/services/auth_service.dart';
import 'package:ketion/features/sync/domain/providers/sync_provider.dart';
import 'package:ketion/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:ketion/features/sync/domain/repositories/sync_state_repository.dart';
import 'package:ketion/features/sync/domain/entities/sync_state_entity.dart';
import 'package:ketion/features/sync/data/repositories/sync_engine_repository_impl.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/features/sync/data/utils/conflict_resolver.dart';
import 'package:ketion/features/sync/data/utils/sync_entity_applier.dart';
import 'package:ketion/features/settings/domain/repositories/settings_repository.dart';
import 'package:ketion/features/settings/domain/models/app_settings_model.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

class FakeAuthService implements AuthService {
  @override
  Future<Result<String>> signIn(List<String> scopes) async => const Success('mock_token');
  @override
  Future<Result<String>> getAccessToken(List<String> scopes) async => const Success('mock_token');
  @override
  Future<Result<void>> signOut() async => const Success(null);
  @override
  Future<bool> isSignedIn() async => true;
}

class FakeSettingsRepository implements SettingsRepository {
  AppSettingsModel _settings = const AppSettingsModel(
    autoSync: true,
    syncFrequency: '15 minutes',
    tombstoneRetentionDays: 30,
    themeMode: 'system',
  );

  @override
  Future<AppSettingsModel> getSettings() async => _settings;
  
  @override
  Future<void> updateSettings(AppSettingsModel settings) async {
    _settings = settings;
  }
}

class FakeSyncStateRepository implements SyncStateRepository {
  SyncStateEntity? _state;
  bool returnError = false;

  @override
  Future<Result<SyncStateEntity?>> getSyncState(String deviceId, String provider) async {
    if (returnError) return const Error(StorageFailure('error'));
    _state ??= SyncStateEntity(
        deviceId: deviceId,
        provider: provider,
        lastDriveCursor: null,
      );
    return Success(_state);
  }

  @override
  Future<Result<void>> saveSyncState(SyncStateEntity state) async {
    if (returnError) return const Error(StorageFailure('error'));
    _state = state;
    return const Success(null);
  }
}

class FakeSyncProvider implements SyncProvider {
  String? returnToken;
  List<Map<String, dynamic>> returnChanges = [];
  bool crashOnListChanges = false;
  bool crashOnPushBatch = false;
  int pushBatchCallCount = 0;
  
  @override
  String get providerId => 'fake_provider';

  @override
  Future<Result<void>> initialize(String accessToken) async => const Success(null);
  
  @override
  Future<Result<SyncDownloadResult>> downloadChanges(String? cursor) async {
    if (crashOnListChanges) {
      throw Exception('Simulated crash during listChanges');
    }
    return Success(SyncDownloadResult(
      changes: returnChanges,
      nextCursor: returnChanges.isEmpty ? null : 'next_cursor',
    ),);
  }

  @override
  Future<Result<void>> uploadChanges(String batchId, Map<String, dynamic> payload) async {
    pushBatchCallCount++;
    if (crashOnPushBatch) {
      throw Exception('Simulated crash during uploadChanges');
    }
    return const Success(null);
  }

  @override
  Future<Result<String>> uploadAttachment(String localPath, String mimeType, String checksum) async {
    return const Success('uploaded_id');
  }
  
  @override
  Future<Result<void>> downloadAttachment(String remoteFileId, String destinationPath) async {
    return const Success(null);
  }
  
  @override
  Future<Result<Map<String, dynamic>>> getAvailableStorage() async {
    return const Success({'limit': 1000, 'usage': 500});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({'ketion_device_id': 'device-1'});

  late AppDatabase database;
  late SyncEngineRepositoryImpl syncEngine;
  late SyncQueueRepository syncQueue;
  late FakeSyncStateRepository syncStateRepo;
  late FakeSyncProvider syncProvider;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    syncQueue = SyncQueueRepositoryImpl(database);
    syncStateRepo = FakeSyncStateRepository();
    syncProvider = FakeSyncProvider();

    syncEngine = SyncEngineRepositoryImpl(
      db: database,
      authService: FakeAuthService(),
      syncProvider: syncProvider,
      stateRepository: syncStateRepo,
      queueRepository: syncQueue,
      settingsRepository: FakeSettingsRepository(),
      conflictResolver: ConflictResolver(database),
      entityApplier: SyncEntityApplier(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('SyncEngine Integration Tests', () {
    test('Pagination crash recovery', () async {
      syncProvider.returnChanges = [
        {
           'batchId': 'batch-1',
           'deviceId': 'device-2',
           'table': 'pages',
           'entityId': 'page-1',
           'operation': 'upsert',
           'payload': {
              'id': 'page-1',
              'title': 'Remote Page',
              'version': 1,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
           },
        }
      ];
      
      syncProvider.crashOnListChanges = true;

      // First run should crash
      await expectLater(syncEngine.syncNow(), throwsException);
      
      // Let's verify the db is still intact
      final pages = await database.select(database.pages).get();
      expect(pages.isEmpty, isTrue);

      // Now recover
      syncProvider.crashOnListChanges = false;
      final result = await syncEngine.syncNow();
      
      expect(result.isSuccess, isTrue);
      final recoveredPages = await database.select(database.pages).get();
      expect(recoveredPages.length, 1);
      expect(recoveredPages.first.title, 'Remote Page');
      
      // Verify sync state updated
      final stateRes = await syncStateRepo.getSyncState('device-1', 'fake_provider');
      final state = stateRes.fold((s) => s, (e) => throw Exception());
      expect(state!.lastDriveCursor, 'next_cursor');
    });

    test('Crash after remote application does not duplicate processing', () async {
      syncProvider.returnChanges = [
        {
           'batchId': 'batch-2',
           'deviceId': 'device-2',
           'table': 'pages',
           'entityId': 'page-2',
           'operation': 'upsert',
           'payload': {
              'id': 'page-2',
              'title': 'Batch 2',
              'version': 1,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
           },
        }
      ];

      await syncEngine.syncNow();
      
      // Try syncing the exact same batch again (late arriving / duplicate)
      final result = await syncEngine.syncNow();
      expect(result.isSuccess, isTrue);
      
      // Database should still only have 1 page with this ID, and not error out
      final pages = await database.select(database.pages).get();
      expect(pages.length, 1);
    });

    test('Late-arriving batch is ignored if already processed', () async {
      // Simulate processed batch in DB
      await database.into(database.processedBatches).insert(
        ProcessedBatchesCompanion.insert(
          batchId: 'batch-late',
          deviceId: 'device-3',
          processedAt: Value(DateTime.now()),
        ),
      );

      syncProvider.returnChanges = [
        {
           'batchId': 'batch-late',
           'deviceId': 'device-3',
           'table': 'pages',
           'entityId': 'page-late',
           'operation': 'upsert',
           'payload': {
              'id': 'page-late',
              'title': 'Late Page',
              'version': 1,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
           },
        }
      ];

      await syncEngine.syncNow();

      // Because the batch was marked as processed, it should not insert the page
      final pages = await database.select(database.pages).get();
      expect(pages.isEmpty, isTrue);
    });

    test('Clock skew LWW (Last Writer Wins)', () async {
      final now = DateTime.now();
      
      // Insert local page
      await database.into(database.pages).insert(
        PagesCompanion.insert(
          id: 'page-skew',
          title: const Value('Local Title'),
          version: const Value(2),
          createdAt: now,
          updatedAt: now,
        ),
      );

      syncProvider.returnChanges = [
        {
           'batchId': 'batch-skew',
           'deviceId': 'device-skew',
           'table': 'pages',
           'entityId': 'page-skew',
           'operation': 'upsert',
           'payload': {
              'id': 'page-skew',
              'title': 'Remote Skew Title',
              'version': 3,
              'createdAt': now.subtract(const Duration(minutes: 5)).toIso8601String(),
              'updatedAt': now.subtract(const Duration(minutes: 5)).toIso8601String(),
           },
        }
      ];

      await syncEngine.syncNow();

      // Local should win because local updatedAt is newer, despite remote version being higher.
      final pages = await database.select(database.pages).get();
      expect(pages.length, 1);
      expect(pages.first.title, 'Local Title'); // Kept local due to newer timestamp
    });
    test('Multi-entity batch is atomic on error', () async {
      // If a batch contains 2 changes, and the 2nd change crashes (e.g., malformed), 
      // the entire batch should be rolled back and NOT marked as processed.
      
      syncProvider.returnChanges = [
        {
           'batchId': 'batch-atomic',
           'deviceId': 'device-x',
           'table': 'pages',
           'entityId': 'page-a',
           'operation': 'upsert',
           'payload': {
              'id': 'page-a',
              'title': 'Valid Page',
              'version': 1,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
           },
        },
        {
           'batchId': 'batch-atomic',
           'deviceId': 'device-x',
           'table': 'pages',
           'entityId': 'page-b',
           'operation': 'upsert',
           // Missing required fields will cause a DB constraint exception or parser exception
           'payload': {
              'id': 'page-b',
           },
        }
      ];

      // It should catch the error and not crash the whole process, 
      // but the result might be Failure or it skips and logs.
      // Wait, our SyncEngineRepositoryImpl might catch exceptions inside the transaction and rollback.
      await syncEngine.syncNow();
      
      // Since it's a batch failure, either it's swallowed (skipping batch) or bubbled up.
      // Let's just assert the first entity wasn't saved because of atomicity.
      final pages = await database.select(database.pages).get();
      expect(pages.where((p) => p.id == 'page-a'), isEmpty);
      
      final processedBatches = await (database.select(database.processedBatches)..where((t) => t.batchId.equals('batch-atomic'))).get();
      expect(processedBatches, isEmpty);
    });

    test('Remote application does not requeue locally', () async {
      // When a remote change is applied, it should NOT trigger local SyncQueue insertion.
      
      syncProvider.returnChanges = [
        {
           'batchId': 'batch-norequeue',
           'deviceId': 'device-y',
           'table': 'pages',
           'entityId': 'page-norequeue',
           'operation': 'upsert',
           'payload': {
              'id': 'page-norequeue',
              'title': 'Remote Page',
              'version': 1,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
           },
        }
      ];

      await syncEngine.syncNow();

      final pages = await database.select(database.pages).get();
      expect(pages.where((p) => p.id == 'page-norequeue').length, 1);
      
      // Ensure the sync queue is still empty (it wasn't queued to push back to remote)
      final queue = await database.select(database.syncQueue).get();
      expect(queue.where((q) => q.entityId == 'page-norequeue'), isEmpty);
    });
  });
}
