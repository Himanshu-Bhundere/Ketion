import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.openInMemory();
  
  db.execute('''
    CREATE VIRTUAL TABLE search_fts USING fts5(
      entityId UNINDEXED,
      entityType UNINDEXED,
      content
    );
  ''');
  
  db.execute("INSERT INTO search_fts(entityId, entityType, content) VALUES ('abc', 'page', 'hello world')");
  // ignore: avoid_print
    print('Inserted');
  
  try {
    db.execute("DELETE FROM search_fts WHERE entityId = 'abc' AND entityType = 'page'");
    // ignore: avoid_print
    print('Deleted successfully by entityId');
  } catch (e) {
    // ignore: avoid_print
    print('Failed to delete: \$e');
  }
}
