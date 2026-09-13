import re
import sys

file_path = "c:/Projects/Ketion/lib/core/database/app_database.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Bump schema version
content = re.sub(
    r"int get schemaVersion => \d+;",
    "int get schemaVersion => 10;",
    content
)

# 2. Update onCreate triggers for pages
content = re.sub(
    r"CREATE TRIGGER pages_ai AFTER INSERT ON pages BEGIN.*?END;",
    "CREATE TRIGGER pages_ai AFTER INSERT ON pages WHEN new.deleted = 0 BEGIN\n            INSERT INTO search_fts(rowid, entityId, pageId, entityType, content) \n            VALUES (new.rowid, new.id, new.id, 'page', new.title);\n          END;",
    content,
    flags=re.DOTALL
)

content = re.sub(
    r"CREATE TRIGGER pages_au AFTER UPDATE ON pages BEGIN.*?END;",
    "CREATE TRIGGER pages_au AFTER UPDATE ON pages BEGIN\n            DELETE FROM search_fts WHERE entityId = old.id AND entityType = 'page';\n            INSERT INTO search_fts(rowid, entityId, pageId, entityType, content) \n            SELECT new.rowid, new.id, new.id, 'page', new.title WHERE new.deleted = 0;\n          END;",
    content,
    flags=re.DOTALL
)

# 3. Update onCreate triggers for blocks
content = re.sub(
    r"CREATE TRIGGER blocks_ai AFTER INSERT ON blocks BEGIN.*?END;",
    "CREATE TRIGGER blocks_ai AFTER INSERT ON blocks WHEN new.deleted = 0 BEGIN\n            INSERT INTO search_fts(rowid, entityId, pageId, entityType, content) \n            VALUES (new.rowid, new.id, new.page_id, 'block', new.data);\n          END;",
    content,
    flags=re.DOTALL
)

content = re.sub(
    r"CREATE TRIGGER blocks_au AFTER UPDATE ON blocks BEGIN.*?END;",
    "CREATE TRIGGER blocks_au AFTER UPDATE ON blocks BEGIN\n            DELETE FROM search_fts WHERE entityId = old.id AND entityType = 'block';\n            INSERT INTO search_fts(rowid, entityId, pageId, entityType, content) \n            SELECT new.rowid, new.id, new.page_id, 'block', new.data WHERE new.deleted = 0;\n          END;",
    content,
    flags=re.DOTALL
)

# 4. Remove Tags triggers from onCreate
content = re.sub(r"// Tags Triggers.*?END;\s*'\);\s*", "", content, flags=re.DOTALL, count=1) # only onCreate

# 5. Fix from < 9
content = re.sub(
    r"if \(from < 9\) \{\s*await m\.deleteTable\('sync_states'\);\s*await m\.createTable\(syncStates\);\s*await m\.deleteTable\('sync_queue'\);\s*await m\.createTable\(syncQueue\);\s*\}",
    "if (from < 9) {\n          // sync_queue and sync_states were accidentally dropped in previous versions.\n          // We don't drop them to avoid data loss.\n          // Ensure they are created if they somehow don't exist.\n          await m.createTable(syncStates);\n          await m.createTable(syncQueue);\n        }",
    content
)

# 6. Add from < 10
v10_migration = """if (from < 10) {
          // Drop old triggers that didn't handle soft deletion
          await customStatement('DROP TRIGGER IF EXISTS pages_ai');
          await customStatement('DROP TRIGGER IF EXISTS pages_ad');
          await customStatement('DROP TRIGGER IF EXISTS pages_au');
          await customStatement('DROP TRIGGER IF EXISTS blocks_ai');
          await customStatement('DROP TRIGGER IF EXISTS blocks_ad');
          await customStatement('DROP TRIGGER IF EXISTS blocks_au');
          await customStatement('DROP TRIGGER IF EXISTS tags_ai');
          await customStatement('DROP TRIGGER IF EXISTS tags_ad');
          await customStatement('DROP TRIGGER IF EXISTS tags_au');

          // Recreate Pages Triggers with soft delete handling
          await customStatement('''
            CREATE TRIGGER pages_ai AFTER INSERT ON pages WHEN new.deleted = 0 BEGIN
              INSERT INTO search_fts(rowid, entityId, pageId, entityType, content) 
              VALUES (new.rowid, new.id, new.id, 'page', new.title);
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER pages_ad AFTER DELETE ON pages BEGIN
              DELETE FROM search_fts WHERE entityId = old.id AND entityType = 'page';
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER pages_au AFTER UPDATE ON pages BEGIN
              DELETE FROM search_fts WHERE entityId = old.id AND entityType = 'page';
              INSERT INTO search_fts(rowid, entityId, pageId, entityType, content) 
              SELECT new.rowid, new.id, new.id, 'page', new.title WHERE new.deleted = 0;
            END;
          ''');

          // Recreate Blocks Triggers with soft delete handling
          await customStatement('''
            CREATE TRIGGER blocks_ai AFTER INSERT ON blocks WHEN new.deleted = 0 BEGIN
              INSERT INTO search_fts(rowid, entityId, pageId, entityType, content) 
              VALUES (new.rowid, new.id, new.page_id, 'block', new.data);
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER blocks_ad AFTER DELETE ON blocks BEGIN
              DELETE FROM search_fts WHERE entityId = old.id AND entityType = 'block';
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER blocks_au AFTER UPDATE ON blocks BEGIN
              DELETE FROM search_fts WHERE entityId = old.id AND entityType = 'block';
              INSERT INTO search_fts(rowid, entityId, pageId, entityType, content) 
              SELECT new.rowid, new.id, new.page_id, 'block', new.data WHERE new.deleted = 0;
            END;
          ''');

          // Note: Tag triggers are explicitly NOT recreated based on FTS policies

          // Clear out the search_fts index and rebuild it fully clean
          await customStatement('DELETE FROM search_fts');
          
          await customStatement('''
            INSERT INTO search_fts(rowid, entityId, pageId, entityType, content)
            SELECT rowid, id, id, 'page', title FROM pages WHERE deleted = 0;
          ''');

          await customStatement('''
            INSERT INTO search_fts(rowid, entityId, pageId, entityType, content)
            SELECT rowid, id, page_id, 'block', data FROM blocks WHERE deleted = 0;
          ''');
        }"""

content = content.replace(
    "if (from < 9) {",
    v10_migration + "\n        " + "if (from < 9) {"
)

# 7. Remove tags from rebuildSearchIndex
content = re.sub(
    r"await customStatement\('''\s*INSERT INTO search_fts\(rowid, entityId, pageId, entityType, content\)\s*SELECT rowid, id, NULL, 'tag', name FROM tags WHERE deleted = 0;\s*'''\);",
    "",
    content
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Migration script generated and executed on app_database.dart")
