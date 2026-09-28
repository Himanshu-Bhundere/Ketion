import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import '../../domain/models/app_settings_model.dart';
import 'settings_providers.dart';
import 'package:path_provider/path_provider.dart';

class SettingsNotifier extends AsyncNotifier<AppSettingsModel> {
  @override
  Future<AppSettingsModel> build() async {
    return ref.watch(settingsRepositoryProvider).getSettings();
  }

  Future<void> updateThemeMode(String mode) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(themeMode: mode);
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).updateSettings(updated);
  }

  Future<void> updateSyncFrequency(String frequency) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(syncFrequency: frequency);
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).updateSettings(updated);

    // Update Workmanager
    await Workmanager().cancelAll();

    if (frequency == 'Manual') return;

    Duration syncDuration = const Duration(minutes: 15);
    if (frequency == '30 minutes') {
      syncDuration = const Duration(minutes: 30);
    } else if (frequency == '1 hour') {
      syncDuration = const Duration(hours: 1);
    }

    if (frequency == '15 minutes' ||
        frequency == '30 minutes' ||
        frequency == '1 hour') {
      await Workmanager().registerPeriodicTask(
        'syncTask',
        'sync_now',
        frequency: syncDuration,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    }
  }

  Future<void> clearCache() async {
    final current = state.value;
    if (current == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
        tempDir.createSync();
      }
    } catch (e) {
      // Ignore cache clearing errors
    }

    final updated = current.copyWith(lastCleanup: DateTime.now());
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).updateSettings(updated);
  }
}
