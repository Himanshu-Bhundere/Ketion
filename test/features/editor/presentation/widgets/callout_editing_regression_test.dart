import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_callout_node.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_callout_keyboard_actions.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as page_entity;
import 'package:ketion/features/pages/domain/repositories/page_repository.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';

List<Block> testBlocks = [];

class MockGetPageBlocksUseCase implements GetPageBlocksUseCase {
  MockGetPageBlocksUseCase(List<Block> initialBlocks) {
    testBlocks = List.from(initialBlocks);
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
  Future<Result<page_entity.Page>> createPage(
    page_entity.Page newPage, {
    String initialBlockType = 'text',
  }) async =>
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
  @override
  Future<Result<void>> restorePage(String id) async => const Success(null);
  @override
  Future<Result<void>> permanentlyDeletePage(String id) async =>
      const Success(null);
  @override
  Future<Result<void>> emptyTrash() async => const Success(null);
  @override
  Future<Result<List<page_entity.Page>>> getDeletedPages() async =>
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

  @override
  Future<Result<List<Block>>> getBlocksForPage(String pageId) async {
    final sorted = List<Block>.from(testBlocks)
      ..sort((a, b) => a.position.compareTo(b.position));
    return Success(sorted);
  }

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
  Future<Result<void>> splitBlock({
    required Block updatedOriginalBlock,
    required int originalExpectedVersion,
    required Block newBlock,
  }) async {
    final idx = testBlocks.indexWhere((b) => b.id == updatedOriginalBlock.id);
    if (idx != -1) {
      testBlocks[idx] = updatedOriginalBlock;
    }
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
    final idx = testBlocks.indexWhere((b) => b.id == mergedBlock.id);
    if (idx != -1) {
      testBlocks[idx] = mergedBlock;
    }
    return const Success(null);
  }

  @override
  Future<Result<List<Block>>> moveBlock(
    String sourceBlockId,
    DropIntent intent,
  ) async {
    return Success(testBlocks);
  }

  Future<Result<void>> updateBlockPositions(
    Map<String, double> positions,
  ) async {
    for (final entry in positions.entries) {
      final idx = testBlocks.indexWhere((b) => b.id == entry.key);
      if (idx != -1) {
        testBlocks[idx] = testBlocks[idx].copyWith(position: entry.value);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> restoreBlock(
    String id,
    String data,
    String? parentBlockId,
    double position,
  ) async {
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
    throw Exception('pumpUntilInitialized timed out');
  }
  await tester.pump(const Duration(milliseconds: 50));
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

void main() {
  const pageId = 'test-callout-page';

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

  group('Callout Editing & Typing Integrity Tests', () {
    testWidgets(
        'Typing at start, middle, and end preserves KetionCalloutNode type, icon, color, and id',
        (tester) async {
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Callout Integrity Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final initialBlocks = [
        Block(
          id: 'callout-1',
          pageId: pageId,
          type: 'callout',
          data: jsonEncode({
            'runtimeType': 'callout',
            'icon': '💡',
            'color': 'blue',
            'spans': [
              {'text': 'Initial callout text'},
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

      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;
      final adapter = hostState.adapter as KetionSuperEditorAdapter;

      expect(document.nodeCount, 1);
      final initialNode = document.getNodeAt(0) as KetionCalloutNode;
      final calloutNodeId = initialNode.id;
      expect(initialNode.icon, '💡');
      expect(initialNode.color, 'blue');
      expect(initialNode.text.toPlainText(), 'Initial callout text');

      // 1. Insert at beginning
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: calloutNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: 'PREFIX: ',
          attributions: {},
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 100));

      var currentNode = document.getNodeById(calloutNodeId);
      expect(currentNode, isA<KetionCalloutNode>());
      expect((currentNode as KetionCalloutNode).icon, '💡');
      expect(currentNode.color, 'blue');
      expect(currentNode.text.toPlainText(), startsWith('PREFIX: Initial'));

      // 2. Insert in middle
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: calloutNodeId,
            nodePosition: const TextNodePosition(offset: 8),
          ),
          textToInsert: '[MIDDLE] ',
          attributions: {},
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 100));

      currentNode = document.getNodeById(calloutNodeId);
      expect(currentNode, isA<KetionCalloutNode>());
      expect(
        (currentNode as KetionCalloutNode).text.toPlainText(),
        contains('[MIDDLE]'),
      );

      // 3. Insert at end
      final textLen = (currentNode).text.toPlainText().length;
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: calloutNodeId,
            nodePosition: TextNodePosition(offset: textLen),
          ),
          textToInsert: ' :SUFFIX',
          attributions: {},
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      currentNode = document.getNodeById(calloutNodeId);
      expect(currentNode, isA<KetionCalloutNode>());
      expect(
        (currentNode as KetionCalloutNode).text.toPlainText(),
        endsWith(':SUFFIX'),
      );
      expect(currentNode.icon, '💡');
      expect(currentNode.color, 'blue');

      // Verify persisted block retains callout type, icon, and updated text
      final persistedBlock = testBlocks.firstWhere((b) => b.id == 'callout-1');
      expect(persistedBlock.type, 'callout');
      final persistedData = jsonDecode(persistedBlock.data);
      expect(persistedData['runtimeType'], 'callout');
      expect(persistedData['icon'], '💡');
      expect(persistedData['color'], 'blue');
      expect(
        persistedData['spans'][0]['text'],
        (currentNode).text.toPlainText(),
      );
    });

    testWidgets('Deleting text preserves KetionCalloutNode type',
        (tester) async {
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Callout Deletion Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final initialBlocks = [
        Block(
          id: 'callout-del',
          pageId: pageId,
          type: 'callout',
          data: jsonEncode({
            'runtimeType': 'callout',
            'icon': '⚠️',
            'color': 'yellow',
            'spans': [
              {'text': 'DeleteSomeWordsHere'},
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

      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;
      final adapter = hostState.adapter as KetionSuperEditorAdapter;

      final calloutNodeId = document.first.id;

      editor.execute([
        DeleteContentRequest(
          documentRange: DocumentSelection(
            base: DocumentPosition(
              nodeId: calloutNodeId,
              nodePosition: const TextNodePosition(offset: 0),
            ),
            extent: DocumentPosition(
              nodeId: calloutNodeId,
              nodePosition: const TextNodePosition(offset: 6),
            ),
          ),
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      final node = document.getNodeById(calloutNodeId);
      expect(node, isA<KetionCalloutNode>());
      expect(
        (node as KetionCalloutNode).text.toPlainText(),
        'SomeWordsHere',
      );
      expect(node.icon, '⚠️');
      expect(node.color, 'yellow');
    });

    testWidgets(
        'Pressing Enter splits callout cleanly into callout and paragraph',
        (tester) async {
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Callout Split Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final initialBlocks = [
        Block(
          id: 'callout-split',
          pageId: pageId,
          type: 'callout',
          data: jsonEncode({
            'runtimeType': 'callout',
            'icon': '📌',
            'color': 'purple',
            'spans': [
              {'text': 'FirstPartSecondPart'},
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

      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;

      final calloutNodeId = document.first.id;
      final newParagraphId = Editor.createNodeId();

      editor.execute([
        SplitParagraphRequest(
          nodeId: calloutNodeId,
          splitPosition: const TextNodePosition(offset: 9),
          newNodeId: newParagraphId,
          replicateExistingMetadata: false,
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 500));

      expect(document.nodeCount, 2);

      // Node 1 must remain a KetionCalloutNode with the head text
      final firstNode = document.getNodeAt(0);
      expect(firstNode, isA<KetionCalloutNode>());
      expect((firstNode as KetionCalloutNode).text.toPlainText(), 'FirstPart');
      expect(firstNode.icon, '📌');
      expect(firstNode.color, 'purple');

      // Node 2 must be a normal ParagraphNode
      final secondNode = document.getNodeAt(1);
      expect(secondNode, isA<ParagraphNode>());
      expect(secondNode is KetionCalloutNode, isFalse);
      expect((secondNode as ParagraphNode).text.toPlainText(), 'SecondPart');
    });

    testWidgets(
        'Backspace at offset 0 halts execution without converting to paragraph',
        (tester) async {
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Backspace Guard Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final initialBlocks = [
        Block(
          id: 'callout-bs',
          pageId: pageId,
          type: 'callout',
          data: jsonEncode({
            'runtimeType': 'callout',
            'icon': '🛡️',
            'color': 'green',
            'spans': [
              {'text': 'Protected Callout'},
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

      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;
      final composer = hostState.composer as MutableDocumentComposer;

      final calloutNodeId = document.first.id;

      composer.setSelectionWithReason(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: calloutNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionReason.userInteraction,
      );

      final fakeContext = FakeSuperEditorContext(
        editor: editor,
        document: document,
        composer: composer,
        documentLayout: FakeDocumentLayout(),
      );

      const keyEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.backspace,
        logicalKey: LogicalKeyboardKey.backspace,
        timeStamp: Duration.zero,
      );

      final instruction = convertCalloutToParagraphWhenBackspacePressed(
        editContext: fakeContext,
        keyEvent: keyEvent,
      );

      expect(instruction, ExecutionInstruction.haltExecution);
      final node = document.getNodeById(calloutNodeId);
      expect(node, isA<KetionCalloutNode>());
      expect((node as KetionCalloutNode).icon, '🛡️');
      expect(node.color, 'green');
    });

    testWidgets('Undo/redo preserves KetionCalloutNode type and content',
        (tester) async {
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Callout Undo Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final initialBlocks = [
        Block(
          id: 'callout-undo',
          pageId: pageId,
          type: 'callout',
          data: jsonEncode({
            'runtimeType': 'callout',
            'icon': '🔄',
            'color': 'orange',
            'spans': [
              {'text': 'Original'},
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

      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;
      final historyController =
          hostState.historyController as EditorHistoryController;

      final calloutNodeId = document.first.id;

      // Edit callout
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: calloutNodeId,
            nodePosition: const TextNodePosition(offset: 8),
          ),
          textToInsert: ' Edit',
          attributions: {},
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        (document.getNodeById(calloutNodeId) as KetionCalloutNode)
            .text
            .toPlainText(),
        'Original Edit',
      );

      // Undo
      historyController.undo();
      await tester.pump(const Duration(milliseconds: 100));

      var node = document.getNodeById(calloutNodeId);
      expect(node, isA<KetionCalloutNode>());
      expect((node as KetionCalloutNode).text.toPlainText(), 'Original');
      expect(node.icon, '🔄');
      expect(node.color, 'orange');

      // Redo
      historyController.redo();
      await tester.pump(const Duration(milliseconds: 100));

      node = document.getNodeById(calloutNodeId);
      expect(node, isA<KetionCalloutNode>());
      expect((node as KetionCalloutNode).text.toPlainText(), 'Original Edit');
      expect(node.icon, '🔄');
      expect(node.color, 'orange');
    });

    testWidgets(
        'Save and reopen note preserves Callout type, exact text, icon, and color',
        (tester) async {
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Reopen Note Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final initialBlocks = [
        Block(
          id: 'callout-reopen',
          pageId: pageId,
          type: 'callout',
          data: jsonEncode({
            'runtimeType': 'callout',
            'icon': '🚀',
            'color': 'cyan',
            'spans': [
              {'text': 'Persistent Callout'},
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

      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = hostState.editor as Editor;
      final adapter = hostState.adapter as KetionSuperEditorAdapter;

      final calloutNodeId = (hostState.document as MutableDocument).first.id;

      // Type into the callout
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: calloutNodeId,
            nodePosition: const TextNodePosition(offset: 18),
          ),
          textToInsert: ' with extra content!',
          attributions: {},
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      // Clear the widget tree to simulate closing the note
      await tester.pumpWidget(const SizedBox());

      // Reopen the note using the saved testBlocks
      await tester
          .pumpWidget(buildTestApp(blocks: testBlocks, testPage: testPage));
      await pumpUntilInitialized(tester);

      final hostStateReopened =
          tester.state(find.byType(SuperEditorHost)) as dynamic;
      final documentReopened = hostStateReopened.document as MutableDocument;

      expect(documentReopened.nodeCount, 1);
      final reopenedNode = documentReopened.getNodeAt(0);
      expect(reopenedNode, isA<KetionCalloutNode>());
      final callout = reopenedNode as KetionCalloutNode;
      expect(
        callout.text.toPlainText(),
        'Persistent Callout with extra content!',
      );
      expect(callout.icon, '🚀');
      expect(callout.color, 'cyan');
    });
  });
}
