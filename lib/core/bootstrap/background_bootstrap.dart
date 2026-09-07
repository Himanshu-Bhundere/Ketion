import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/config/env_config.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/features/sync/presentation/providers/sync_providers.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    EnvConfig.init(environment: 'dev', isProduction: false);
    final container = ProviderContainer();
    
    final syncScheduler = container.read(syncSchedulerProvider);
    
    try {
      final res = await syncScheduler.performImmediateSync();
      return res is Success;
    } catch (e) {
      appLogger.e('Background sync failed: $e');
      return false;
    } finally {
      container.dispose();
    }
  });
}

class BackgroundBootstrap {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    // In actual usage, the app would schedule the task somewhere else,
    // e.g. after login or explicitly by the user, via SyncScheduler.scheduleBackgroundSync().
  }
}
