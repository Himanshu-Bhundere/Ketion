import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/services/background_sync_scheduler.dart';
import 'package:ketion/core/services/background_sync_scheduler_factory.dart';
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
import 'package:ketion/features/sync/data/utils/conflict_resolver.dart';
import 'package:ketion/features/sync/data/utils/sync_entity_applier.dart';
import 'package:ketion/features/sync/domain/utils/sync_mutex.dart';
import 'package:ketion/features/sync/domain/services/sync_scheduler.dart';
import 'package:ketion/features/settings/presentation/providers/settings_providers.dart';

export 'package:ketion/features/sync/domain/utils/sync_mutex.dart';
export 'package:ketion/features/sync/domain/services/sync_scheduler.dart';
export 'package:ketion/features/sync/presentation/controllers/sync_controller.dart';
import 'package:ketion/features/media/data/services/attachment_sync_service_impl.dart';


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
  final db = ref.watch(appDatabaseProvider);
  final syncProvider = ref.watch(syncProviderInterfaceProvider);
  final authService = ref.watch(authServiceProvider);
  final queueRepo = ref.watch(syncQueueRepositoryProvider);
  final stateRepo = ref.watch(syncStateRepositoryProvider);
  final conflictResolver = ConflictResolver(db);
  final entityApplier = SyncEntityApplier(db);
  final settingsRepo = ref.watch(settingsRepositoryProvider);

  return SyncEngineRepositoryImpl(
    syncProvider: syncProvider,
    authService: authService,
    queueRepository: queueRepo,
    stateRepository: stateRepo,
    conflictResolver: conflictResolver,
    entityApplier: entityApplier,
    settingsRepository: settingsRepo,
    db: db,
  );
});

final syncNowUseCaseProvider = Provider<SyncNowUseCase>((ref) {
  final engineRepo = ref.watch(syncEngineRepositoryProvider);
  final widgetService = ref.watch(widgetServiceProvider);
  final attachmentSyncService = ref.watch(attachmentSyncServiceProvider);
  return SyncNowUseCase(engineRepo, widgetService, attachmentSyncService);
});

final enqueueSyncUseCaseProvider = Provider<EnqueueSyncUseCase>((ref) {
  final engineRepo = ref.watch(syncEngineRepositoryProvider);
  return EnqueueSyncUseCase(engineRepo);
});

final backgroundSyncSchedulerProvider = Provider<BackgroundSyncScheduler>((ref) {
  return getBackgroundSyncScheduler();
});

final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final mutex = ref.watch(syncMutexProvider);
  final useCase = ref.watch(syncNowUseCaseProvider);
  final scheduler = ref.watch(backgroundSyncSchedulerProvider);
  return SyncScheduler(mutex, useCase, scheduler);
});

