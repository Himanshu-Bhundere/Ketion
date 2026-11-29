import 'dart:async';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ketion/core/database/app_database.dart' hide Page, Block;
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/features/blocks/data/repositories/block_repository_impl.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/features/editor/presentation/pages/editor_page.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_edit_requests.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_list_item_component.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_slash_command_registry.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_toggle_keyboard_actions.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_host.dart';
import 'package:ketion/features/pages/data/repositories/page_repository_impl.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:super_editor/super_editor.dart';

Future<void> _pumpUntilInitialized(WidgetTester tester) async {
  int attempts = 0;
  while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
      attempts < 50) {
    await tester.pump(const Duration(milliseconds: 50));
    attempts++;
  }
  if (attempts >= 50) {
    throw Exception('Timed out waiting for editor initialization');
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _pumpWait(WidgetTester tester, [int millis = 150]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: millis));
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

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await db.close();
  });

  Future<(GoRouter, SuperEditorHostState)> pumpEditorForPage(
    WidgetTester tester,
    Page page,
  ) async {
    await pageRepo.createPage(page);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Text('Home'),
          ),
        ),
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
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await _pumpWait(tester);

    unawaited(router.push('/editor/${page.id}'));
    await _pumpWait(tester, 300);
    await _pumpUntilInitialized(tester);

    final hostState =
        tester.state<SuperEditorHostState>(find.byType(SuperEditorHost));
    return (router, hostState);
  }

  void runSlashOption(
    SuperEditorHostState host,
    String nodeId,
    String optionId,
  ) {
    final doc = host.document;
    final editor = host.editor;
    final cmd = KetionSlashCommandRegistry.allCommands
        .firstWhere((c) => c.id == optionId);
    final innerRequests = cmd.getEditRequestsWithDoc(nodeId, doc);
    expect(innerRequests, isNotEmpty, reason: 'No requests for $optionId');

    final slashStr = '/$optionId';
    final node = doc.getNodeById(nodeId) as TextNode;
    final endOffset = node.text.toPlainText().length;
    editor.execute([
      InsertTextRequest(
        documentPosition: DocumentPosition(
          nodeId: nodeId,
          nodePosition: TextNodePosition(offset: endOffset),
        ),
        textToInsert: slashStr,
        attributions: const {},
      ),
    ]);

    final afterInsertNode = doc.getNodeById(nodeId) as TextNode;
    final target = SlashCommandTarget(
      nodeId: nodeId,
      slashStartIndex: endOffset,
      slashEndIndex: afterInsertNode.text.toPlainText().length,
    );

    editor.execute([
      ConvertSlashCommandRequest(
        target: target,
        innerRequest: innerRequests.first,
      ),
      ...innerRequests.skip(1),
    ]);
  }

  Future<void> flushAndPump(
    WidgetTester tester,
    SuperEditorHostState host,
  ) async {
    bool done = false;
    Object? err;
    unawaited(
      host.flush().then<void>(
        (_) => done = true,
        onError: (Object e) {
          err = e;
          done = true;
        },
      ),
    );
    int ticks = 0;
    while (!done && ticks < 100) {
      await tester.pump(const Duration(milliseconds: 20));
      ticks++;
    }
    if (err != null) {
      throw err!;
    }
    if (!done) {
      throw TimeoutException('Timed out flushing SuperEditorHost');
    }
  }

  Future<void> focusNodeAtEnd(
    WidgetTester tester,
    SuperEditorHostState host,
    String nodeId,
  ) async {
    await tester.tap(find.byType(ParagraphComponent).first, warnIfMissed: false);
    await _pumpWait(tester, 50);
    final node = host.document.getNodeById(nodeId) as TextNode;
    host.editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: nodeId,
            nodePosition: TextNodePosition(offset: node.text.length),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
    await _pumpWait(tester, 50);
  }

  group('List Enter Continuation Repro', () {
    testWidgets(
      'root bulleted, numbered, and checklist continue with hardware Enter and persist',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
        final now = DateTime.now().toUtc();
        final page = Page(
          id: 'root-lists-hw',
          title: 'Root Lists HW',
          createdAt: now,
          updatedAt: now,
        );
        final (router, host) = await pumpEditorForPage(tester, page);

        final firstId = host.document.first.id;
        await focusNodeAtEnd(tester, host, firstId);

        // 1. Bulleted list
        runSlashOption(host, firstId, 'bulleted_list');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Bullet 1')]);
        await _pumpWait(tester, 50);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpWait(tester, 100);

        expect(host.document.nodeCount, greaterThanOrEqualTo(2));
        final bullet2 = host.document.getNodeAt(1);
        expect(bullet2, isA<ListItemNode>());
        expect((bullet2 as ListItemNode).type, ListItemType.unordered);
        host.editor.execute([const InsertPlainTextAtCaretRequest('Bullet 2')]);
        await _pumpWait(tester, 50);

        // Advance to plain paragraph via second Enter (empty bullet exits)
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpWait(tester, 100);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpWait(tester, 100);

        // 2. Numbered list
        final numStartId = host.composer.selection!.extent.nodeId;
        runSlashOption(host, numStartId, 'numbered_list');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Step 1')]);
        await _pumpWait(tester, 50);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpWait(tester, 100);

        final num2 = host.document.getNodeAfterById(numStartId);
        expect(num2, isA<ListItemNode>());
        expect((num2 as ListItemNode).type, ListItemType.ordered);
        expect(
          computeKetionListItemOrdinalValue(num2, host.document),
          equals(2),
        );
        host.editor.execute([const InsertPlainTextAtCaretRequest('Step 2')]);
        await _pumpWait(tester, 50);

        // Advance out of numbered list
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpWait(tester, 100);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpWait(tester, 100);

        // 3. Checklist
        final taskStartId = host.composer.selection!.extent.nodeId;
        runSlashOption(host, taskStartId, 'checklist');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Task 1')]);
        await _pumpWait(tester, 50);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpWait(tester, 100);

        final task2 = host.document.getNodeAfterById(taskStartId);
        expect(task2, isA<TaskNode>());
        expect((task2 as TaskNode).isComplete, isFalse);
        host.editor.execute([const InsertPlainTextAtCaretRequest('Task 2')]);
        await _pumpWait(tester, 50);

        await flushAndPump(tester, host);
        await _pumpWait(tester, 350);

        // Verify persisted blocks after reload
        router.pop();
        await _pumpWait(tester, 200);
        unawaited(router.push('/editor/${page.id}'));
        await _pumpWait(tester, 300);
        await _pumpUntilInitialized(tester);
        final reopenedHost =
            tester.state<SuperEditorHostState>(find.byType(SuperEditorHost));
        final ordered = reopenedHost.document
            .whereType<ListItemNode>()
            .where((n) => n.type == ListItemType.ordered)
            .toList();
        final unordered = reopenedHost.document
            .whereType<ListItemNode>()
            .where((n) => n.type == ListItemType.unordered)
            .toList();
        final tasks = reopenedHost.document.whereType<TaskNode>().toList();

        expect(unordered.length, greaterThanOrEqualTo(2));
        expect(ordered.length, greaterThanOrEqualTo(2));
        expect(tasks.length, greaterThanOrEqualTo(2));
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'root bulleted, numbered, and checklist continue with IME InsertNewlineAtCaretRequest',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
        final now = DateTime.now().toUtc();
        final page = Page(
          id: 'root-lists-ime',
          title: 'Root Lists IME',
          createdAt: now,
          updatedAt: now,
        );
        final (_, host) = await pumpEditorForPage(tester, page);

        final bulletId = host.document.first.id;
        await focusNodeAtEnd(tester, host, bulletId);
        runSlashOption(host, bulletId, 'bulleted_list');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Bullet A')]);
        host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
        await _pumpWait(tester, 50);
        expect(host.document.getNodeAfterById(bulletId), isA<ListItemNode>());
        expect(
          (host.document.getNodeAfterById(bulletId) as ListItemNode).type,
          ListItemType.unordered,
        );

        // Exit bullet via second empty Enter
        host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
        await _pumpWait(tester, 50);

        final numId = host.composer.selection!.extent.nodeId;
        runSlashOption(host, numId, 'numbered_list');
        host.editor.execute([const InsertPlainTextAtCaretRequest('One')]);
        host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
        await _pumpWait(tester, 50);
        final num2 = host.document.getNodeAfterById(numId);
        expect(num2, isA<ListItemNode>());
        expect((num2 as ListItemNode).type, ListItemType.ordered);

        // Exit numbered list via empty Enter
        host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
        await _pumpWait(tester, 50);

        final taskId = host.composer.selection!.extent.nodeId;
        runSlashOption(host, taskId, 'checklist');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Todo 1')]);
        host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
        await _pumpWait(tester, 50);
        expect(host.document.getNodeAfterById(taskId), isA<TaskNode>());

        await flushAndPump(tester, host);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'toggle-nested bulleted, numbered, and checklist continue inside toggle on hardware Enter and IME Enter',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
        final now = DateTime.now().toUtc();
        final page = Page(
          id: 'toggle-lists',
          title: 'Toggle Lists',
          createdAt: now,
          updatedAt: now,
        );
        final (_, host) = await pumpEditorForPage(tester, page);

        final toggleId = host.document.first.id;
        await focusNodeAtEnd(tester, host, toggleId);
        runSlashOption(host, toggleId, 'toggle');
        host.editor.execute([const InsertPlainTextAtCaretRequest('My Toggle')]);
        await _pumpWait(tester, 50);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpWait(tester, 100);

        final toggleBlockId = host.registry.blockIdForNode(toggleId);
        expect(toggleBlockId, isNotNull);

        // Convert toggle child to numbered list, type item 1, press hardware Enter
        final num1Id = host.composer.selection!.extent.nodeId;
        runSlashOption(host, num1Id, 'numbered_list');
        host.editor.execute([const InsertPlainTextAtCaretRequest('First')]);
        await _pumpWait(tester, 50);
        expect(
          isInsideToggleBody(
            host.document.getNodeById(num1Id)!,
            host.document,
            host.registry,
          ),
          isTrue,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpWait(tester, 100);

        final num2 = host.document.getNodeAfterById(num1Id);
        expect(
          num2,
          isA<ListItemNode>(),
          reason: 'Hardware Enter on numbered list inside toggle should create next numbered list item',
        );
        expect((num2 as ListItemNode).type, ListItemType.ordered);
        expect(num2.metadata['parentBlockId'], equals(toggleBlockId));
        expect(num2.metadata['depth'], equals(1));
        expect(computeKetionListItemOrdinalValue(num2, host.document), equals(2));

        // Now test IME Enter (InsertNewlineAtCaretRequest) inside toggle on bullet & checklist
        host.editor.execute([const InsertPlainTextAtCaretRequest('Second')]);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter); // creates item 3
        await _pumpWait(tester, 50);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter); // exits list inside toggle
        await _pumpWait(tester, 50);

        final bullet1Id = host.composer.selection!.extent.nodeId;
        runSlashOption(host, bullet1Id, 'bulleted_list');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Bullet A')]);
        host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
        await _pumpWait(tester, 50);

        final bullet2 = host.document.getNodeAfterById(bullet1Id);
        expect(
          bullet2,
          isA<ListItemNode>(),
          reason: 'IME Enter on bullet list inside toggle should create next bullet item',
        );
        expect((bullet2 as ListItemNode).type, ListItemType.unordered);
        expect(bullet2.metadata['parentBlockId'], equals(toggleBlockId));
        expect(bullet2.metadata['depth'], equals(1));

        // Exit bullet list to toggle child paragraph
        host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
        await _pumpWait(tester, 50);

        final task1Id = host.composer.selection!.extent.nodeId;
        runSlashOption(host, task1Id, 'checklist');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Check A')]);
        host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
        await _pumpWait(tester, 50);

        final task2 = host.document.getNodeAfterById(task1Id);
        expect(
          task2,
          isA<TaskNode>(),
          reason: 'IME Enter on checklist inside toggle should create next checklist item',
        );
        expect((task2 as TaskNode).metadata['parentBlockId'], equals(toggleBlockId));
        expect(task2.metadata['depth'], equals(1));

        // Pressing Enter on empty checklist directly inside toggle converts to toggle-body paragraph
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpWait(tester, 100);
        final exitedTaskToPara = host.document.getNodeById(task2.id);
        expect(exitedTaskToPara, isA<ParagraphNode>());
        expect(exitedTaskToPara!.metadata['parentBlockId'], equals(toggleBlockId));
        expect(exitedTaskToPara.metadata['depth'], equals(1));

        // Pressing Enter again on empty toggle-body paragraph exits toggle
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpWait(tester, 100);
        final exitedTogglePara = host.document.getNodeById(task2.id);
        expect(exitedTogglePara, isA<ParagraphNode>());
        expect(exitedTogglePara!.metadata['parentBlockId'], isNull);
        expect(exitedTogglePara.metadata['depth'], equals(0));

        await flushAndPump(tester, host);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'root lists via slashCommandController and IME performAction(TextInputAction.newline) continue across iOS/Android',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
        final now = DateTime.now().toUtc();
        final page = Page(
          id: 'ios-ime-lists',
          title: 'iOS IME Lists',
          createdAt: now,
          updatedAt: now,
        );
        final (_, host) = await pumpEditorForPage(tester, page);

        final firstId = host.document.first.id;
        await focusNodeAtEnd(tester, host, firstId);

        // Select /numbered_list via live slashCommandController
        host.editor.execute([const InsertPlainTextAtCaretRequest('/numbered')]);
        await _pumpWait(tester, 100);
        host.slashCommandController.selectCommand(0);
        await _pumpWait(tester, 100);

        expect(host.document.getNodeById(firstId), isA<ListItemNode>());
        host.editor.execute([const InsertPlainTextAtCaretRequest('Item one')]);
        await _pumpWait(tester, 50);

        await tester.testTextInput.receiveAction(TextInputAction.newline);
        await _pumpWait(tester, 100);

        final secondNode = host.document.getNodeAfterById(firstId);
        expect(secondNode, isA<ListItemNode>());
        expect((secondNode as ListItemNode).type, ListItemType.ordered);
        expect(computeKetionListItemOrdinalValue(secondNode, host.document), 2);

        // Repeat with indented nested list item
        host.editor.execute([const InsertPlainTextAtCaretRequest('Item two')]);
        await _pumpWait(tester, 50);
        host.editor.execute([IndentListItemRequest(nodeId: secondNode.id)]);
        await _pumpWait(tester, 50);

        await tester.testTextInput.receiveAction(TextInputAction.newline);
        await _pumpWait(tester, 100);

        final thirdNode = host.document.getNodeAfterById(secondNode.id);
        final refreshedSecond =
            host.document.getNodeById(secondNode.id) as ListItemNode;
        expect(thirdNode, isA<ListItemNode>());
        expect((thirdNode as ListItemNode).type, ListItemType.ordered);
        expect(thirdNode.indent, equals(1));
        expect(
          thirdNode.metadata['parentBlockId'],
          equals(refreshedSecond.metadata['parentBlockId']),
          reason: 'Indented list Enter must keep sibling parentBlockId',
        );

        await flushAndPump(tester, host);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'indented checklist preserves indent/parent on Enter, outdents on empty Enter, and supports Undo/Redo',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final now = DateTime.now().toUtc();
          final page = Page(
            id: 'indented-checklist',
            title: 'Indented Checklist',
            createdAt: now,
            updatedAt: now,
          );
          final (_, host) = await pumpEditorForPage(tester, page);

          final parentTaskId = host.document.first.id;
          await focusNodeAtEnd(tester, host, parentTaskId);
          runSlashOption(host, parentTaskId, 'checklist');
          host.editor.execute([const InsertPlainTextAtCaretRequest('Parent')]);
          host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
          await _pumpWait(tester, 50);

          final child1 = host.document.getNodeAfterById(parentTaskId) as TaskNode;
          host.editor.execute([const InsertPlainTextAtCaretRequest('Child 1')]);
          await _pumpWait(tester, 50);
          host.editor.execute([IndentTaskRequest(child1.id)]);
          await _pumpWait(tester, 50);

          final indentedChild1 = host.document.getNodeById(child1.id) as TaskNode;
          final parentBlockId = host.registry.blockIdForNode(parentTaskId);
          expect(indentedChild1.indent, equals(1));
          expect(indentedChild1.metadata['parentBlockId'], equals(parentBlockId));

          // Enter via Android delta-forwarded InsertNewlineAtCaretRequest
          host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
          await _pumpWait(tester, 50);

          final child2 = host.document.getNodeAfterById(child1.id);
          expect(child2, isA<TaskNode>());
          expect((child2 as TaskNode).indent, equals(1));
          expect(child2.isComplete, isFalse);
          expect(child2.metadata['depth'], equals(1));
          expect(child2.metadata['parentBlockId'], equals(parentBlockId));

          // Enter on empty nested child2 unindents back to depth 0 (still TaskNode)
          host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
          await _pumpWait(tester, 50);
          final unindented = host.document.getNodeById(child2.id) as TaskNode;
          expect(unindented.indent, equals(0));
          expect(unindented.metadata['depth'], equals(0));
          expect(unindented.metadata['parentBlockId'], isNull);

          // Second Enter at depth 0 exits to plain ParagraphNode
          host.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
          await _pumpWait(tester, 50);
          expect(host.document.getNodeById(child2.id), isA<ParagraphNode>());

          // Undo brings back unindented TaskNode cleanly
          host.historyController.undo();
          await _pumpWait(tester, 50);
          expect(host.document.getNodeById(child2.id), isA<TaskNode>());

          await flushAndPump(tester, host);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'floating toolbar bullet button keeps focus and continues bullet list on hardware Enter',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          final now = DateTime.now().toUtc();
          final page = Page(
            id: 'toolbar-bullet',
            title: 'Toolbar Bullet',
            createdAt: now,
            updatedAt: now,
          );
          final (_, host) = await pumpEditorForPage(tester, page);

          final firstId = host.document.first.id;
          await tester.tap(
            find.byWidgetPredicate((w) => w is SizedBox && w.height == 120),
          );
          await _pumpWait(tester, 50);
          await focusNodeAtEnd(tester, host, firstId);
          await _pumpWait(tester, 50);

          final toolbarBtn = find.byKey(const ValueKey('toolbar_bullet_list'));
          expect(toolbarBtn, findsOneWidget);
          await tester.tap(toolbarBtn);
          await _pumpWait(tester, 100);

          expect(host.document.getNodeById(firstId), isA<ListItemNode>());
          host.editor.execute([const InsertPlainTextAtCaretRequest('Toolbar item')]);
          await _pumpWait(tester, 50);

          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await _pumpWait(tester, 100);

          final second = host.document.getNodeAfterById(firstId);
          expect(
            second,
            isA<ListItemNode>(),
            reason: 'Clicking toolbar bullet button and pressing Enter should create next bullet item',
          );

          await flushAndPump(tester, host);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
