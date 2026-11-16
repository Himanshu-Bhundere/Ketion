import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/settings/data/repositories/settings_repository_impl.dart';

void main() {
  group('Assistive ball settings database migration (v22 to v23)', () {
    test(
        'upgrades app_settings_table and assigns default assistive_ball_enabled 0 to existing settings',
        () async {
      final sqliteDb = sqlite3.openInMemory();

      // Setup v22 schema
      sqliteDb.execute('''
        CREATE TABLE pages (
          id TEXT NOT NULL PRIMARY KEY,
          parent_page_id TEXT,
          title TEXT NOT NULL DEFAULT '',
          icon TEXT,
          cover_image TEXT,
          cover_image_vertical_offset REAL DEFAULT 0.5,
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
        CREATE TABLE app_settings_table (
          id TEXT NOT NULL PRIMARY KEY,
          theme_mode TEXT NOT NULL DEFAULT 'System',
          sync_frequency TEXT NOT NULL DEFAULT '15 minutes',
          auto_sync INTEGER NOT NULL DEFAULT 1,
          cache_limit_m_b INTEGER NOT NULL DEFAULT 100,
          tombstone_retention_days INTEGER NOT NULL DEFAULT 30,
          accent_color TEXT NOT NULL DEFAULT 'blue',
          font_size TEXT NOT NULL DEFAULT 'medium',
          editor_appearance TEXT NOT NULL DEFAULT 'comfortable',
          high_contrast INTEGER NOT NULL DEFAULT 0,
          reduced_motion INTEGER NOT NULL DEFAULT 0,
          last_cleanup INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
        CREATE TABLE attachments (id TEXT NOT NULL PRIMARY KEY, file_name TEXT NOT NULL, file_size INTEGER NOT NULL, mime_type TEXT NOT NULL, remote_url TEXT, local_path TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0);
        CREATE TABLE processed_batches (id TEXT NOT NULL PRIMARY KEY, batch_id TEXT NOT NULL, processed_at INTEGER NOT NULL);
        CREATE VIRTUAL TABLE search_fts USING fts5(
          entityId UNINDEXED,
          pageId UNINDEXED,
          entityType UNINDEXED,
          content
        );
        PRAGMA user_version = 22;
      ''');

      // Insert pre-migration settings record
      sqliteDb.execute('''
        INSERT INTO app_settings_table (
          id, theme_mode, sync_frequency, auto_sync, cache_limit_m_b,
          accent_color, font_size, editor_appearance, high_contrast,
          reduced_motion, created_at, updated_at
        ) VALUES (
          'default', 'System', '15 minutes', 1, 100,
          'blue', 'medium', 'comfortable', 0,
          0, 1700000000, 1700000000
        );
      ''');

      // Initialize Drift database to trigger onUpgrade
      final db = AppDatabase.forTesting(NativeDatabase.opened(sqliteDb));
      await db.customSelect('SELECT 1').get();

      // 1. Verify schema upgrade occurred to 24
      expect(db.schemaVersion, 24);

      // 2. Verify column exists and default is false (0)
      final rows = await db.customSelect(
        'SELECT id, assistive_ball_enabled, assistive_ball_normalized_x, assistive_ball_normalized_y FROM app_settings_table WHERE id = ?',
        variables: [Variable.withString('default')],
      ).get();

      expect(rows.length, 1);
      final enabled = rows.first.read<bool>('assistive_ball_enabled');
      expect(enabled, isFalse);
      final normX = rows.first.read<double>('assistive_ball_normalized_x');
      final normY = rows.first.read<double>('assistive_ball_normalized_y');
      expect(normX, 1.0);
      expect(normY, 1.0);

      // 3. Verify repository read and update operations
      final repository = SettingsRepositoryImpl(db);
      var settings = await repository.getSettings();
      expect(settings.assistiveBallEnabled, isFalse);

      await repository.updateSettings(settings.copyWith(assistiveBallEnabled: true));

      settings = await repository.getSettings();
      expect(settings.assistiveBallEnabled, isTrue);

      await db.close();
    });
  });
}
