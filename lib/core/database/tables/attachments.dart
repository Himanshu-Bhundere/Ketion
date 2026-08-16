import 'package:drift/drift.dart';

@DataClassName('Attachment')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get driveFileId => text().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get checksumSha256 => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get duration => integer().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get uploadStatus => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
