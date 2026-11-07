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
import 'package:ketion/features/blocks/domain/entities/block.dart' as entity;
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/features/editor/presentation/pages/editor_page.dart';
import 'package:ketion/features/editor/presentation/widgets/page_header.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_host.dart';
import 'package:ketion/features/pages/data/repositories/page_repository_impl.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/features/widgets/domain/services/widget_service.dart';
import 'package:ketion/features/widgets/presentation/providers/widget_providers.dart';
import 'package:super_editor/super_editor.dart';

class MockWidgetService implements WidgetService {
  @override
  Future<Result<void>> generateWidgetSnapshot() async => const Success(null);

  @override
  Future<Result<void>> triggerWidgetUpdate() async => const Success(null);

  @override
  Future<Result<void>> updateSimpleWidgetData(String key, dynamic value) async =>
      const Success(null);
}

Future<void> pumpUntilInitialized(WidgetTester tester) async {
  int attempts = 0;
  while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
      attempts < 50) {
    await tester.pump(const Duration(milliseconds: 50));
    attempts++;
  }
  expect(attempts < 50, isTrue);
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PageRepositoryImpl pageRepo;
  late BlockRepositoryImpl blockRepo;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final syncQueueRepo = SyncQueueRepositoryImpl(db);
    pageRepo = PageRepositoryImpl(db, syncQueueRepo, appLogger);
    blockRepo = BlockRepositoryImpl(db, syncQueueRepo, appLogger);
  });

  testWidgets(
      'Full-page scrolling hosts PageHeader and SuperEditor in unified CustomScrollView',
      (tester) async {
    final now = DateTime.now().toUtc();
    final page = Page(
      id: 'scroll-test-page',
      title: 'Full Page Scrolling Test',
      coverImage: 'cover-1',
      icon: '📝',
      createdAt: now,
      updatedAt: now,
    );
    await pageRepo.createPage(page);

    // Create several blocks to make the document scrollable.
    for (int i = 0; i < 20; i++) {
      await blockRepo.createBlock(entity.Block(
        id: 'block-$i',
        pageId: 'scroll-test-page',
        type: 'text',
        position: i * 1000.0,
        data: '{"text":"Block content line $i that fills up space in the document"}',
        createdAt: now,
        updatedAt: now,
      ),);
    }

    final router = GoRouter(
      initialLocation: '/editor/scroll-test-page',
      routes: [
        GoRoute(
          path: '/editor/:pageId',
          builder: (context, state) =>
              EditorPage(pageId: state.pathParameters['pageId']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          pageRepositoryProvider.overrideWithValue(pageRepo),
          blockRepositoryProvider.overrideWithValue(blockRepo),
          widgetServiceProvider.overrideWithValue(MockWidgetService()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await pumpUntilInitialized(tester);
    await tester.pumpAndSettle();

    // Verify CustomScrollView is present in the editor host.
    final customScrollViewFinder = find.descendant(
      of: find.byType(SuperEditorHost),
      matching: find.byType(CustomScrollView),
    );
    expect(customScrollViewFinder, findsOneWidget);

    // Verify PageHeader and SuperEditor are descendants of the CustomScrollView.
    expect(
      find.descendant(
        of: customScrollViewFinder,
        matching: find.byType(PageHeader),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: customScrollViewFinder,
        matching: find.byType(SuperEditor),
      ),
      findsOneWidget,
    );

    // Get initial position of PageHeader.
    final initialHeaderY = tester.getTopLeft(find.byType(PageHeader)).dy;

    // Drag scroll upwards by 200 pixels.
    await tester.drag(customScrollViewFinder, const Offset(0, -200));
    await tester.pumpAndSettle();

    // Verify PageHeader moved upwards along with the unified scroll view.
    final scrolledHeaderY = tester.getTopLeft(find.byType(PageHeader)).dy;
    expect(scrolledHeaderY, lessThan(initialHeaderY));

    // Cleanup widget tree and database
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await db.close();
  });
}
