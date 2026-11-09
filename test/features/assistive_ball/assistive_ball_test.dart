import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/core/database/app_database.dart' hide Page, Block;
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/assistive_ball/domain/services/assistive_ball_platform_service.dart';
import 'package:ketion/features/assistive_ball/presentation/providers/assistive_ball_provider.dart';
import 'package:ketion/features/assistive_ball/presentation/widgets/assistive_ball_widget.dart';
import 'package:ketion/features/assistive_ball/presentation/widgets/floating_note_view.dart';
import 'package:ketion/features/assistive_ball/presentation/widgets/note_selector_panel.dart';
import 'package:ketion/features/assistive_ball/presentation/widgets/root_assistive_ball_overlay.dart';
import 'package:ketion/features/blocks/data/repositories/block_repository_impl.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart' as entity;
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/features/pages/data/repositories/page_repository_impl.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/settings/domain/models/app_settings_model.dart';
import 'package:ketion/features/settings/domain/repositories/settings_repository.dart';
import 'package:ketion/features/settings/presentation/providers/settings_providers.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/features/widgets/domain/services/widget_service.dart';
import 'package:ketion/features/widgets/presentation/providers/widget_providers.dart';

class MockWidgetService implements WidgetService {
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

class MockAssistiveBallPlatformService implements AssistiveBallPlatformService {
  bool shown = false;
  double? lastX;
  double? lastY;

  @override
  bool get isSystemOverlaySupported => true;

  @override
  Future<bool> checkOverlayPermission() async => true;

  @override
  Future<bool> requestOverlayPermission() async => true;

  @override
  Future<void> showSystemOverlay({double? x, double? y}) async {
    shown = true;
    lastX = x;
    lastY = y;
  }

  @override
  Future<void> hideSystemOverlay() async {
    shown = false;
  }

  @override
  Future<void> updateSystemOverlayPosition(double x, double y) async {
    lastX = x;
    lastY = y;
  }

  @override
  void Function(double x, double y)? onPositionChanged;
}

class FakeSettingsRepository implements SettingsRepository {
  AppSettingsModel _settings;
  FakeSettingsRepository({bool assistiveBallEnabled = true})
      : _settings =
            AppSettingsModel(assistiveBallEnabled: assistiveBallEnabled);

  @override
  Future<AppSettingsModel> getSettings() async => _settings;

