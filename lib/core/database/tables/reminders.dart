import 'package:drift/drift.dart';
import 'pages.dart';
import 'blocks.dart';

@DataClassName('Reminder')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get blockId => text().nullable().references(Blocks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get reminderTime => dateTime()();
  TextColumn get recurrenceRule => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
