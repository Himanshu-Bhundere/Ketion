import 'package:workmanager/workmanager.dart';
import 'background_sync_scheduler.dart';

class NativeBackgroundSyncScheduler implements BackgroundSyncScheduler {
  static const String _periodicSyncTask = 'ketion.sync.periodic';

  @override
  Future<void> schedulePeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      _periodicSyncTask,
      _periodicSyncTask,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  @override
  Future<void> cancelSync() async {
    await Workmanager().cancelByUniqueName(_periodicSyncTask);
  }
}

BackgroundSyncScheduler getBackgroundSyncScheduler() => NativeBackgroundSyncScheduler();
