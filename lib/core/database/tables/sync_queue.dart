import 'package:drift/drift.dart';

@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityTable => text()(); // The table name (e.g., 'blocks', 'pages')
  TextColumn get entityId => text()(); // The ID of the changed entity
  TextColumn get operation => text()(); // 'create', 'update', 'delete', 'restore'
  TextColumn get payload => text().nullable()(); // Optional JSON payload for the change
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // 'pending', 'processing', 'failed', 'completed'
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
