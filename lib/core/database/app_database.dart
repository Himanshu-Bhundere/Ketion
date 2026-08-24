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

import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

@DriftDatabase(tables: [
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
],)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Create FTS5 external content table for blocks
        await customStatement('''
          CREATE VIRTUAL TABLE blocks_fts USING fts5(
            id UNINDEXED,
            pageId UNINDEXED,
            type UNINDEXED,
            data,
            content='blocks',
            content_rowid='rowid'
          );
        ''');

        // Triggers to keep FTS index synced with the blocks table
        await customStatement('''
          CREATE TRIGGER blocks_ai AFTER INSERT ON blocks BEGIN
            INSERT INTO blocks_fts(rowid, id, pageId, type, data) 
            VALUES (new.rowid, new.id, new.page_id, new.type, new.data);
          END;
        ''');
        
        await customStatement('''
          CREATE TRIGGER blocks_ad AFTER DELETE ON blocks BEGIN
            INSERT INTO blocks_fts(blocks_fts, rowid, id, pageId, type, data) 
            VALUES ('delete', old.rowid, old.id, old.page_id, old.type, old.data);
          END;
        ''');
        
        await customStatement('''
          CREATE TRIGGER blocks_au AFTER UPDATE ON blocks BEGIN
            INSERT INTO blocks_fts(blocks_fts, rowid, id, pageId, type, data) 
            VALUES ('delete', old.rowid, old.id, old.page_id, old.type, old.data);
            
            INSERT INTO blocks_fts(rowid, id, pageId, type, data) 
            VALUES (new.rowid, new.id, new.page_id, new.type, new.data);
          END;
        ''');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // In a real app we'd alter table. For early dev we can just drop and recreate it 
          // (or use m.alterTable if possible). To be safe, we'll recreate attachments since it wasn't populated yet.
          await m.deleteTable(attachments.actualTableName);
          await m.createTable(attachments);
        }
        if (from < 3) {
          await m.createTable(syncQueue);
          await m.createTable(syncStates);
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
    await customStatement("INSERT INTO blocks_fts(blocks_fts) VALUES('rebuild')");
  }
}

/// Provides a global instance of AppDatabase.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
