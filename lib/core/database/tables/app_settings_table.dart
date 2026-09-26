import 'package:drift/drift.dart';

@DataClassName('AppSettingEntity')
class AppSettingsTable extends Table {
  TextColumn get id => text()();
  TextColumn get themeMode => text().withDefault(const Constant('System'))();
  TextColumn get syncFrequency =>
      text().withDefault(const Constant('15 minutes'))();
  BoolColumn get autoSync => boolean().withDefault(const Constant(true))();
  IntColumn get cacheLimitMB => integer().withDefault(const Constant(100))();
  IntColumn get tombstoneRetentionDays =>
      integer().withDefault(const Constant(30))();
  DateTimeColumn get lastCleanup => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
