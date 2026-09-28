import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/backup_service.dart';
import '../providers/settings_notifier.dart';
import '../../domain/models/app_settings_model.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsRepositoryImpl(db);
});

final appSettingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettingsModel>(() {
  return SettingsNotifier();
});
