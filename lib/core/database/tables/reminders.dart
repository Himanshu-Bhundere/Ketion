import 'package:drift/drift.dart';
import 'pages.dart';
import 'blocks.dart';

@DataClassName('Reminder')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get pageId =>
      text().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get blockId =>
      text().nullable().references(Blocks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withDefault(const Constant(''))();
  DateTimeColumn get reminderTime => dateTime()();
  TextColumn get timezone => text().withDefault(const Constant('UTC'))();
  TextColumn get recurrenceRule => text().nullable()();
  DateTimeColumn get snoozeUntil => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
