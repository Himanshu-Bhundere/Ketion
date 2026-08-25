import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/widgets/presentation/providers/widget_providers.dart';
import 'package:ketion/features/auth/presentation/providers/auth_providers.dart';
import 'package:ketion/features/sync/data/providers/google_drive_sync_provider.dart';
import 'package:ketion/features/sync/data/repositories/sync_engine_repository_impl.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/features/sync/data/repositories/sync_state_repository_impl.dart';
import 'package:ketion/features/sync/domain/providers/sync_provider.dart';
import 'package:ketion/features/sync/domain/repositories/sync_engine_repository.dart';
import 'package:ketion/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:ketion/features/sync/domain/repositories/sync_state_repository.dart';
import 'package:ketion/features/sync/domain/usecases/enqueue_sync_usecase.dart';
import 'package:ketion/features/sync/domain/usecases/sync_now_usecase.dart';

final syncProviderInterfaceProvider = Provider<SyncProvider>((ref) {
  return GoogleDriveSyncProvider();
});

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncQueueRepositoryImpl(db);
});

final syncStateRepositoryProvider = Provider<SyncStateRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncStateRepositoryImpl(db);
});

final syncEngineRepositoryProvider = Provider<SyncEngineRepository>((ref) {
  final syncProvider = ref.watch(syncProviderInterfaceProvider);
  final authService = ref.watch(authServiceProvider);
  final queueRepo = ref.watch(syncQueueRepositoryProvider);
  final stateRepo = ref.watch(syncStateRepositoryProvider);

  return SyncEngineRepositoryImpl(
    syncProvider: syncProvider,
    authService: authService,
    queueRepository: queueRepo,
    stateRepository: stateRepo,
  );
});
final syncNowUseCaseProvider = Provider<SyncNowUseCase>((ref) {
  final engineRepo = ref.watch(syncEngineRepositoryProvider);
  final widgetService = ref.watch(widgetServiceProvider);
  return SyncNowUseCase(engineRepo, widgetService);
});

final enqueueSyncUseCaseProvider = Provider<EnqueueSyncUseCase>((ref) {
  final engineRepo = ref.watch(syncEngineRepositoryProvider);
  return EnqueueSyncUseCase(engineRepo);
});
