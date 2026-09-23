import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/auth/presentation/providers/auth_providers.dart';
import 'package:ketion/features/sync/presentation/providers/sync_providers.dart';

enum SyncUiStatus {
  savedLocally,
  syncPending,
  syncing,
  synced,
  offline,
  syncFailed,
  authenticationRequired,
}

class SyncUiState {
  final SyncUiStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const SyncUiState({
    this.status = SyncUiStatus.savedLocally,
    this.lastSyncedAt,
    this.errorMessage,
  });

  SyncUiState copyWith({
    SyncUiStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) {
    return SyncUiState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncController extends StateNotifier<SyncUiState> {
  final Ref _ref;

  SyncController(this._ref) : super(const SyncUiState()) {
    _init();
  }

  Future<void> _init() async {
    // Check auth status first
    final authService = _ref.read(authServiceProvider);
    final isSignedIn = await authService.isSignedIn();
    if (!isSignedIn) {
      state = state.copyWith(status: SyncUiStatus.authenticationRequired);
      return;
    }
    
    // Default starting state if authenticated
    state = state.copyWith(status: SyncUiStatus.savedLocally);
  }

  Future<void> syncNow() async {
    if (state.status == SyncUiStatus.syncing) return;
    
    state = state.copyWith(status: SyncUiStatus.syncing);

    final syncNowUseCase = _ref.read(syncNowUseCaseProvider);
    final result = await syncNowUseCase();

    if (result is Success) {
      state = state.copyWith(
        status: SyncUiStatus.synced,
        lastSyncedAt: DateTime.now().toUtc(),
        errorMessage: null,
      );
    } else if (result is Error) {
      final failure = result.failure;
      appLogger.e('Manual sync failed: ${failure.message}');
      
      // We could differentiate based on failure type, e.g. NetworkFailure -> offline
      state = state.copyWith(
        status: SyncUiStatus.syncFailed,
        errorMessage: failure.message,
      );
    }
  }

  void markSyncPending() {
    if (state.status != SyncUiStatus.authenticationRequired && 
        state.status != SyncUiStatus.syncing) {
      state = state.copyWith(status: SyncUiStatus.syncPending);
    }
  }
}

final syncControllerProvider = StateNotifierProvider<SyncController, SyncUiState>((ref) {
  return SyncController(ref);
});
