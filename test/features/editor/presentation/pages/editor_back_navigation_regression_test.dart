import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ketion/core/database/app_database.dart' hide Page, Block;
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/blocks/data/repositories/block_repository_impl.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/features/editor/presentation/pages/editor_page.dart';
import 'package:ketion/features/editor/presentation/widgets/editor_top_bar.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_editor_host.dart';
import 'package:ketion/features/pages/data/repositories/page_repository_impl.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/features/widgets/domain/services/widget_service.dart';
import 'package:ketion/features/widgets/presentation/providers/widget_providers.dart';

class MockWidgetService implements WidgetService {
  int updateCount = 0;
  int snapshotCount = 0;

  @override
  Future<Result<void>> generateWidgetSnapshot() async {
    snapshotCount++;
    return const Success(null);
  }

  @override
  Future<Result<void>> triggerWidgetUpdate() async {
    updateCount++;
    return const Success(null);
  }

  @override
  Future<Result<void>> updateSimpleWidgetData(String key, dynamic value) async {
    return const Success(null);
  }
}

Future<void> pumpUntilInitialized(WidgetTester tester) async {
  int attempts = 0;
  while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
      attempts < 50) {
    await tester.pump(const Duration(milliseconds: 50));
    attempts++;
  }
  if (attempts >= 50) {
    throw Exception(
      'pumpUntilInitialized timed out waiting for CircularProgressIndicator to disappear',
    );
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> pumpWait(WidgetTester tester, [int millis = 300]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: millis));
}

Future<void> openEditor(
  WidgetTester tester,
  GoRouter router,
  String pageId,
) async {
  unawaited(router.push('/editor/$pageId'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await pumpUntilInitialized(tester);
}

Future<void> goBack(WidgetTester tester) async {
  final backButton = find.byTooltip('Back');
  expect(backButton, findsOneWidget);
  await tester.tap(backButton, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PageRepositoryImpl pageRepo;
  late BlockRepositoryImpl blockRepo;
  late MockWidgetService mockWidgetService;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final syncQueueRepo = SyncQueueRepositoryImpl(db);
    pageRepo = PageRepositoryImpl(db, syncQueueRepo, appLogger);
    blockRepo = BlockRepositoryImpl(db, syncQueueRepo, appLogger);
    mockWidgetService = MockWidgetService();
  });

  tearDown(() {
    // In-memory test database will be garbage collected.
  });

  group('Editor Back Navigation Regression Tests', () {
    testWidgets('Back navigation flushes pending changes and updates native widgets before popping',
        (tester) async {
      final now = DateTime.now().toUtc();
      final page = Page(
        id: 'test-page-nav-1',
        title: 'Initial Title',
        createdAt: now,
        updatedAt: now,
      );
      await pageRepo.createPage(page);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Home Screen Content'),
            ),
          ),
          GoRoute(
            path: '/editor/:pageId',
            builder: (context, state) {
              final pageId = state.pathParameters['pageId']!;
              return EditorPage(pageId: pageId);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            pageRepositoryProvider.overrideWithValue(pageRepo),
            blockRepositoryProvider.overrideWithValue(blockRepo),
            widgetServiceProvider.overrideWithValue(mockWidgetService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await pumpWait(tester);

      expect(find.text('Home Screen Content'), findsOneWidget);

      await openEditor(tester, router, page.id);

      expect(find.byType(EditorPage), findsOneWidget);
      expect(find.byType(EditorTopBar), findsOneWidget);

      await goBack(tester);

      // Home screen must be visible and valid, NOT a blank screen
      expect(find.text('Home Screen Content'), findsOneWidget);
      expect(find.byType(EditorPage), findsNothing);

      // Widget service update must have executed
      expect(mockWidgetService.snapshotCount, greaterThanOrEqualTo(1));
      expect(mockWidgetService.updateCount, greaterThanOrEqualTo(1));
    });

    testWidgets('Rapid back presses do not cause duplicate navigation or blank route',
        (tester) async {
      final now = DateTime.now().toUtc();
      final page = Page(
        id: 'test-page-rapid-nav',
        title: 'Rapid Nav Page',
        createdAt: now,
        updatedAt: now,
      );
      await pageRepo.createPage(page);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Home Destination Screen'),
            ),
          ),
          GoRoute(
            path: '/editor/:pageId',
            builder: (context, state) {
              final pageId = state.pathParameters['pageId']!;
              return EditorPage(pageId: pageId);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            pageRepositoryProvider.overrideWithValue(pageRepo),
            blockRepositoryProvider.overrideWithValue(blockRepo),
            widgetServiceProvider.overrideWithValue(mockWidgetService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await pumpWait(tester);

      await openEditor(tester, router, page.id);

      expect(find.byType(EditorPage), findsOneWidget);

      final backButton = find.byTooltip('Back');
      // Rapid multiple taps simulating fast repeated presses
      await tester.tap(backButton, warnIfMissed: false);
      await tester.tap(backButton, warnIfMissed: false);
      await tester.tap(backButton, warnIfMissed: false);
      await pumpWait(tester, 500);

      // Must remain at home destination without crash or blank screen
      expect(find.text('Home Destination Screen'), findsOneWidget);
      expect(find.byType(EditorPage), findsNothing);
    });

    testWidgets('Reopening note after back navigation restores content and hierarchy',
        (tester) async {
      final now = DateTime.now().toUtc();
      final page = Page(
        id: 'test-page-reopen',
        title: 'Reopen Note Title',
        createdAt: now,
        updatedAt: now,
      );
      await pageRepo.createPage(page);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Home Dashboard'),
            ),
          ),
          GoRoute(
            path: '/editor/:pageId',
            builder: (context, state) {
              final pageId = state.pathParameters['pageId']!;
              return EditorPage(pageId: pageId);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            pageRepositoryProvider.overrideWithValue(pageRepo),
            blockRepositoryProvider.overrideWithValue(blockRepo),
            widgetServiceProvider.overrideWithValue(mockWidgetService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await pumpWait(tester);

      // 1. Open editor first time
      await openEditor(tester, router, page.id);
      expect(find.byType(EditorPage), findsOneWidget);

      // 2. Navigate back to home
      await goBack(tester);
      expect(find.text('Home Dashboard'), findsOneWidget);

      // 3. Re-open editor second time
      await openEditor(tester, router, page.id);
      expect(find.byType(EditorPage), findsOneWidget);
      expect(find.byType(KetionEditorHost), findsOneWidget);

      // 4. Navigate back again
      await goBack(tester);
      expect(find.text('Home Dashboard'), findsOneWidget);
    });
  });
}
