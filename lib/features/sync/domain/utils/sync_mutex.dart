import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a global mechanism to prevent overlapping sync operations.
/// Essential for ensuring foreground and background syncs don't collide.
class SyncMutex {
  bool _isSyncing = false;

  /// Returns true if a sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Attempts to acquire the sync lock.
  /// Returns true if acquired successfully, false if already syncing.
  bool tryAcquire() {
    if (_isSyncing) return false;
    _isSyncing = true;
    return true;
  }

  /// Releases the sync lock.
  void release() {
    _isSyncing = false;
  }
}

final syncMutexProvider = Provider<SyncMutex>((ref) {
  return SyncMutex();
});
