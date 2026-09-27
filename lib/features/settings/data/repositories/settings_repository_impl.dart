import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/app_settings_model.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final AppDatabase _db;

  SettingsRepositoryImpl(this._db);

  @override
  Future<AppSettingsModel> getSettings() async {
    final entity = await (_db.select(_db.appSettingsTable)
          ..where((t) => t.id.equals('default')))
        .getSingleOrNull();

    if (entity == null) {
      // Create default settings if not exists
      const newModel = AppSettingsModel();
      await _db.into(_db.appSettingsTable).insert(
            AppSettingsTableCompanion.insert(
              id: 'default',
              themeMode: const Value('System'),
              syncFrequency: const Value('15 minutes'),
              autoSync: const Value(true),
              cacheLimitMB: const Value(100),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      return newModel;
    }

    return AppSettingsModel(
      themeMode: entity.themeMode,
      syncFrequency: entity.syncFrequency,
      autoSync: entity.autoSync,
      cacheLimitMB: entity.cacheLimitMB,
      lastCleanup: entity.lastCleanup,
    );
  }

  @override
  Future<void> updateSettings(AppSettingsModel settings) async {
    await (_db.update(_db.appSettingsTable)
          ..where((t) => t.id.equals('default')))
        .write(
      AppSettingsTableCompanion(
        themeMode: Value(settings.themeMode),
        syncFrequency: Value(settings.syncFrequency),
        autoSync: Value(settings.autoSync),
        cacheLimitMB: Value(settings.cacheLimitMB),
        lastCleanup: Value(settings.lastCleanup),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
