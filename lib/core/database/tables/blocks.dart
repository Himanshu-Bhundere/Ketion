import 'package:drift/drift.dart';
import 'pages.dart';

@DataClassName('Block')
class Blocks extends Table {
  TextColumn get id => text()();
  TextColumn get pageId =>
      text().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get parentBlockId =>
      text().nullable().references(Blocks, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  RealColumn get position => real()();
  TextColumn get data => text()(); // JSON string
  TextColumn get searchableText => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
