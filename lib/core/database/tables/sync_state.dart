import 'package:drift/drift.dart';

@DataClassName('SyncStateData')
class SyncStates extends Table {
  TextColumn get deviceId => text()(); // The device ID
  TextColumn get provider => text()(); // e.g. 'google_drive'
  IntColumn get lastSyncedVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncTime => dateTime().nullable()();
  TextColumn get remoteSyncCursor => text().nullable()(); // PageToken for google drive

  @override
  Set<Column> get primaryKey => {deviceId, provider};
}
