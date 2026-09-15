import 'package:drift/drift.dart';

@DataClassName('AttachmentData')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get blockId => text()();
  TextColumn get driveFileId => text().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get mimeType => text()();
  TextColumn get checksumSha256 => text().nullable()();
  IntColumn get fileSize => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get duration => integer().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get uploadStatus => text().withDefault(const Constant('Pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinnedOffline => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
