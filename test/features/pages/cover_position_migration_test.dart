import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ketion/core/database/app_database.dart';

void main() {
  group('Cover position database migration (v21 to v22)', () {
    test(
        'upgrades pages table and assigns default offset 0.5 to existing pages',
        () async {
      final sqliteDb = sqlite3.openInMemory();

      // Setup v21 schema for pages and required dependencies
      sqliteDb.execute('''
        CREATE TABLE pages (
          id TEXT NOT NULL PRIMARY KEY,
          parent_page_id TEXT,
          title TEXT NOT NULL DEFAULT '',
          icon TEXT,
          cover_image TEXT,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0,
          deleted INTEGER NOT NULL DEFAULT 0,
          deleted_at INTEGER,
          is_template INTEGER NOT NULL DEFAULT 0,
          version INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
        CREATE TABLE blocks (id TEXT NOT NULL PRIMARY KEY, page_id TEXT NOT NULL, parent_block_id TEXT, data TEXT NOT NULL, type TEXT NOT NULL, position REAL NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0, version INTEGER NOT NULL DEFAULT 1);
        CREATE TABLE tags (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);
        CREATE TABLE collections (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);
        CREATE TABLE reminders (id TEXT NOT NULL PRIMARY KEY, title TEXT, timezone TEXT, snooze_until INTEGER, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);
        CREATE TABLE history_pages (id TEXT NOT NULL PRIMARY KEY);
        CREATE TABLE page_collections (page_id TEXT NOT NULL, collection_id TEXT NOT NULL, PRIMARY KEY(page_id, collection_id));
        CREATE TABLE page_tags (page_id TEXT NOT NULL, tag_id TEXT NOT NULL, PRIMARY KEY(page_id, tag_id));
        CREATE TABLE sync_queue (id TEXT NOT NULL PRIMARY KEY, entity_table TEXT NOT NULL, entity_id TEXT NOT NULL, operation TEXT NOT NULL, payload TEXT, created_at INTEGER NOT NULL, status TEXT NOT NULL, attempt_count INTEGER NOT NULL, last_attempt_at INTEGER, next_retry_at INTEGER, last_error TEXT);
        CREATE TABLE sync_states (device_id TEXT NOT NULL, provider TEXT NOT NULL, last_sync_time INTEGER, last_drive_cursor TEXT, PRIMARY KEY(device_id, provider));
        CREATE TABLE app_settings_table (id TEXT NOT NULL PRIMARY KEY, theme_mode TEXT NOT NULL DEFAULT 'System', sync_frequency TEXT NOT NULL DEFAULT '15 minutes', auto_sync INTEGER NOT NULL DEFAULT 1, cache_limit_m_b INTEGER NOT NULL DEFAULT 100, tombstone_retention_days INTEGER NOT NULL DEFAULT 30, last_cleanup INTEGER, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);
        CREATE TABLE attachments (id TEXT NOT NULL PRIMARY KEY, file_name TEXT NOT NULL, file_size INTEGER NOT NULL, mime_type TEXT NOT NULL, remote_url TEXT, local_path TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);
        CREATE TABLE processed_batches (id TEXT NOT NULL PRIMARY KEY, batch_id TEXT NOT NULL, processed_at INTEGER NOT NULL);
        CREATE VIRTUAL TABLE search_fts USING fts5(
          entityId UNINDEXED,
          pageId UNINDEXED,
          entityType UNINDEXED,
          content
        );
        PRAGMA user_version = 21;
      ''');

      // Insert pre-migration page record
      sqliteDb.execute('''
        INSERT INTO pages (id, title, cover_image, created_at, updated_at)
        VALUES ('page-v21', 'Note Title', 'cover-att-1', 1700000000, 1700000000);
      ''');

      // Initialize Drift database to trigger onUpgrade
      final db = AppDatabase.forTesting(NativeDatabase.opened(sqliteDb));
      await db.customSelect('SELECT 1').get();

      // 1. Verify schema upgrade occurred
      expect(db.schemaVersion, 22);

      // 2. Verify column exists and default value is 0.5
      final rows = await db.customSelect(
        'SELECT id, cover_image_vertical_offset FROM pages WHERE id = ?',
        variables: [Variable.withString('page-v21')],
      ).get();

      expect(rows.length, 1);
      final offset = rows.first.read<double>('cover_image_vertical_offset');
      expect(offset, 0.5);

      // 3. Verify valid offset updates persist correctly
      await db.customUpdate(
        'UPDATE pages SET cover_image_vertical_offset = ? WHERE id = ?',
        variables: [Variable.withReal(0.75), Variable.withString('page-v21')],
      );
      final updatedRows = await db.customSelect(
        'SELECT cover_image_vertical_offset FROM pages WHERE id = ?',
        variables: [Variable.withString('page-v21')],
      ).get();
      expect(
          updatedRows.first.read<double>('cover_image_vertical_offset'), 0.75,);

      // 4. Verify boundary values 0.0 and 1.0 succeed
      await db.customUpdate(
        'UPDATE pages SET cover_image_vertical_offset = ? WHERE id = ?',
        variables: [Variable.withReal(0.0), Variable.withString('page-v21')],
      );
      expect(
        (await db.customSelect(
                'SELECT cover_image_vertical_offset FROM pages WHERE id = ?',
                variables: [Variable.withString('page-v21')],).get())
            .first
            .read<double>('cover_image_vertical_offset'),
        0.0,
      );

      await db.customUpdate(
        'UPDATE pages SET cover_image_vertical_offset = ? WHERE id = ?',
        variables: [Variable.withReal(1.0), Variable.withString('page-v21')],
      );
      expect(
        (await db.customSelect(
                'SELECT cover_image_vertical_offset FROM pages WHERE id = ?',
                variables: [Variable.withString('page-v21')],).get())
            .first
            .read<double>('cover_image_vertical_offset'),
        1.0,
      );

      // 5. Verify CHECK constraint rejects values < 0.0 or > 1.0
      expect(
        () async => await db.customUpdate(
          'UPDATE pages SET cover_image_vertical_offset = ? WHERE id = ?',
          variables: [Variable.withReal(1.2), Variable.withString('page-v21')],
        ),
        throwsA(isA<SqliteException>()),
      );

      expect(
        () async => await db.customUpdate(
          'UPDATE pages SET cover_image_vertical_offset = ? WHERE id = ?',
          variables: [
            Variable.withReal(-0.01),
            Variable.withString('page-v21'),
          ],
        ),
        throwsA(isA<SqliteException>()),
      );

      await db.close();
    });

    test('fresh database creation includes cover_image_vertical_offset column',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db.schemaVersion, 22);

      await db.customSelect('SELECT 1').get();
      final tableInfo =
          await db.customSelect("PRAGMA table_info('pages')").get();
      final hasColumn = tableInfo.any(
        (row) => row.read<String>('name') == 'cover_image_vertical_offset',
      );
      expect(hasColumn, isTrue);

      await db.close();
    });
  });
}
