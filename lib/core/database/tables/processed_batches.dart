import 'package:drift/drift.dart';

@DataClassName('ProcessedBatchData')
class ProcessedBatches extends Table {
  TextColumn get batchId => text()(); // UUIDv7 of the batch
  TextColumn get deviceId => text()(); // Which device produced this batch
  DateTimeColumn get processedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {batchId};
}
