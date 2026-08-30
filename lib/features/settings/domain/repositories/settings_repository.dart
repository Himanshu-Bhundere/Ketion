import '../models/app_settings_model.dart';

abstract class SettingsRepository {
  Future<AppSettingsModel> getSettings();
  Future<void> updateSettings(AppSettingsModel settings);
}
