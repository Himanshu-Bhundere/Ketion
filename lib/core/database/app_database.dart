import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables/pages.dart';
import 'tables/blocks.dart';
import 'tables/attachments.dart';
import 'tables/reminders.dart';
import 'tables/collections.dart';
import 'tables/tags.dart';
import 'tables/history_pages.dart';
import 'tables/page_collections.dart';
import 'tables/page_tags.dart';
import 'tables/sync_queue.dart';
import 'tables/sync_state.dart';
import 'tables/app_settings_table.dart';
import 'tables/processed_batches.dart';

import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Pages,
    Blocks,
    Attachments,
    Reminders,
    Collections,
    Tags,
    HistoryPages,
    PageCollections,
    PageTags,
    SyncQueue,
    SyncStates,
    AppSettingsTable,
    ProcessedBatches,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create unified FTS5 table for Pages, Blocks, and Tags
        await customStatement('''
          CREATE VIRTUAL TABLE search_fts USING fts5(
            entityId UNINDEXED,
            pageId UNINDEXED,
            entityType UNINDEXED,
            content
          );
        ''');

        // Pages Triggers
        await customStatement('''
          CREATE TRIGGER pages_ai AFTER INSERT ON pages WHEN new.deleted = 0 BEGIN
            INSERT INTO search_fts(entityId, pageId, entityType, content) 
              VALUES (new.id, new.id, 'page', new.title);
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
            INSERT INTO search_fts(entityId, pageId, entityType, content) 
              SELECT new.id, new.id, 'page', new.title WHERE new.deleted = 0;
          END;
        ''');

        // Blocks Triggers
        await customStatement('''
          CREATE TRIGGER blocks_ai AFTER INSERT ON blocks WHEN new.deleted = 0 BEGIN
            INSERT INTO search_fts(entityId, pageId, entityType, content) 
              VALUES (new.id, new.page_id, 'block', new.data);
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
            INSERT INTO search_fts(entityId, pageId, entityType, content) 
              SELECT new.id, new.page_id, 'block', new.data WHERE new.deleted = 0;
          END;
        ''');

        // Tags Triggers
        await customStatement('''
          CREATE TRIGGER tags_ai AFTER INSERT ON tags BEGIN
            INSERT INTO search_fts(entityId, pageId, entityType, content) 
              VALUES (new.id, NULL, 'tag', new.name);
          END;
        ''');

        await customStatement('''
          CREATE TRIGGER tags_ad AFTER DELETE ON tags BEGIN
            DELETE FROM search_fts WHERE entityId = old.id AND entityType = 'tag';
          END;
        ''');

        await customStatement('''
          CREATE TRIGGER tags_au AFTER UPDATE ON tags BEGIN
            UPDATE search_fts 
            SET content = new.name 
            WHERE entityId = old.id AND entityType = 'tag';
          END;
        ''');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await customStatement(
            'ALTER TABLE attachments RENAME TO attachments_v1',
          );
          await m.createTable(attachments);
          await customStatement('''
            INSERT INTO attachments (id, mime_type, file_size)
            SELECT id, '', 0 FROM attachments_v1
          ''');
          await customStatement('DROP TABLE IF EXISTS attachments_v1');
        }
        if (from < 3) {
          await m.createTable(syncQueue);
          await m.createTable(syncStates);
        }
        if (from < 4) {
          await m.addColumn(tags, tags.createdAt);
          await m.addColumn(tags, tags.updatedAt);
          await m.addColumn(tags, tags.deleted);

          await m.addColumn(collections, collections.createdAt);
          await m.addColumn(collections, collections.updatedAt);
          await m.addColumn(collections, collections.deleted);

          await m.addColumn(reminders, reminders.title);
          await m.addColumn(reminders, reminders.timezone);
          await m.addColumn(reminders, reminders.snoozeUntil);
          await m.addColumn(reminders, reminders.createdAt);
          await m.addColumn(reminders, reminders.updatedAt);
          await m.addColumn(reminders, reminders.deleted);
        }
        if (from < 5) {
          await customStatement(
            'ALTER TABLE attachments RENAME TO attachments_v4',
          );
          await m.createTable(attachments);
          await customStatement('''
            INSERT INTO attachments (id, mime_type, file_size)
            SELECT id, mime_type, file_size FROM attachments_v4
          ''');
          await customStatement('DROP TABLE IF EXISTS attachments_v4');
        }
        if (from < 6) {
          // Drop old search structure
          await customStatement('DROP TABLE IF EXISTS blocks_fts');
          await customStatement('DROP TRIGGER IF EXISTS blocks_ai');
          await customStatement('DROP TRIGGER IF EXISTS blocks_ad');
          await customStatement('DROP TRIGGER IF EXISTS blocks_au');

          // Create new search_fts table and triggers
          await customStatement('''
            CREATE VIRTUAL TABLE search_fts USING fts5(
              entityId UNINDEXED,
              pageId UNINDEXED,
              entityType UNINDEXED,
              content
            );
          ''');

          // Pages Triggers
          await customStatement('''
            CREATE TRIGGER pages_ai AFTER INSERT ON pages WHEN new.deleted = 0 BEGIN
            INSERT INTO search_fts(entityId, pageId, entityType, content) 
              VALUES (new.id, new.id, 'page', new.title);
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
            INSERT INTO search_fts(entityId, pageId, entityType, content) 
              SELECT new.id, new.id, 'page', new.title WHERE new.deleted = 0;
          END;
          ''');

          // Blocks Triggers
          await customStatement('''
            CREATE TRIGGER blocks_ai AFTER INSERT ON blocks WHEN new.deleted = 0 BEGIN
            INSERT INTO search_fts(entityId, pageId, entityType, content) 
              VALUES (new.id, new.page_id, 'block', new.data);
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
            INSERT INTO search_fts(entityId, pageId, entityType, content) 
              SELECT new.id, new.page_id, 'block', new.data WHERE new.deleted = 0;
          END;
          ''');

          // Tags Triggers
          await customStatement('''
            CREATE TRIGGER tags_ai AFTER INSERT ON tags BEGIN
              INSERT INTO search_fts(entityId, pageId, entityType, content) 
              VALUES (new.id, NULL, 'tag', new.name);
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER tags_ad AFTER DELETE ON tags BEGIN
              DELETE FROM search_fts WHERE entityId = old.id AND entityType = 'tag';
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER tags_au AFTER UPDATE ON tags BEGIN
              UPDATE search_fts 
              SET content = new.name 
              WHERE entityId = old.id AND entityType = 'tag';
            END;
          ''');

          // Rebuild index for existing data
          await customStatement('''
            INSERT INTO search_fts(entityId, pageId, entityType, content)
            SELECT id, id, 'page', title FROM pages;
          ''');
          await customStatement('''
            INSERT INTO search_fts(entityId, pageId, entityType, content)
            SELECT id, page_id, 'block', data FROM blocks;
          ''');
          await customStatement('''
            INSERT INTO search_fts(entityId, pageId, entityType, content)
            SELECT id, NULL, 'tag', name FROM tags;
          ''');
        } // Close if (from < 6)

        if (from < 7) {
          await m.addColumn(pages, pages.isTemplate);
        }
        if (from < 8) {
          await m.createTable(appSettingsTable);
        }
        if (from < 10) {
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
              INSERT INTO search_fts(entityId, pageId, entityType, content) 
              VALUES (new.id, new.id, 'page', new.title);
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
              INSERT INTO search_fts(entityId, pageId, entityType, content) 
              SELECT new.id, new.id, 'page', new.title WHERE new.deleted = 0;
            END;
          ''');

          // Recreate Blocks Triggers with soft delete handling
          await customStatement('''
            CREATE TRIGGER blocks_ai AFTER INSERT ON blocks WHEN new.deleted = 0 BEGIN
              INSERT INTO search_fts(entityId, pageId, entityType, content) 
              VALUES (new.id, new.page_id, 'block', new.data);
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
              INSERT INTO search_fts(entityId, pageId, entityType, content) 
              SELECT new.id, new.page_id, 'block', new.data WHERE new.deleted = 0;
            END;
          ''');

          // Note: Tag triggers are explicitly NOT recreated based on FTS policies

          // Clear out the search_fts index and rebuild it fully clean
          await customStatement('DELETE FROM search_fts');

          await customStatement('''
            INSERT INTO search_fts(entityId, pageId, entityType, content)
            SELECT id, id, 'page', title FROM pages WHERE deleted = 0;
          ''');

          await customStatement('''
            INSERT INTO search_fts(entityId, pageId, entityType, content)
            SELECT id, page_id, 'block', data FROM blocks WHERE deleted = 0;
          ''');
        }
        if (from < 9) {
          // In previous versions, sync_queue and sync_states were added in v3 but
          // might have been missed in some environments. Deterministically verify existence:
          final queueExists = await customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_queue';",
          ).get();
          if (queueExists.isEmpty) {
            await m.createTable(syncQueue);
          }
          final statesExists = await customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_states';",
          ).get();
          if (statesExists.isEmpty) {
            await m.createTable(syncStates);
          }
        }
        if (from < 11) {
          // Phase 2: Schema changed significantly for attachments.
          // Create new table, copy data, drop old table to be safe
          await customStatement(
            'ALTER TABLE attachments RENAME TO attachments_old',
          );
          await m.createTable(attachments);

          // Copy existing data. We explicitly list columns that existed in v10 and map them to v11.
          await customStatement('''
            INSERT INTO attachments (id, block_id, file_size, mime_type, local_path, created_at, updated_at, deleted)
            SELECT id, 'migrated_from_v10', file_size, mime_type, local_path, created_at, updated_at, deleted
            FROM attachments_old
          ''');

          await customStatement('DROP TABLE IF EXISTS attachments_old');
        }
        if (from < 12) {
          // Add processed_batches table
          await m.createTable(processedBatches);

          // Add leaseUntil column to syncQueue
          await m.addColumn(syncQueue, syncQueue.leaseUntil);
        }
        if (from < 13) {
          // Add batchId, version, updatedAt to syncQueue for Phase A
          await m.addColumn(syncQueue, syncQueue.batchId);
          await m.addColumn(syncQueue, syncQueue.version);
          await m.addColumn(syncQueue, syncQueue.updatedAt);
        }
      },
      beforeOpen: (details) async {
        // Enforce foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Rebuilds the FTS5 search index from scratch.
  /// Useful for migrations, database recovery, and imports.
  Future<void> rebuildSearchIndex() async {
    await customStatement('DELETE FROM search_fts');

    await customStatement('''
      INSERT INTO search_fts(entityId, pageId, entityType, content)
            SELECT id, id, 'page', title FROM pages WHERE deleted = 0;
    ''');

    await customStatement('''
      INSERT INTO search_fts(entityId, pageId, entityType, content)
            SELECT id, page_id, 'block', data FROM blocks WHERE deleted = 0;
    ''');
  }

  /// Purge tombstones (deleted records) older than the specified retention period.
  Future<void> cleanupTombstones({int retentionDays = 30}) async {
    // Disabled (Phase A.5: Tombstone Safety)
    // Synchronizable entity tombstones are retained indefinitely unless a future
    // synchronization protocol introduces a safe global acknowledgement/watermark mechanism.
    return;
  }
}

/// Provides a global instance of AppDatabase.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
