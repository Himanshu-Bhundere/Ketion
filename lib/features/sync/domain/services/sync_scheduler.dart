import 'package:ketion/core/services/background_sync_scheduler.dart';
import 'package:ketion/features/sync/domain/utils/sync_mutex.dart';
import 'package:ketion/features/sync/domain/usecases/sync_now_usecase.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/core/utils/logger.dart';

class SyncScheduler {
  final SyncMutex _syncMutex;
  final SyncNowUseCase _syncNowUseCase;
  final BackgroundSyncScheduler _backgroundScheduler;
  DateTime? _lastSyncTime;
  static const Duration _syncCooldown = Duration(minutes: 5);

  SyncScheduler(this._syncMutex, this._syncNowUseCase, this._backgroundScheduler);

  /// Schedules the background periodic sync using the platform abstraction.
  Future<void> scheduleBackgroundSync() async {
    await _backgroundScheduler.schedulePeriodicSync();
  }

  /// Cancels the background periodic sync.
  Future<void> cancelBackgroundSync() async {
    await _backgroundScheduler.cancelSync();
  }

  /// Attempts to perform an immediate sync if no other sync is running.
  /// If [force] is true, it bypasses the cooldown period.
  Future<Result<void>> performImmediateSync({bool force = false}) async {
    if (!force && _lastSyncTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastSyncTime!) < _syncCooldown) {
        appLogger.d('Sync skipped: Cooldown period active.');
        return const Success(null);
      }
    }

    if (!_syncMutex.tryAcquire()) {
      appLogger.w('Sync skipped: A sync operation is already in progress.');
      return const Success(null); // or a specific failure type
    }

    try {
      final result = await _syncNowUseCase();
      if (result is Success) {
        _lastSyncTime = DateTime.now();
      }
      return result;
    } finally {
      _syncMutex.release();
    }
  }
}
