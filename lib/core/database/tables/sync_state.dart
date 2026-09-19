import 'package:drift/drift.dart';

@DataClassName('SyncStateData')
class SyncStates extends Table {
  TextColumn get deviceId => text()(); // The device ID
  TextColumn get provider => text()(); // e.g. 'google_drive'
  TextColumn get lastDriveCursor => text().nullable()();
  DateTimeColumn get lastSyncTime => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {deviceId, provider};
}