  @override
  Future<void> updateSettings(AppSettingsModel settings) async {
    _settings = settings;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssistiveBallNotifier Unit Tests', () {
    late MockAssistiveBallPlatformService mockPlatform;
    late FakeSettingsRepository fakeSettingsRepo;
    late ProviderContainer container;

    setUp(() {
      mockPlatform = MockAssistiveBallPlatformService();
      fakeSettingsRepo = FakeSettingsRepository(assistiveBallEnabled: true);
      container = ProviderContainer(
        overrides: [
          assistiveBallPlatformServiceProvider.overrideWithValue(mockPlatform),
          settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state has default coordinates and closed menu', () {
      final state = container.read(assistiveBallProvider);
      expect(state.normalizedX, 0.98);
      expect(state.normalizedY, 0.02);
      expect(state.isMenuOpen, isFalse);
      expect(state.isFloatingNoteOpen, isFalse);
      expect(state.isNoteSelectorOpen, isFalse);
    });

    test('updatePosition clamps coordinates within safe margins', () {
      final notifier = container.read(assistiveBallProvider.notifier);
      notifier.updatePosition(-1.0, 2.0);
      var state = container.read(assistiveBallProvider);
      expect(state.normalizedX, 0.02);
      expect(state.normalizedY, 0.98);

      notifier.updatePosition(0.5, 0.6);
      state = container.read(assistiveBallProvider);
      expect(state.normalizedX, 0.5);
      expect(state.normalizedY, 0.6);
    });

    test('snapToNearestEdge sets target coordinates and updates platform', () {
      final notifier = container.read(assistiveBallProvider.notifier);
      notifier.snapToNearestEdge(0.04, 0.7);
      final state = container.read(assistiveBallProvider);
      expect(state.normalizedX, 0.02);
      expect(state.normalizedY, 0.98);
    });

    test('snapToNearestCorner accurately routes to all four corner positions',
        () {
      final notifier = container.read(assistiveBallProvider.notifier);

      // Top-Left
      notifier.snapToNearestCorner(0.1, 0.1);
      var state = container.read(assistiveBallProvider);
      expect(state.normalizedX, 0.02);
      expect(state.normalizedY, 0.02);

      // Top-Right
      notifier.snapToNearestCorner(0.9, 0.1);
      state = container.read(assistiveBallProvider);
      expect(state.normalizedX, 0.98);
      expect(state.normalizedY, 0.02);

      // Bottom-Left
      notifier.snapToNearestCorner(0.1, 0.9);
      state = container.read(assistiveBallProvider);
      expect(state.normalizedX, 0.02);
      expect(state.normalizedY, 0.98);

      // Bottom-Right
      notifier.snapToNearestCorner(0.9, 0.9);
      state = container.read(assistiveBallProvider);
      expect(state.normalizedX, 0.98);
      expect(state.normalizedY, 0.98);
    });

    test('setEnabled synchronizes state, app settings, and platform overlay',
        () async {
      final notifier = container.read(assistiveBallProvider.notifier);

      await notifier.setEnabled(false);
      var state = container.read(assistiveBallProvider);
      expect(state.isEnabled, isFalse);
      expect(state.isVisible, isFalse);
      expect(state.isNoteSelectorOpen, isFalse);
      expect(mockPlatform.shown, isFalse);
      var settings = await fakeSettingsRepo.getSettings();
      expect(settings.assistiveBallEnabled, isFalse);

      await notifier.setEnabled(true);
      state = container.read(assistiveBallProvider);
      expect(state.isEnabled, isTrue);
      expect(state.isVisible, isTrue);
      expect(mockPlatform.shown, isTrue);
      settings = await fakeSettingsRepo.getSettings();
      expect(settings.assistiveBallEnabled, isTrue);
    });

    test('Floating note open, minimize, restore, and close workflow', () {
      final notifier = container.read(assistiveBallProvider.notifier);
      notifier.openFloatingNote();
      var state = container.read(assistiveBallProvider);
      expect(state.isFloatingNoteOpen, isTrue);
      expect(state.isNoteSelectorOpen, isFalse);
      expect(state.activePageId, isNull);
      expect(state.isNoteMinimized, isFalse);

      notifier.minimizeFloatingNote();
      state = container.read(assistiveBallProvider);
      expect(state.isNoteMinimized, isTrue);

      notifier.restoreFloatingNote();
      state = container.read(assistiveBallProvider);
      expect(state.isNoteMinimized, isFalse);

      notifier.updateFloatingNoteSize(360, 420);
      notifier.updateFloatingNotePosition(0.2, 0.3);
      state = container.read(assistiveBallProvider);
      expect(state.floatingNoteWidth, 360);
      expect(state.floatingNoteHeight, 420);
      expect(state.floatingNoteNormalizedX, 0.2);
      expect(state.floatingNoteNormalizedY, 0.3);

      notifier.closeFloatingNote();
      state = container.read(assistiveBallProvider);
      expect(state.isFloatingNoteOpen, isFalse);
      expect(state.isNoteSelectorOpen, isFalse);
    });

    test('Note selector open, close, and returnToNoteSelector workflow', () {
      final notifier = container.read(assistiveBallProvider.notifier);

      notifier.openNoteSelector();
      var state = container.read(assistiveBallProvider);
      expect(state.isNoteSelectorOpen, isTrue);
      expect(state.isFloatingNoteOpen, isFalse);
      expect(state.isMenuOpen, isFalse);

      notifier.openFloatingNote(pageId: 'note-456');
      state = container.read(assistiveBallProvider);
      expect(state.isNoteSelectorOpen, isFalse);
      expect(state.isFloatingNoteOpen, isTrue);
      expect(state.activePageId, 'note-456');

      notifier.returnToNoteSelector();
      state = container.read(assistiveBallProvider);
      expect(state.isNoteSelectorOpen, isTrue);
      expect(state.isFloatingNoteOpen, isFalse);
      expect(state.activePageId, isNull);

      notifier.closeNoteSelector();
      state = container.read(assistiveBallProvider);
      expect(state.isNoteSelectorOpen, isFalse);
    });

    test('openFloatingNote with pageId loads existing page ID', () {
      final notifier = container.read(assistiveBallProvider.notifier);
      notifier.openFloatingNote(pageId: 'test-page-123');
      final state = container.read(assistiveBallProvider);
      expect(state.isFloatingNoteOpen, isTrue);
      expect(state.isNoteSelectorOpen, isFalse);
      expect(state.activePageId, 'test-page-123');
    });

    test('Sequential createPage and createBlock unit test', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final syncQueueRepo = SyncQueueRepositoryImpl(db);
      final pageRepo = PageRepositoryImpl(db, syncQueueRepo, appLogger);
      final blockRepo = BlockRepositoryImpl(db, syncQueueRepo, appLogger);
      final now = DateTime.now();

      await pageRepo.createPage(
        Page(
          id: 'seq-page-1',
          title: 'Title 1',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await blockRepo.createBlock(
        entity.Block(
          id: 'seq-block-1',
          pageId: 'seq-page-1',
          type: 'text',
          position: 1000.0,
          data: '{"text":"Hello World"}',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final blocksResult = await blockRepo.getBlocksForPage('seq-page-1');
      expect(blocksResult.isSuccess, isTrue);
      await db.close();
    });
  });

  group('Assistive Ball & Floating Note Widget Tests', () {
    late AppDatabase db;
    late PageRepositoryImpl pageRepo;
    late BlockRepositoryImpl blockRepo;
    late MockAssistiveBallPlatformService mockPlatform;
    late MockWidgetService mockWidgetService;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final syncQueueRepo = SyncQueueRepositoryImpl(db);
      pageRepo = PageRepositoryImpl(db, syncQueueRepo, appLogger);
      blockRepo = BlockRepositoryImpl(db, syncQueueRepo, appLogger);
      mockPlatform = MockAssistiveBallPlatformService();
      mockWidgetService = MockWidgetService();
    });

    Widget createTestApp({
      required bool assistiveBallEnabled,
    }) {
      final fakeSettings = FakeSettingsRepository(
        assistiveBallEnabled: assistiveBallEnabled,
      );

      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          pageRepositoryProvider.overrideWithValue(pageRepo),
          blockRepositoryProvider.overrideWithValue(blockRepo),
          assistiveBallPlatformServiceProvider.overrideWithValue(mockPlatform),
          settingsRepositoryProvider.overrideWithValue(fakeSettings),
          widgetServiceProvider.overrideWithValue(mockWidgetService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RootAssistiveBallOverlay(
              child: Container(
                color: Colors.white,
                child: const Center(child: Text('Main Content')),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
        'Displays ball when enabled, menu has only Quick Note, Note Selector, Hide Ball',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(assistiveBallEnabled: true));
      await tester.pumpAndSettle();

      expect(find.byType(AssistiveBallWidget), findsOneWidget);
      expect(find.byIcon(Icons.bubble_chart_rounded), findsOneWidget);

      // Tap ball icon to open popout menu
      await tester.tap(find.byIcon(Icons.bubble_chart_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Quick Note'), findsOneWidget);
      expect(find.text('Note Selector'), findsOneWidget);
      expect(find.text('Hide Ball'), findsOneWidget);
      expect(find.text('Recent Note'), findsNothing);

      // Tap Quick Note
      await tester.tap(find.text('Quick Note'));
      await tester.pumpAndSettle();

      // Floating note view should appear with exactly one control (Close button)
      expect(find.byType(FloatingNoteView), findsOneWidget);
      expect(find.text('Quick Note'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
      expect(find.byTooltip('Back to Note Selector'), findsNothing);
      expect(find.byTooltip('Minimize'), findsNothing);
      expect(find.byTooltip('Open in Editor'), findsNothing);

      // Enter title and content
      await tester.enterText(
        find.widgetWithText(TextField, 'Note title...'),
        'My Quick Idea',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Type your thoughts here...'),
        'Remember to review Ketion floating note architecture.',
      );
      await tester.pump();

      // Tap Save button and wait for SQLite write to complete
      await tester.tap(find.widgetWithText(TextButton, 'Save Note'));
      await tester.pump();
      for (int i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (find.byType(FloatingNoteView).evaluate().isEmpty) break;
      }

      // Floating note should be closed
      expect(find.byType(FloatingNoteView), findsNothing);

      // Verify page was created in repository
      final pagesResult = await tester.runAsync(() => pageRepo.getAllPages());
      expect(pagesResult!.isSuccess, isTrue);
      final pages = pagesResult.valueOrNull!;
      expect(pages.any((p) => p.title == 'My Quick Idea'), isTrue);

      final createdPage = pages.firstWhere((p) => p.title == 'My Quick Idea');
      final blocksResult = await tester
          .runAsync(() => blockRepo.getBlocksForPage(createdPage.id));
      expect(blocksResult!.isSuccess, isTrue);
      final blocks = blocksResult.valueOrNull!;
      expect(blocks.length, greaterThanOrEqualTo(1));
      expect(
        blocks.any(
          (b) => b.data.contains(
            'Remember to review Ketion floating note architecture.',
          ),
        ),
        isTrue,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets(
        'Floating note view in preview mode has single back control and navigates correctly',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Pre-populate a page and blocks
      final now = DateTime.now();
      const testPageId = 'page-floater-1';
      await tester.runAsync(() async {
        await pageRepo.createPage(
          Page(
            id: testPageId,
            title: 'Project Roadmap',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await blockRepo.createBlock(
          entity.Block(
            id: 'block-1',
            pageId: testPageId,
            type: 'text',
            position: 1000.0,
            data: '{"text":"Milestone 1: Unified Page Scroll"}',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await blockRepo.createBlock(
          entity.Block(
            id: 'block-2',
            pageId: testPageId,
            type: 'text',
            position: 2000.0,
            data: '{"text":"Milestone 2: Floating Assistive Ball"}',
            createdAt: now,
            updatedAt: now,
          ),
        );
      });

      await tester.pumpWidget(createTestApp(assistiveBallEnabled: true));
      await tester.pumpAndSettle();

      // Open floating note for this page via notifier
      final element = tester.element(find.byType(RootAssistiveBallOverlay));
      final container = ProviderScope.containerOf(element);
      container
          .read(assistiveBallProvider.notifier)
          .openFloatingNote(pageId: testPageId);
      await tester.pump();

      for (int i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (find
            .text('Milestone 1: Unified Page Scroll')
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      expect(find.byType(FloatingNoteView), findsOneWidget);
      expect(find.text('Note Preview'), findsOneWidget);
      expect(find.text('Project Roadmap'), findsOneWidget);
      expect(find.text('Milestone 1: Unified Page Scroll'), findsOneWidget);
      expect(find.text('Milestone 2: Floating Assistive Ball'), findsOneWidget);

      // Verify exactly ONE header control (Back button)
      expect(find.byTooltip('Back to Note Selector'), findsOneWidget);
      expect(find.byTooltip('Close'), findsNothing);
      expect(find.byTooltip('Minimize'), findsNothing);
      expect(find.byTooltip('Open in Editor'), findsNothing);

      // Tap Back button to return to Note Selector Panel
      await tester.tap(find.byTooltip('Back to Note Selector'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      for (int i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (find.text('Select a Note').evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.byType(FloatingNoteView), findsNothing);
      expect(find.byType(NoteSelectorPanel), findsOneWidget);
      expect(find.text('Select a Note'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('Popout menu Note Selector opens panel and loads selected note',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      const testPageId = 'page-selector-123';
      await tester.runAsync(() async {
        await pageRepo.createPage(
          Page(
            id: testPageId,
            title: 'Selected Meeting Note',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await blockRepo.createBlock(
          entity.Block(
            id: 'block-sel-1',
            pageId: testPageId,
            type: 'text',
            position: 1000.0,
            data: '{"text":"Meeting action items"}',
            createdAt: now,
            updatedAt: now,
          ),
        );
      });

      await tester.pumpWidget(createTestApp(assistiveBallEnabled: true));
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byIcon(Icons.bubble_chart_rounded));
      await tester.pumpAndSettle();

      // Tap Note Selector
      expect(find.text('Note Selector'), findsOneWidget);
      await tester.tap(find.text('Note Selector'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // NoteSelectorPanel should be displayed
      expect(find.byType(NoteSelectorPanel), findsOneWidget);
      expect(find.text('Select a Note'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is IconButton &&
              (w.tooltip == 'Close Note Selector' || w.tooltip == 'Close'),
        ),
        findsOneWidget,
      );

      for (int i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (find.text('Selected Meeting Note').evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.text('Selected Meeting Note'), findsOneWidget);

      // Select the note
      await tester.tap(find.text('Selected Meeting Note'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      for (int i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (find.text('Selected Meeting Note').evaluate().isNotEmpty) {
          break;
        }
      }

      // Floating note view should now be open for this note
      expect(find.byType(FloatingNoteView), findsOneWidget);
      expect(find.byType(NoteSelectorPanel), findsNothing);
      expect(find.text('Note Preview'), findsOneWidget);
      expect(find.text('Selected Meeting Note'), findsOneWidget);

      // Verify back button is visible and tapping returns to Note Selector Panel
      expect(find.byTooltip('Back to Note Selector'), findsOneWidget);
      await tester.tap(find.byTooltip('Back to Note Selector'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      for (int i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (find.text('Select a Note').evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.byType(NoteSelectorPanel), findsOneWidget);
      expect(find.byType(FloatingNoteView), findsNothing);
      expect(find.text('Select a Note'), findsOneWidget);

      // Tap Close on NoteSelectorPanel
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is IconButton &&
              (w.tooltip == 'Close Note Selector' || w.tooltip == 'Close'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NoteSelectorPanel), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
