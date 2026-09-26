import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:ketion/core/services/background_sync_scheduler.dart';
import 'package:ketion/features/sync/domain/utils/sync_mutex.dart';
import 'package:ketion/features/sync/domain/usecases/sync_now_usecase.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/core/utils/logger.dart';

class SyncScheduler with WidgetsBindingObserver {
  final SyncMutex _syncMutex;
  final SyncNowUseCase _syncNowUseCase;
  final BackgroundSyncScheduler _backgroundScheduler;
  DateTime? _lastSyncTime;
  Timer? _foregroundTimer;
  static const Duration _syncCooldown = Duration(minutes: 1);
  static const Duration _foregroundInterval = Duration(minutes: 2);

  SyncScheduler(
      this._syncMutex, this._syncNowUseCase, this._backgroundScheduler) {
    WidgetsBinding.instance.addObserver(this);
    _startForegroundTimer();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foregroundTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      appLogger.i('App resumed, triggering sync...');
      performImmediateSync();
    }
  }

  void _startForegroundTimer() {
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(_foregroundInterval, (_) {
      appLogger.d('Foreground timer triggered sync');
      performImmediateSync();
    });
  }

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
      final now = DateTime.now().toUtc();
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
        _lastSyncTime = DateTime.now().toUtc();
      }
      return result;
    } finally {
      _syncMutex.release();
    }
  }
}
