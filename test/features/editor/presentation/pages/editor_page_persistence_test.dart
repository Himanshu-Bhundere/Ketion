import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ketion/core/database/app_database.dart' hide Page, Block;
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/blocks/data/repositories/block_repository_impl.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/features/editor/presentation/pages/editor_page.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_editor_host.dart';
import 'package:ketion/features/pages/data/repositories/page_repository_impl.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';
import 'package:ketion/features/pages/domain/repositories/page_repository.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/features/widgets/domain/services/widget_service.dart';
import 'package:ketion/features/widgets/presentation/providers/widget_providers.dart';

class _MockWidgetService implements WidgetService {
  @override
  Future<Result<void>> generateWidgetSnapshot() async => const Success(null);

  @override
  Future<Result<void>> triggerWidgetUpdate() async => const Success(null);

  @override
  Future<Result<void>> updateSimpleWidgetData(
    String key,
    dynamic value,
  ) async =>
      const Success(null);
}

class _FailingPageRepository implements PageRepository {
  final PageRepository _delegate;
  bool failUpdate = false;

  _FailingPageRepository(this._delegate);

  @override
  Future<Result<void>> createPage(
    Page page, {
    String initialBlockType = 'text',
  }) =>
      _delegate.createPage(page, initialBlockType: initialBlockType);

  @override
  Future<Result<Page>> getPage(String id) => _delegate.getPage(id);

  @override
  Future<Result<void>> updatePage(Page page) async {
    if (failUpdate) {
      return const Error(UnknownFailure('Simulated failure updating page'));
    }
    return _delegate.updatePage(page);
  }

  @override
  Future<Result<void>> deletePage(String id) => _delegate.deletePage(id);

  @override
  Future<Result<void>> restorePage(String id) => _delegate.restorePage(id);

  @override
  Future<Result<void>> permanentlyDeletePage(String id) =>
      _delegate.permanentlyDeletePage(id);

  @override
  Future<Result<void>> emptyTrash() => _delegate.emptyTrash();

  @override
  Future<Result<List<Page>>> getRecentPages() => _delegate.getRecentPages();

  @override
  Future<Result<List<Page>>> getFavoritePages() => _delegate.getFavoritePages();

  @override
  Future<Result<List<Page>>> getChildPages(String parentId) =>
      _delegate.getChildPages(parentId);

  @override
  Future<Result<List<Page>>> getTemplatePages() => _delegate.getTemplatePages();

  @override
  Future<Result<List<Page>>> getDeletedPages() => _delegate.getDeletedPages();
}

Future<void> _pumpUntilInitialized(WidgetTester tester) async {
  int attempts = 0;
  while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
      attempts < 50) {
    await tester.pump(const Duration(milliseconds: 50));
    attempts++;
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _pumpWait(WidgetTester tester, [int millis = 300]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: millis));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PageRepositoryImpl realPageRepo;
  late _FailingPageRepository failingPageRepo;
  late BlockRepositoryImpl blockRepo;
  late _MockWidgetService mockWidgetService;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final syncQueueRepo = SyncQueueRepositoryImpl(db);
    realPageRepo = PageRepositoryImpl(db, syncQueueRepo, appLogger);
    failingPageRepo = _FailingPageRepository(realPageRepo);
    blockRepo = BlockRepositoryImpl(db, syncQueueRepo, appLogger);
    mockWidgetService = _MockWidgetService();
  });

  group('EditorPage Persistence Lifecycle Tests', () {
    testWidgets(
        'Failed note update prevents navigation and displays snackbar error',
        (tester) async {
      final now = DateTime.now().toUtc();
      final page = Page(
        id: 'test-page-persistence-fail',
        title: 'Original Title',
        createdAt: now,
        updatedAt: now,
      );
      await realPageRepo.createPage(page);

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
            pageRepositoryProvider.overrideWithValue(failingPageRepo),
            blockRepositoryProvider.overrideWithValue(blockRepo),
            widgetServiceProvider.overrideWithValue(mockWidgetService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await _pumpWait(tester);

      // Open editor
      unawaited(router.push('/editor/${page.id}'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _pumpUntilInitialized(tester);

      expect(find.byType(EditorPage), findsOneWidget);

      // Trigger a failing title update
      failingPageRepo.failUpdate = true;
      final host =
          tester.widget<KetionEditorHost>(find.byType(KetionEditorHost));

      // Trigger in-flight update on the page that will fail
      unawaited(host.onTitleChanged('Failed New Title'));
      await tester.pump();

      // Tap back button while in-flight title update will fail
      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // EditorPage should remain mounted
      expect(find.byType(EditorPage), findsOneWidget);
      expect(find.text('Home Destination Screen'), findsNothing);

      // SnackBar should be displayed
      expect(
        find.text(
          'Your changes could not be saved. The editor will remain open.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
