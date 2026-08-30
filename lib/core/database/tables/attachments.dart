import 'package:drift/drift.dart';

@DataClassName('AttachmentData')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text()();
  TextColumn get blockId => text()();
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get size => integer()();
  TextColumn get sha256 => text()();
  TextColumn get relativePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
