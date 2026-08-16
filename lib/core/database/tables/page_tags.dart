import 'package:drift/drift.dart';
import 'pages.dart';
import 'tags.dart';

@DataClassName('PageTag')
class PageTags extends Table {
  TextColumn get pageId => text().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId => text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {pageId, tagId};
}
