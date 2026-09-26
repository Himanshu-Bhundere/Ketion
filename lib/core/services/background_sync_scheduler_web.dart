import 'background_sync_scheduler.dart';

class WebBackgroundSyncScheduler implements BackgroundSyncScheduler {
  @override
  Future<void> schedulePeriodicSync() async {
    // Workmanager is not supported on web.
    // In Web, background sync is handled by Service Workers or visibility events.
  }

  @override
  Future<void> cancelSync() async {
    // No-op for web
  }
}

BackgroundSyncScheduler getBackgroundSyncScheduler() =>
    WebBackgroundSyncScheduler();
