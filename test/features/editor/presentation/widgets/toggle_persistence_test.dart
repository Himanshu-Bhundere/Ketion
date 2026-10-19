import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';

import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/blocks/domain/usecases/get_page_blocks_usecase.dart';
import 'package:ketion/features/blocks/domain/repositories/block_repository.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/editor/domain/models/drop_intent.dart';
import 'package:ketion/features/editor/presentation/widgets/editor_history_controller.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_host.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as page_entity;
import 'package:ketion/features/pages/domain/repositories/page_repository.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';

import 'package:flutter/services.dart';
import 'package:ketion/features/editor/presentation/widgets/slash_command_menu.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_slash_command.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_slash_command_registry.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_edit_requests.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_toggle_keyboard_actions.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';

List<Block> testBlocks = [];

class MockGetPageBlocksUseCase implements GetPageBlocksUseCase {
  MockGetPageBlocksUseCase(List<Block> initialBlocks) {
    testBlocks = initialBlocks;
  }
  @override
  Future<Result<List<Block>>> call(String pageId) async {
    return Success(testBlocks);
  }
}

class _MockPageRepo implements PageRepository {
  final page_entity.Page page;
  _MockPageRepo(this.page);

  @override
  Future<Result<page_entity.Page>> getPage(String id) async => Success(page);
  @override
  Future<Result<page_entity.Page>> createPage(page_entity.Page newPage,
          {String initialBlockType = 'text',}) async =>
      Success(page);
  @override
  Future<Result<void>> deletePage(String id) async => const Success(null);
  Future<Result<List<page_entity.Page>>> getPages() async => Success([page]);
  @override
  Future<Result<page_entity.Page>> updatePage(
    page_entity.Page updatedPage,
  ) async =>
      Success(updatedPage);
  @override
  Future<Result<List<page_entity.Page>>> getChildPages(String parentId) async =>
      const Success([]);
  @override
  Future<Result<List<page_entity.Page>>> getFavoritePages() async =>
      const Success([]);
  @override
  Future<Result<List<page_entity.Page>>> getRecentPages() async =>
      const Success([]);
  @override
  Future<Result<List<page_entity.Page>>> getTemplatePages() async =>
      const Success([]);
}

class DummyBlockRepository implements BlockRepository {
  @override
  Future<Result<Block>> createBlock(Block block) async {
    testBlocks.add(block);
    return Success(block);
  }

  @override
  Future<Result<void>> deleteBlock(
    String id, {
    required int expectedVersion,
  }) async {
    testBlocks.removeWhere((b) => b.id == id);
    return const Success(null);
  }

  @override
  Future<Result<Block>> getBlock(String id) async {
    final block = testBlocks.firstWhere((b) => b.id == id);
    return Success(block);
  }

  Future<Result<List<Block>>> getPageBlocks(String pageId) async =>
      Success(testBlocks);
  @override
  Future<Result<List<Block>>> getBlocksForPage(String pageId) async =>
      Success(testBlocks);
  @override
  Future<Result<List<Block>>> getChildBlocks(String parentBlockId) async {
    return Success(
      testBlocks
          .where((b) => b.parentBlockId == parentBlockId && !b.deleted)
          .toList(),
    );
  }

  @override
  Future<Result<void>> updateBlock(
    Block block, {
    required int expectedVersion,
  }) async {
    final index = testBlocks.indexWhere((b) => b.id == block.id);
    if (index != -1) {
      testBlocks[index] = block;
    }
    return const Success(null);
  }

  @override
  Future<Result<List<Block>>> moveBlock(
    String sourceBlockId,
    DropIntent intent,
  ) async {
    return const Success([]);
  }

  @override
  Future<Result<void>> splitBlock({
    required Block updatedOriginalBlock,
    required int originalExpectedVersion,
    required Block newBlock,
  }) async {
    testBlocks.add(newBlock);
    return const Success(null);
  }

