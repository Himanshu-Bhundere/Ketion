import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ketion/core/database/app_database.dart';

void main() {
  test('Database upgrades from v10 to v12 and preserves attachments', () async {
    // 1. Create a raw sqlite3 memory database and manually setup v10 schema
    final sqliteDb = sqlite3.openInMemory();
    
    sqliteDb.execute('''
      CREATE TABLE pages (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0, is_template INTEGER NOT NULL DEFAULT 0, version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE blocks (id TEXT NOT NULL PRIMARY KEY, page_id TEXT NOT NULL, data TEXT NOT NULL, block_type TEXT NOT NULL, sort_order INTEGER NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0, version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE tags (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE collections (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE reminders (id TEXT NOT NULL PRIMARY KEY, title TEXT, timezone TEXT, snooze_until INTEGER, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE history_pages (id TEXT NOT NULL PRIMARY KEY);
      CREATE TABLE page_collections (page_id TEXT NOT NULL, collection_id TEXT NOT NULL, PRIMARY KEY(page_id, collection_id));
      CREATE TABLE page_tags (page_id TEXT NOT NULL, tag_id TEXT NOT NULL, PRIMARY KEY(page_id, tag_id));
      CREATE TABLE sync_queue (id TEXT NOT NULL PRIMARY KEY, entity_table TEXT NOT NULL, entity_id TEXT NOT NULL, operation TEXT NOT NULL, payload TEXT, created_at INTEGER NOT NULL, status TEXT NOT NULL, attempt_count INTEGER NOT NULL, last_attempt_at INTEGER, next_retry_at INTEGER, last_error TEXT);
      CREATE TABLE sync_states (device_id TEXT NOT NULL, provider TEXT NOT NULL, last_sync_time INTEGER, last_drive_cursor TEXT, PRIMARY KEY(device_id, provider));
      CREATE TABLE app_settings (id INTEGER NOT NULL PRIMARY KEY);
      
      -- The v10 attachments table (before v11 migration)
      CREATE TABLE attachments (
        id TEXT NOT NULL PRIMARY KEY,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        mime_type TEXT NOT NULL,
        remote_url TEXT,
        local_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0
      );
      
      PRAGMA user_version = 10;
    ''');

    // 2. Insert representative dummy data
    sqliteDb.execute('''
      INSERT INTO attachments (id, file_name, file_size, mime_type, remote_url, local_path, created_at, updated_at, deleted)
      VALUES ('uuid-1', 'test.png', 1024, 'image/png', 'https://example.com/test.png', '/local/path/test.png', 1600000000, 1600000000, 0);
    ''');

    // 3. Wrap in Drift database to trigger migration
    final driftDb = AppDatabase.forTesting(NativeDatabase.opened(sqliteDb));
    
    // Trigger migration
    await driftDb.customSelect('SELECT 1').get();
    
    // 4. Verify data survived
    final attachmentsData = await driftDb.customSelect('SELECT * FROM attachments').get();
    expect(attachmentsData.length, 1);
    
    final row = attachmentsData.first;
    expect(row.read<String>('id'), 'uuid-1');
    expect(row.read<String>('block_id'), 'migrated_from_v10');
    expect(row.read<int>('file_size'), 1024);
    expect(row.read<String>('mime_type'), 'image/png');
    
    // 5. Verify v12 schema additions exist
    final processedBatches = await driftDb.customSelect('SELECT * FROM processed_batches').get();
    expect(processedBatches, isEmpty);
    
    final queueItems = await driftDb.customSelect('SELECT * FROM sync_queue WHERE lease_until IS NOT NULL').get();
    expect(queueItems, isEmpty);

    await driftDb.close();
  });
}
