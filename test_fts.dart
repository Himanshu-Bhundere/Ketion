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
  print('Inserted');
  
  try {
    db.execute("DELETE FROM search_fts WHERE entityId = 'abc' AND entityType = 'page'");
    print('Deleted successfully by entityId');
  } catch (e) {
    print('Failed to delete: \$e');
  }
}