  @override
  Future<Result<void>> mergeBlocks({
    required Block mergedBlock,
    required int survivorExpectedVersion,
    required String deletedBlockId,
    required int victimExpectedVersion,
  }) async {
    testBlocks.removeWhere((b) => b.id == deletedBlockId);
    return const Success(null);
  }

  Future<Result<void>> updateBlocks(List<Block> blocks) async {
    for (final block in blocks) {
      final index = testBlocks.indexWhere((b) => b.id == block.id);
      if (index != -1) {
        testBlocks[index] = block;
      }
    }
    return const Success(null);
  }

  Future<Result<void>> deleteBlocks(List<String> ids) async =>
      const Success(null);
  Future<Result<void>> hardDeleteBlock(String id) async => const Success(null);
  @override
  Future<Result<void>> restoreBlock(
    String id,
    String data,
    String? parentBlockId,
    double position,
  ) async {
    testBlocks.add(
      Block(
        id: id,
        pageId: 'test-page',
        type: 'text',
        data: data,
        parentBlockId: parentBlockId,
        position: position,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
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

void main() {
  const pageId = 'test-page';

  Widget buildTestApp({
    required List<Block> blocks,
    required page_entity.Page testPage,
  }) {
    return ProviderScope(
      overrides: [
        getPageBlocksUseCaseProvider
            .overrideWithValue(MockGetPageBlocksUseCase(blocks)),
        blockRepositoryProvider.overrideWithValue(DummyBlockRepository()),
        pageRepositoryProvider.overrideWithValue(_MockPageRepo(testPage)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, child) {
              ref.watch(editorHistoryControllerProvider(pageId));
              return SuperEditorHost(
                pageId: pageId,
                onTitleChanged: (title) async => const Success(null),
                onIconChanged: (icon) async => const Success(null),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('Toggle slash conversion roundtrip saves block type correctly',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final initialBlocks = [
        Block(
          id: 'b1',
          pageId: pageId,
          type: 'text',
          data: jsonEncode({
            'spans': [
              {'text': 'Test item'},
            ],
            'headingLevel': 0,
          }),
          position: 1000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester
          .pumpWidget(buildTestApp(blocks: initialBlocks, testPage: testPage));
      await pumpUntilInitialized(tester);

      final State state = tester.state(find.byType(SuperEditorHost));
      final dynamic hostState = state;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;
      final registry = hostState.registry;

      final firstNode = document.first as ParagraphNode;
      expect(registry.blockIdForNode(firstNode.id), 'b1');

      // Find the toggle option and execute
      final List<SlashCommandOption> options =
          hostState.getSlashOptionsForTesting('') as List<SlashCommandOption>;
      final toggleOption = options.firstWhere((o) => o.title == 'Toggle List');

      List<EditRequest> requests = [];
      if (toggleOption is KetionSlashCommand) {
        requests = toggleOption.getEditRequestsWithDoc(firstNode.id, document);
      } else if (toggleOption is SuperEditorSlashCommandOption) {
        requests = toggleOption.getEditRequests(firstNode.id);
      }
      editor.execute(requests);

      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final newNode = document.first;
      expect(newNode is ParagraphNode, isTrue);
      expect((newNode as ParagraphNode).metadata['blockType'],
          const NamedAttribution('toggle'),);
      expect(newNode.metadata['isExpanded'], true);

      // Verify SQLite block persistence (DummyBlockRepository)
      final updatedBlock = testBlocks.firstWhere((b) => b.id == 'b1');
      expect(updatedBlock.type,
          'list',); // Toggle is stored as 'list' with 'listType': 'toggle'

      final data = jsonDecode(updatedBlock.data);
      expect(data['listType'], 'toggle');
      expect(data['isExpanded'], true);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Toggle undo and redo correctness', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final initialBlocks = [
        Block(
          id: 'b1',
          pageId: pageId,
          type: 'text',
          data: jsonEncode({
            'spans': [
              {'text': 'Test item'},
            ],
            'headingLevel': 0,
          }),
          position: 1000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester
          .pumpWidget(buildTestApp(blocks: initialBlocks, testPage: testPage));
      await pumpUntilInitialized(tester);

      final State state = tester.state(find.byType(SuperEditorHost));
      final dynamic hostState = state;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;

      final firstNodeId = document.first.id;

      // Simulate convert to Toggle via slash command
      final List<SlashCommandOption> options =
          hostState.getSlashOptionsForTesting('') as List<SlashCommandOption>;
      final toggleOption = options.firstWhere((o) => o.title == 'Toggle List');

      List<EditRequest> requests = [];
      if (toggleOption is KetionSlashCommand) {
        requests = toggleOption.getEditRequestsWithDoc(firstNodeId, document);
      }
      editor.execute(requests);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect((document.first as ParagraphNode).metadata['blockType'],
          const NamedAttribution('toggle'),);

      // Undo
      final BuildContext context = tester.element(find.byType(SuperEditorHost));
      final container = ProviderScope.containerOf(context);
      final historyController =
          container.read(editorHistoryControllerProvider(pageId));

      historyController?.undo();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect((document.first as ParagraphNode).metadata['blockType'],
          isNot(const NamedAttribution('toggle')),);

      // Redo
      historyController?.redo();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect((document.first as ParagraphNode).metadata['blockType'],
          const NamedAttribution('toggle'),);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
      'Nested hierarchy: collapsing toggle hides descendants without deleting, expanding restores hierarchy',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final initialBlocks = [
        Block(
          id: 'toggle-1',
          pageId: pageId,
          type: 'list',
          data: jsonEncode({
            'listType': 'toggle',
            'isExpanded': true,
            'spans': [
              {'text': 'Parent Toggle'},
            ],
          }),
          position: 1000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Block(
          id: 'child-1',
          pageId: pageId,
          type: 'text',
          data: jsonEncode({
            'spans': [
              {'text': 'Child paragraph'},
            ],
            'headingLevel': 0,
          }),
          parentBlockId: 'toggle-1',
          position: 2000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Block(
          id: 'child-2',
          pageId: pageId,
          type: 'list',
          data: jsonEncode({
            'listType': 'bullet',
            'spans': [
              {'text': 'Child bullet'},
            ],
          }),
          parentBlockId: 'toggle-1',
          position: 3000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester
          .pumpWidget(buildTestApp(blocks: initialBlocks, testPage: testPage));
      await pumpUntilInitialized(tester);

      final State state = tester.state(find.byType(SuperEditorHost));
      final dynamic hostState = state;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;
      final adapter = hostState.adapter as KetionSuperEditorAdapter;

      // Verify 3 nodes present initially
      expect(document.nodeCount, 3);
      final toggleNode = document.getNodeAt(0) as ParagraphNode;
      expect(toggleNode.metadata['blockType'], const NamedAttribution('toggle'));
      expect(toggleNode.metadata['isExpanded'], true);

      final child1Node = document.getNodeAt(1)!;
      expect(child1Node.metadata['depth'], 1);
      expect(child1Node.metadata['parentBlockId'], 'toggle-1');

      final child2Node = document.getNodeAt(2)!;
      expect(child2Node.metadata['depth'], 1);
      expect(child2Node.metadata['parentBlockId'], 'toggle-1');

      // 1. Collapse toggle via ToggleExpandedRequest
      editor.execute([
        ToggleExpandedRequest(nodeId: toggleNode.id, isExpanded: false),
      ]);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      // In document, children are hidden
      expect(document.nodeCount, 1);
      expect(document.first.id, toggleNode.id);

      // In persisted testBlocks, children were NOT deleted
      expect(testBlocks.length, 3);
      expect(testBlocks.any((b) => b.id == 'child-1'), isTrue);
      expect(testBlocks.any((b) => b.id == 'child-2'), isTrue);

      // 2. Expand toggle restores descendants with same content and ordering
      editor.execute([
        ToggleExpandedRequest(nodeId: toggleNode.id, isExpanded: true),
      ]);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      expect(document.nodeCount, 3);
      expect(document.getNodeAt(1)!.id, child1Node.id);
      expect(
        (document.getNodeAt(1) as TextNode).text.toPlainText(),
        'Child paragraph',
      );
      expect(document.getNodeAt(2)!.id, child2Node.id);
      expect(
        (document.getNodeAt(2) as TextNode).text.toPlainText(),
        'Child bullet',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
      'Enter at end of toggle creates new child or focuses existing child',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final initialBlocks = [
        Block(
          id: 'toggle-alone',
          pageId: pageId,
          type: 'list',
          data: jsonEncode({
            'listType': 'toggle',
            'isExpanded': true,
            'spans': [
              {'text': 'Empty Toggle'},
            ],
          }),
          position: 1000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester
          .pumpWidget(buildTestApp(blocks: initialBlocks, testPage: testPage));
      await pumpUntilInitialized(tester);

      final State state = tester.state(find.byType(SuperEditorHost));
      final dynamic hostState = state;
      final editor = hostState.editor as Editor;
      final composer = hostState.composer as MutableDocumentComposer;
      final document = hostState.document as MutableDocument;
      final adapter = hostState.adapter as KetionSuperEditorAdapter;

      final toggleNode = document.first as ParagraphNode;

      // Place caret at end of toggle text
      editor.execute([
        ChangeSelectionRequest(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: toggleNode.id,
              nodePosition: TextNodePosition(offset: toggleNode.text.length),
            ),
          ),
          SelectionChangeType.placeCaret,
          SelectionReason.userInteraction,
        ),
      ]);

      final fakeContext = FakeSuperEditorContext(
        editor: editor,
        document: document,
        composer: composer,
        documentLayout: FakeDocumentLayout(),
      );

      // Simulate Enter key event at end of toggle
      const enterEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );

      final instruction = splitToggleWhenEnterPressed(
        editContext: fakeContext,
        keyEvent: enterEvent,
      );

      expect(instruction, ExecutionInstruction.haltExecution);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      // Now document should have 2 nodes: the toggle and the newly created child
      expect(document.nodeCount, 2);
      final firstChildNode = document.getNodeAt(1)!;
      expect(firstChildNode.metadata['depth'], 1);
      expect(firstChildNode.metadata['parentBlockId'], 'toggle-alone');
      expect(composer.selection?.extent.nodeId, firstChildNode.id);

      // Press Enter again at the end of the toggle - should insert another child node
      editor.execute([
        ChangeSelectionRequest(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: toggleNode.id,
              nodePosition: TextNodePosition(offset: toggleNode.text.length),
            ),
          ),
          SelectionChangeType.placeCaret,
          SelectionReason.userInteraction,
        ),
      ]);

      final secondInstruction = splitToggleWhenEnterPressed(
        editContext: fakeContext,
        keyEvent: enterEvent,
      );
      expect(secondInstruction, ExecutionInstruction.haltExecution);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      expect(document.nodeCount, 3);
      final secondChildNode = document.getNodeAt(2)!;
      expect(secondChildNode.metadata['depth'], 1);
      expect(secondChildNode.metadata['parentBlockId'], 'toggle-alone');
      expect(composer.selection?.extent.nodeId, secondChildNode.id);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

class FakeSuperEditorContext implements SuperEditorContext {
  @override
  final Editor editor;
  @override
  final Document document;
  @override
  final DocumentComposer composer;
  @override
  final DocumentLayout documentLayout;

  FakeSuperEditorContext({
    required this.editor,
    required this.document,
    required this.composer,
    required this.documentLayout,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeDocumentLayout implements DocumentLayout {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

