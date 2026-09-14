abstract class BackgroundSyncScheduler {
  Future<void> schedulePeriodicSync();
  Future<void> cancelSync();
}
