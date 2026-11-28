import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:go_router/go_router.dart';

import 'package:ketion/core/database/app_database.dart' hide Page;
import 'package:ketion/core/router/routes.dart';
import 'package:ketion/features/pages/data/repositories/page_repository_impl.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';
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

    testWidgets(
      'Desktop width tap opens editor route instead of only setting state',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final now = DateTime.now().toUtc();
        await pageRepo.createPage(
          Page(
            id: 'win-note-1',
            title: 'Windows Click Note',
            createdAt: now,
            updatedAt: now,
          ),
        );

        final router = GoRouter(
          initialLocation: Routes.notes,
          routes: [
            GoRoute(
              path: Routes.notes,
              builder: (context, state) => const NotesPage(),
            ),
            GoRoute(
              name: Routes.editorName,
              path: Routes.editor,
              builder: (context, state) => Scaffold(
                body: Text('Editor: ${state.pathParameters['pageId']}'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(database),
              syncQueueRepositoryProvider.overrideWithValue(syncQueue),
              pageRepositoryProvider.overrideWithValue(pageRepo),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Windows Click Note'), findsOneWidget);
        await tester.tap(find.text('Windows Click Note'));
        await tester.pumpAndSettle();

        expect(find.text('Editor: win-note-1'), findsOneWidget);
      },
    );
  });
}
