import 'package:drift/drift.dart';

@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityTable =>
      text()(); // The table name (e.g., 'blocks', 'pages')
  TextColumn get entityId => text()(); // The ID of the changed entity
  TextColumn get operation =>
      text()(); // 'create', 'update', 'delete', 'restore'
  TextColumn get payload =>
      text().nullable()(); // Optional JSON payload for the change
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(
        const Constant(
          'pending',
        ),
      )(); // 'pending', 'uploading', 'uploaded', 'failed'
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
