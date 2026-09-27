import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';

import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/pages/data/repositories/page_repository_impl.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/features/sync/presentation/providers/sync_providers.dart';
import 'package:ketion/features/pages/presentation/pages/notes_page.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/core/utils/logger.dart';

void main() {
  late AppDatabase database;
  late PageRepositoryImpl pageRepo;
  late SyncQueueRepositoryImpl syncQueue;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    syncQueue = SyncQueueRepositoryImpl(database);
    final logger = AppLogger();
    pageRepo = PageRepositoryImpl(database, syncQueue, logger);
  });

  tearDown(() {
    database.close();
  });

  Future<void> pumpNotesPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          syncQueueRepositoryProvider.overrideWithValue(syncQueue),
          pageRepositoryProvider.overrideWithValue(pageRepo),
        ],
        child: const MaterialApp(
          home: NotesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Page UX Stabilization', () {
    testWidgets('Empty page behavior', (tester) async {
      await pumpNotesPage(tester);

      expect(find.text('No notes yet'), findsOneWidget);
      expect(find.text('New Note'), findsOneWidget);
    });
  });
}
