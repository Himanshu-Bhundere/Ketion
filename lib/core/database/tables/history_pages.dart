import 'package:drift/drift.dart';
import 'pages.dart';

@DataClassName('HistoryPage')
class HistoryPages extends Table {
  TextColumn get id => text()();
  TextColumn get pageId =>
      text().references(Pages, #id, onDelete: KeyAction.cascade)();
  IntColumn get snapshotVersion => integer()();
  BlobColumn get compressedSnapshot => blob()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
