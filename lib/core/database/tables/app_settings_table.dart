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
  TextColumn get accentColor => text().withDefault(const Constant('blue'))();
  TextColumn get fontSize => text().withDefault(const Constant('medium'))();
  TextColumn get editorAppearance => text().withDefault(const Constant('comfortable'))();
  BoolColumn get highContrast => boolean().withDefault(const Constant(false))();
  BoolColumn get reducedMotion => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastCleanup => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
