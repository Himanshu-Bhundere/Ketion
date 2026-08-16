import 'package:drift/drift.dart';

@DataClassName('Tag')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
