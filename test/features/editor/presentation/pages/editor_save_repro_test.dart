import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ketion/core/database/app_database.dart' hide Page, Block;
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/features/blocks/data/repositories/block_repository_impl.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/features/editor/presentation/pages/editor_page.dart';
import 'package:ketion/features/editor/presentation/widgets/convert_paragraph_to_callout.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_callout_node.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_edit_requests.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_slash_command_registry.dart';
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

Future<void> _pumpWait(WidgetTester tester, [int millis = 200]) async {
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
    String optionId, {
    String typedText = '',
  }) {
    final doc = host.document;
    final editor = host.editor;
    final cmd = KetionSlashCommandRegistry.allCommands
        .firstWhere((c) => c.id == optionId);
    final innerRequests = cmd.getEditRequestsWithDoc(nodeId, doc);
    expect(innerRequests, isNotEmpty, reason: 'No requests for $optionId');

    final slashStr = '/$optionId';
    if (typedText.isNotEmpty) {
      editor.execute([
        InsertPlainTextAtCaretRequest(typedText),
      ]);
    }
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

  group('Real SQLite Editor Multi-Option Save Repro', () {
    testWidgets(
      'toggle inside toggle, multiple collapsed toggles, and back save',
      (tester) async {
        final now = DateTime.now().toUtc();
        final page = Page(
          id: 'repro-nested-toggles',
          title: 'Meghalaya',
          createdAt: now,
          updatedAt: now,
        );
        final (_, host) = await pumpEditorForPage(tester, page);

        final firstNodeId = host.document.first.id;
        host.editor.execute([
          ChangeSelectionRequest(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: firstNodeId,
                nodePosition: const TextNodePosition(offset: 0),
              ),
            ),
            SelectionChangeType.placeCaret,
            SelectionReason.userInteraction,
          ),
        ]);

        // 1. Convert first paragraph to /toggle and type 'Food'
        runSlashOption(host, firstNodeId, 'toggle');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Food')]);
        await _pumpWait(tester, 50);

        // 2. Press Enter (InsertNewlineAtCaretRequest) to insert child inside Food
        final childInsideFoodId = Editor.createNodeId();
        host.editor.execute([
          InsertNewlineAtCaretRequest(childInsideFoodId),
        ]);
        await _pumpWait(tester, 50);

        // 3. Convert child inside Food to /toggle (TOGGLE INSIDE TOGGLE!)
        runSlashOption(host, childInsideFoodId, 'toggle');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Momos')]);
        await _pumpWait(tester, 50);

        // 4. Press Enter inside nested toggle 'Momos' -> child inside Momos
        final grandchildId = Editor.createNodeId();
        host.editor.execute([
          InsertNewlineAtCaretRequest(grandchildId),
        ]);
        host.editor.execute([const InsertPlainTextAtCaretRequest('Steamed')]);
        await _pumpWait(tester, 50);

        // 5. Collapse nested toggle, then collapse Food
        host.editor.execute([
          ToggleExpandedRequest(nodeId: childInsideFoodId, isExpanded: false),
        ]);
        await _pumpWait(tester, 50);
        host.editor.execute([
          ToggleExpandedRequest(nodeId: firstNodeId, isExpanded: false),
        ]);
        await _pumpWait(tester, 50);

        // 6. Press Enter on collapsed Food -> exit paragraph, convert to /toggle 'Clothes'
        final clothesNodeId = Editor.createNodeId();
        host.editor.execute([
          ChangeSelectionRequest(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: firstNodeId,
                nodePosition: TextNodePosition(
                  offset: (host.document.getNodeById(firstNodeId) as TextNode)
                      .text
                      .length,
                ),
              ),
            ),
            SelectionChangeType.placeCaret,
            SelectionReason.userInteraction,
          ),
          InsertNewlineAtCaretRequest(clothesNodeId),
        ]);
        await _pumpWait(tester, 50);
        runSlashOption(host, clothesNodeId, 'toggle');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Clothes')]);
        final jacketNodeId = Editor.createNodeId();
        host.editor.execute([
          InsertNewlineAtCaretRequest(jacketNodeId),
        ]);
        host.editor.execute([const InsertPlainTextAtCaretRequest('Jacket')]);
        host.editor.execute([
          ToggleExpandedRequest(nodeId: clothesNodeId, isExpanded: false),
        ]);
        await _pumpWait(tester, 50);

        // Tap Back immediately
        await tester.tap(find.byTooltip('Back'));
        await _pumpWait(tester, 500);

        expect(
          find.textContaining('Your changes could not be saved'),
          findsNothing,
        );
        expect(find.text('Home'), findsOneWidget);

        // Verify persisted blocks in SQLite
        final savedRes = await blockRepo.getBlocksForPage(page.id);
        final savedBlocks = savedRes.valueOrNull ?? [];
        expect(savedBlocks.length, 5);
      },
    );

    testWidgets(
      'multiple slash options including checklist/bullet to toggle inside toggle',
      (tester) async {
        final now = DateTime.now().toUtc();
        final page = Page(
          id: 'repro-multi-options',
          title: 'Multi Options',
          createdAt: now,
          updatedAt: now,
        );
        final (_, host) = await pumpEditorForPage(tester, page);

        final firstNodeId = host.document.first.id;
        host.editor.execute([
          ChangeSelectionRequest(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: firstNodeId,
                nodePosition: const TextNodePosition(offset: 0),
              ),
            ),
            SelectionChangeType.placeCaret,
            SelectionReason.userInteraction,
          ),
        ]);

        // Toggle -> bullet -> convert bullet to /toggle -> child -> checklist -> h1 -> callout -> code -> divider -> table
        runSlashOption(host, firstNodeId, 'toggle');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Outer')]);

        final bulletChildId = Editor.createNodeId();
        host.editor.execute([
          InsertNewlineAtCaretRequest(bulletChildId),
        ]);
        runSlashOption(host, bulletChildId, 'bulleted_list');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Converted')]);

        // Convert ListItemNode inside toggle to /toggle!
        runSlashOption(host, bulletChildId, 'toggle');
        final nestedChildId = Editor.createNodeId();
        host.editor.execute([
          InsertNewlineAtCaretRequest(nestedChildId),
        ]);
        runSlashOption(host, nestedChildId, 'checklist');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Task A')]);

        // Convert TaskNode to /callout or paragraph/toggle
        final task2Id = Editor.createNodeId();
        host.editor.execute([
          SplitExistingTaskRequest(
            existingNodeId: nestedChildId,
            splitOffset: 6,
            newNodeId: task2Id,
          ),
        ]);
        runSlashOption(host, task2Id, 'h1');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Heading')]);

        final afterH1Id = Editor.createNodeId();
        host.editor.execute([InsertNewlineAtCaretRequest(afterH1Id)]);
        runSlashOption(host, afterH1Id, 'callout');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Tip')]);

        final afterCalloutId = Editor.createNodeId();
        host.editor.execute([InsertNewlineAtCaretRequest(afterCalloutId)]);
        runSlashOption(host, afterCalloutId, 'code');
        host.editor.execute([const InsertPlainTextAtCaretRequest('print(1);')]);

        final afterCodeId = Editor.createNodeId();
        host.editor.execute([InsertNewlineAtCaretRequest(afterCodeId)]);
        runSlashOption(host, afterCodeId, 'divider');
        runSlashOption(host, afterCodeId, 'table');

        // Tap Back
        await tester.tap(find.byTooltip('Back'));
        await _pumpWait(tester, 500);

        expect(
          find.textContaining('Your changes could not be saved'),
          findsNothing,
        );
        expect(find.text('Home'), findsOneWidget);

        // Verify all blocks preserve hierarchy
        final savedRes = await blockRepo.getBlocksForPage(page.id);
        final savedBlocks = savedRes.valueOrNull ?? [];
        final convertedBlock =
            savedBlocks.firstWhere((b) => b.id == host.registry.blockIdForNode(bulletChildId), orElse: () => savedBlocks.first);
        final nestedMap =
            savedBlocks.where((b) => jsonDecode(b.data)['listType'] == 'toggle').toList();
        expect(nestedMap.length, 2);
        // Second toggle must still have Outer as parentBlockId!
        expect(nestedMap.any((b) => b.parentBlockId != null), isTrue);
        expect(convertedBlock.type, 'list');
      },
    );

    testWidgets(
      'rapid editing, toggle expand/collapse, title edit, and immediate back navigation',
      (tester) async {
        final now = DateTime.now().toUtc();
        final page = Page(
          id: 'repro-rapid-multi',
          title: 'Initial',
          createdAt: now,
          updatedAt: now,
        );
        final (_, host) = await pumpEditorForPage(tester, page);

        // Edit page title
        await tester.enterText(find.byType(TextField).first, 'Meghalaya Trip');

        final nodeId = host.document.first.id;
        host.editor.execute([
          ChangeSelectionRequest(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: nodeId,
                nodePosition: const TextNodePosition(offset: 0),
              ),
            ),
            SelectionChangeType.placeCaret,
            SelectionReason.userInteraction,
          ),
        ]);
        runSlashOption(host, nodeId, 'toggle');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Day 1')]);

        final c1 = Editor.createNodeId();
        host.editor.execute([InsertNewlineAtCaretRequest(c1)]);
        host.editor.execute([const InsertPlainTextAtCaretRequest('Shillong')]);

        // Collapse, expand, collapse immediately without waiting debounce
        host.editor.execute([ToggleExpandedRequest(nodeId: nodeId, isExpanded: false)]);
        host.editor.execute([ToggleExpandedRequest(nodeId: nodeId, isExpanded: true)]);
        host.editor.execute([ToggleExpandedRequest(nodeId: nodeId, isExpanded: false)]);

        // Undo then redo
        host.historyController.undo();
        await _pumpWait(tester, 50);
        host.historyController.redo();
        await _pumpWait(tester, 50);

        await tester.tap(find.byTooltip('Back'));
        await _pumpWait(tester, 500);

        expect(
          find.textContaining('Your changes could not be saved'),
          findsNothing,
        );
        expect(find.text('Home'), findsOneWidget);
      },
    );

    testWidgets(
      'debounced edits, toggle inside toggle via UI chevron, exit toggle empty enter, reopen and edit',
      (tester) async {
        final now = DateTime.now().toUtc();
        final page = Page(
          id: 'repro-debounced-ui',
          title: 'Meghalaya',
          createdAt: now,
          updatedAt: now,
        );
        final (router, host) = await pumpEditorForPage(tester, page);

        final node0 = host.document.first.id;
        host.editor.execute([
          ChangeSelectionRequest(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: node0,
                nodePosition: const TextNodePosition(offset: 0),
              ),
            ),
            SelectionChangeType.placeCaret,
            SelectionReason.userInteraction,
          ),
        ]);

        // Create Food toggle and pause > 350ms so debounce fires
        runSlashOption(host, node0, 'toggle');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Food')]);
        await _pumpWait(tester, 400);

        // Press Enter -> child 1 inside Food, convert to inner toggle
        final innerId = Editor.createNodeId();
        host.editor.execute([InsertNewlineAtCaretRequest(innerId)]);
        await _pumpWait(tester, 400);
        runSlashOption(host, innerId, 'toggle');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Veg')]);
        await _pumpWait(tester, 400);

        // Enter inside inner toggle -> grandchild
        final gcId = Editor.createNodeId();
        host.editor.execute([InsertNewlineAtCaretRequest(gcId)]);
        host.editor.execute([const InsertPlainTextAtCaretRequest('Jadoh')]);
        await _pumpWait(tester, 400);

        // Press Enter to create empty line inside inner toggle, then Enter again to exit inner toggle
        final exit1 = Editor.createNodeId();
        host.editor.execute([InsertNewlineAtCaretRequest(exit1)]);
        await _pumpWait(tester, 100);
        final exit2 = Editor.createNodeId();
        host.editor.execute([InsertNewlineAtCaretRequest(exit2)]);
        await _pumpWait(tester, 400);

        // Exit outer toggle on empty line, convert to Clothes toggle
        final exitOuter = Editor.createNodeId();
        host.editor.execute([InsertNewlineAtCaretRequest(exitOuter)]);
        await _pumpWait(tester, 100);
        final clothesNode = host.document.last;
        host.editor.execute([
          ChangeSelectionRequest(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: clothesNode.id,
                nodePosition: const TextNodePosition(offset: 0),
              ),
            ),
            SelectionChangeType.placeCaret,
            SelectionReason.userInteraction,
          ),
        ]);
        runSlashOption(host, clothesNode.id, 'toggle');
        host.editor.execute([const InsertPlainTextAtCaretRequest('Clothes')]);
        await _pumpWait(tester, 100);

        final jacket = Editor.createNodeId();
        host.editor.execute([InsertNewlineAtCaretRequest(jacket)]);
        host.editor.execute([const InsertPlainTextAtCaretRequest('Warm coat')]);
        await _pumpWait(tester, 400);

        // Collapse Clothes then Food using ToggleExpandedRequest
        host.editor.execute([
          ToggleExpandedRequest(nodeId: clothesNode.id, isExpanded: false),
        ]);
        await _pumpWait(tester, 100);
        host.editor.execute([
          ToggleExpandedRequest(nodeId: node0, isExpanded: false),
        ]);
        await _pumpWait(tester, 100);

        // Tap Back
        await tester.tap(find.byTooltip('Back'));
        await _pumpWait(tester, 500);
        expect(
          find.textContaining('Your changes could not be saved'),
          findsNothing,
        );
        expect(find.text('Home'), findsOneWidget);

        // Reopen the saved note and expand + edit + collapse + tap Back
        unawaited(router.push('/editor/${page.id}'));
        await _pumpWait(tester, 300);
        await _pumpUntilInitialized(tester);
        final host2 =
            tester.state<SuperEditorHostState>(find.byType(SuperEditorHost));
        expect(host2.document.length, greaterThanOrEqualTo(2));

        // Expand both toggles, edit, collapse both, and exit
        final food2 = host2.document.first;
        host2.editor.execute([
          ToggleExpandedRequest(nodeId: food2.id, isExpanded: true),
        ]);
        await _pumpWait(tester, 100);
        host2.editor.execute([
          ToggleExpandedRequest(nodeId: food2.id, isExpanded: false),
        ]);
        await _pumpWait(tester, 100);

        await tester.tap(find.byTooltip('Back'));
        await _pumpWait(tester, 500);
        expect(
          find.textContaining('Your changes could not be saved'),
          findsNothing,
        );
        expect(find.text('Home'), findsOneWidget);
      },
    );

    testWidgets(
      'all slash block conversions, Tab/Shift+Tab indent, Backspace merge, and back save',
      (tester) async {
        final now = DateTime.now().toUtc();
        final page = Page(
          id: 'repro-all-blocks',
          title: 'All Blocks Save Test',
          createdAt: now,
          updatedAt: now,
        );
        final (router, host) = await pumpEditorForPage(tester, page);

        String placeCaretAtLast({bool atEnd = false}) {
          final node = host.document.last;
          final offset = atEnd && node is TextNode
              ? node.text.toPlainText().length
              : 0;
          host.editor.execute([
            ChangeSelectionRequest(
              DocumentSelection.collapsed(
                position: DocumentPosition(
                  nodeId: node.id,
                  nodePosition: node is TextNode
                      ? TextNodePosition(offset: offset)
                      : const UpstreamDownstreamNodePosition.downstream(),
                ),
              ),
              SelectionChangeType.placeCaret,
              SelectionReason.userInteraction,
            ),
          ]);
          return node.id;
        }

        Future<void> convertAndAdvance(String optionId, String content) async {
          final nodeId = placeCaretAtLast();
          runSlashOption(host, nodeId, optionId);
          host.editor.execute([InsertPlainTextAtCaretRequest(content)]);
          await _pumpWait(tester, 50);

          final newId = Editor.createNodeId();
          final currentNode = host.document.getNodeById(nodeId);
          if (currentNode is ListItemNode) {
            final endPos = TextNodePosition(
              offset: currentNode.text.toPlainText().length,
            );
            host.editor.execute([
              SplitListItemRequest(
                nodeId: nodeId,
                splitPosition: endPos,
                newNodeId: newId,
              ),
            ]);
            final splitNode = host.document.getNodeById(newId);
            if (splitNode is ListItemNode) {
              host.editor.execute([
                ConvertListItemToParagraphRequest(nodeId: newId),
              ]);
            }
          } else if (currentNode is TaskNode) {
            host.editor.execute([
              SplitExistingTaskRequest(
                existingNodeId: nodeId,
                splitOffset: currentNode.text.toPlainText().length,
                newNodeId: newId,
              ),
            ]);
            final splitNode = host.document.getNodeById(newId);
            if (splitNode is TaskNode) {
              host.editor.execute([
                ConvertTaskToParagraphRequest(nodeId: newId),
              ]);
            }
          } else if (currentNode is KetionCalloutNode) {
            host.editor.execute([
              SplitCalloutRequest(
                nodeId: nodeId,
                newNodeId: newId,
                splitOffset: currentNode.text.toPlainText().length,
              ),
            ]);
          } else {
            host.editor.execute([InsertNewlineAtCaretRequest(newId)]);
          }
          await _pumpWait(tester, 50);
        }

        await convertAndAdvance('h1', 'Heading One');
        await convertAndAdvance('h2', 'Heading Two');
        await convertAndAdvance('quote', 'Quoted thought');
        await convertAndAdvance('code', 'final x = 1;');
        await convertAndAdvance('callout', 'Remember this');
        await convertAndAdvance('bulleted_list', 'Bullet item');
        await convertAndAdvance('numbered_list', 'Numbered item');
        await convertAndAdvance('checklist', 'Task item');

        // Insert horizontal divider and table before trailing paragraph
        final beforeDividerId = placeCaretAtLast();
        runSlashOption(host, beforeDividerId, 'divider');
        await _pumpWait(tester, 50);

        final beforeTableId = placeCaretAtLast();
        runSlashOption(host, beforeTableId, 'table');
        await _pumpWait(tester, 50);

        // Create two paragraphs, test Indent -> Unindent -> Merge (Backspace)
        final alphaId = placeCaretAtLast();
        host.editor.execute([const InsertPlainTextAtCaretRequest('Alpha')]);
        final betaId = Editor.createNodeId();
        host.editor.execute([InsertNewlineAtCaretRequest(betaId)]);
        host.editor.execute([const InsertPlainTextAtCaretRequest('Beta')]);
        await _pumpWait(tester, 100);

        host.editor.execute([IndentParagraphRequest(betaId)]);
        await _pumpWait(tester, 50);
        host.editor.execute([UnIndentParagraphRequest(betaId)]);
        await _pumpWait(tester, 50);

        // Move caret to end of Alpha before combining Beta into Alpha
        host.editor.execute([
          ChangeSelectionRequest(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: alphaId,
                nodePosition: TextNodePosition(
                  offset: (host.document.getNodeById(alphaId) as TextNode)
                      .text
                      .toPlainText()
                      .length,
                ),
              ),
            ),
            SelectionChangeType.placeCaret,
            SelectionReason.userInteraction,
          ),
          CombineParagraphsRequest(
            firstNodeId: alphaId,
            secondNodeId: betaId,
          ),
        ]);
        await _pumpWait(tester, 400);

        await tester.tap(find.byTooltip('Back'));
        await _pumpWait(tester, 500);
        expect(
          find.textContaining('Your changes could not be saved'),
          findsNothing,
        );
        expect(find.text('Home'), findsOneWidget);

        unawaited(router.push('/editor/${page.id}'));
        await _pumpWait(tester, 300);
        await _pumpUntilInitialized(tester);
        final reopenedHost =
            tester.state<SuperEditorHostState>(find.byType(SuperEditorHost));
        expect(reopenedHost.document.length, greaterThanOrEqualTo(10));

        await tester.tap(find.byTooltip('Back'));
        await _pumpWait(tester, 500);
        expect(
          find.textContaining('Your changes could not be saved'),
          findsNothing,
        );
      },
    );
  });
}
