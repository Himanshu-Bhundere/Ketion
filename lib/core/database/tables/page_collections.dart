import 'package:drift/drift.dart';
import 'pages.dart';
import 'collections.dart';

@DataClassName('PageCollection')
class PageCollections extends Table {
  TextColumn get pageId =>
      text().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get collectionId =>
      text().references(Collections, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {pageId, collectionId};
}
