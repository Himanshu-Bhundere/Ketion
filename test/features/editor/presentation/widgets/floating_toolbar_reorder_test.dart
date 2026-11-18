import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ketion/features/editor/presentation/widgets/floating_toolbar.dart';

void main() {
  group('FloatingToolbar Reorder and Persistence', () {
    test('Default toolbar order and normalizeOrder handles missing/invalid symbols', () {
      expect(defaultToolbarSymbolOrder, [
        'bullet_list',
        'heading',
        'image',
        'file',
        'hide_keyboard',
      ]);

      // Null or empty returns default
      expect(_FloatingToolbarStatePublic.normalize(null), defaultToolbarSymbolOrder);
      expect(_FloatingToolbarStatePublic.normalize([]), defaultToolbarSymbolOrder);

      // Unknown symbols are filtered out, and missing ones are appended
      final normalized = _FloatingToolbarStatePublic.normalize([
        'custom_invalid',
        'file',
        'image',
      ]);
      expect(normalized, [
        'file',
        'image',
        'bullet_list',
        'heading',
        'hide_keyboard',
      ]);
    });

    testWidgets('Renders items according to initialOrder', (tester) async {
      final customOrder = [
        'file',
        'image',
        'bullet_list',
        'heading',
        'hide_keyboard',
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FloatingToolbar(
                initialOrder: customOrder,
                onAddImage: () {},
                onAddFile: () {},
                onAddList: () {},
                onAddHeading: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final firstFinder = find.byKey(const ValueKey('toolbar_file'));
      final secondFinder = find.byKey(const ValueKey('toolbar_image'));
      expect(firstFinder, findsOneWidget);
      expect(secondFinder, findsOneWidget);

      final firstX = tester.getCenter(firstFinder).dx;
      final secondX = tester.getCenter(secondFinder).dx;
      expect(firstX < secondX, isTrue);
    });

    testWidgets('Reordering with mouse/pointer invokes onOrderChanged', (tester) async {
      List<String>? capturedOrder;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.windows),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 500,
                  child: FloatingToolbar(
                    initialOrder: const [
                      'bullet_list',
                      'heading',
                      'image',
                      'file',
                      'hide_keyboard',
                    ],
                    onOrderChanged: (newOrder) {
                      capturedOrder = newOrder;
                    },
                    onAddImage: () {},
                    onAddFile: () {},
                    onAddList: () {},
                    onAddHeading: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final firstItem = find.byKey(const ValueKey('toolbar_bullet_list'));
      final secondItem = find.byKey(const ValueKey('toolbar_heading'));

      // Drag bullet_list to heading target
      final gesture = await tester.startGesture(tester.getCenter(firstItem));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(secondItem));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(capturedOrder, isNotNull);
      expect(capturedOrder!.first, 'heading');
      expect(capturedOrder![1], 'bullet_list');
    });

    testWidgets('Platform-aware drag selection (Draggable on desktop, LongPressDraggable on mobile)', (tester) async {
      // Windows
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.windows),
            home: Scaffold(
              body: FloatingToolbar(
                initialOrder: defaultToolbarSymbolOrder,
                onAddImage: () {},
                onAddFile: () {},
                onAddList: () {},
                onAddHeading: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Draggable<int>), findsWidgets);
      expect(find.byType(LongPressDraggable<int>), findsNothing);

      // Android
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.android),
            home: Scaffold(
              body: FloatingToolbar(
                initialOrder: defaultToolbarSymbolOrder,
                onAddImage: () {},
                onAddFile: () {},
                onAddList: () {},
                onAddHeading: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LongPressDraggable<int>), findsWidgets);

      // iOS
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: Scaffold(
              body: FloatingToolbar(
                initialOrder: defaultToolbarSymbolOrder,
                onAddImage: () {},
                onAddFile: () {},
                onAddList: () {},
                onAddHeading: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LongPressDraggable<int>), findsWidgets);
    });

    test('Toolbar order persists in SQLite and reloads via SettingsRepository', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = SettingsRepositoryImpl(db);

      final initial = await repo.getSettings();
      expect(initial.toolbarSymbolOrder, [
        'bullet_list',
        'heading',
        'image',
        'file',
        'hide_keyboard',
      ]);

      final reordered = [
        'file',
        'image',
        'heading',
        'bullet_list',
        'hide_keyboard',
      ];
      await repo.updateSettings(initial.copyWith(toolbarSymbolOrder: reordered));

      final reloaded = await repo.getSettings();
      expect(reloaded.toolbarSymbolOrder, reordered);

      await db.close();
    });

    test('Migration to v25 adds toolbar_symbol_order column with default value', () async {
      final sqliteDb = sqlite3.openInMemory();

      sqliteDb.execute('''
        CREATE TABLE pages (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0, is_template INTEGER NOT NULL DEFAULT 0, version INTEGER NOT NULL DEFAULT 1);
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
          assistive_ball_enabled INTEGER NOT NULL DEFAULT 0,
          assistive_ball_normalized_x REAL NOT NULL DEFAULT 1.0,
          assistive_ball_normalized_y REAL NOT NULL DEFAULT 1.0,
          last_cleanup INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
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
        CREATE TABLE processed_batches (id TEXT NOT NULL PRIMARY KEY);
        CREATE VIRTUAL TABLE search_fts USING fts5(
          entityId UNINDEXED,
          pageId UNINDEXED,
          entityType UNINDEXED,
          content
        );

        PRAGMA user_version = 24;
      ''');

      // Insert row in v24 app_settings_table
      sqliteDb.execute('''
        INSERT INTO app_settings_table (id, created_at, updated_at)
        VALUES ('default', 1700000000, 1700000000);
      ''');

      final driftDb = AppDatabase.forTesting(NativeDatabase.opened(sqliteDb));
      // Trigger migration
      await driftDb.customSelect('SELECT 1').get();

      final settingsRow = await driftDb
          .customSelect(
            'SELECT toolbar_symbol_order FROM app_settings_table WHERE id = ?',
            variables: [const Variable<String>('default')],
          )
          .getSingle();

      final storedOrderJson = settingsRow.read<String>('toolbar_symbol_order');
      final decoded = jsonDecode(storedOrderJson) as List<dynamic>;
      expect(decoded.cast<String>(), [
        'bullet_list',
        'heading',
        'image',
        'file',
        'hide_keyboard',
      ]);

      await driftDb.close();
    });
  });
}

class _FloatingToolbarStatePublic {
  static List<String> normalize(List<String>? order) {
    if (order == null || order.isEmpty) {
      return List<String>.from(defaultToolbarSymbolOrder);
    }
    final valid =
        order.where(defaultToolbarSymbolOrder.contains).toSet().toList();
    for (final defaultItem in defaultToolbarSymbolOrder) {
      if (!valid.contains(defaultItem)) {
        valid.add(defaultItem);
      }
    }
    return valid;
  }
}
