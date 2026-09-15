import 'package:drift/drift.dart';

@DataClassName('SyncStateData')
class SyncStates extends Table {
  TextColumn get deviceId => text()(); // The device ID
  TextColumn get provider => text()(); // e.g. 'google_drive'
  IntColumn get lastAppliedGeneration => integer().withDefault(const Constant(0))();
  TextColumn get pageCursor => text().nullable()();
  DateTimeColumn get lastSyncTime => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {deviceId, provider};
}
