import re
import sys

file_path = "c:/Projects/Ketion/lib/core/database/app_database.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Fix the INSERTs to remove rowid
content = re.sub(
    r"INSERT INTO search_fts\(rowid, entityId, pageId, entityType, content\)\s*VALUES \(new\.rowid, (.*?)\)",
    r"INSERT INTO search_fts(entityId, pageId, entityType, content) \n              VALUES (\1)",
    content
)

content = re.sub(
    r"INSERT INTO search_fts\(rowid, entityId, pageId, entityType, content\)\s*SELECT new\.rowid, (.*?) WHERE",
    r"INSERT INTO search_fts(entityId, pageId, entityType, content) \n              SELECT \1 WHERE",
    content
)

content = re.sub(
    r"INSERT INTO search_fts\(rowid, entityId, pageId, entityType, content\)\s*SELECT rowid, (.*?) FROM",
    r"INSERT INTO search_fts(entityId, pageId, entityType, content)\n            SELECT \1 FROM",
    content
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Migration script generated and executed on app_database.dart")
