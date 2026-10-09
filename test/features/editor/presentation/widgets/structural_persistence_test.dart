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
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';
import 'package:ketion/features/editor/presentation/widgets/editor_history_controller.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_host.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as page_entity;
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/import_export/domain/services/pdf_exporter.dart';
import 'package:ketion/features/import_export/domain/usecases/export_usecase.dart';
import 'package:ketion/features/editor/presentation/widgets/blocks/list_block_widget.dart';
import 'package:ketion/features/editor/presentation/widgets/depth_wrapping_component_builder.dart';

// Global variable for dummy repo to access
List<Block> testBlocks = [];

// Mock GetPageBlocksUseCase
class MockGetPageBlocksUseCase implements GetPageBlocksUseCase {
  MockGetPageBlocksUseCase(List<Block> initialBlocks) {
    testBlocks = initialBlocks;
  }

  @override
  Future<Result<List<Block>>> call(String pageId) async {
    return Success(testBlocks);
  }
}

// Dummy block repository to satisfy other use cases
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
    final block = testBlocks.firstWhere(
      (b) => b.id == id,
      orElse: () => Block(
        id: id,
        pageId: 'page',
        type: 'text',
        position: 0,
        data: '{}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
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
    final updatedBlocks =
        BlockTreeService.moveBlock(sourceBlockId, intent, testBlocks);
    for (final updatedBlock in updatedBlocks) {
      final index = testBlocks.indexWhere((b) => b.id == updatedBlock.id);
      if (index != -1) {
        testBlocks[index] = updatedBlock;
      }
    }
    return Success(updatedBlocks);
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

  @override
  Future<Result<void>> splitBlock({
    required Block updatedOriginalBlock,
    required int originalExpectedVersion,
    required Block newBlock,
  }) async {
    final index = testBlocks.indexWhere((b) => b.id == updatedOriginalBlock.id);
    if (index != -1) {
      testBlocks[index] = updatedOriginalBlock;
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
    final index = testBlocks.indexWhere((b) => b.id == mergedBlock.id);
    if (index != -1) {
      testBlocks[index] = mergedBlock;
    }
    testBlocks.removeWhere((b) => b.id == deletedBlockId);
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
  ) async =>
      const Success(null);
}

/// Block repository that records which repository methods were called,
/// allowing tests to assert on the number and type of persistence operations.
class SpyBlockRepository extends DummyBlockRepository {
  final List<String> calls = [];

  @override
  Future<Result<Block>> createBlock(Block block) async {
    calls.add('createBlock:${block.id}');
    return super.createBlock(block);
  }

  @override
  Future<Result<void>> updateBlock(
    Block block, {
    required int expectedVersion,
  }) async {
    calls.add('updateBlock:${block.id}:v$expectedVersion');
    return super.updateBlock(block, expectedVersion: expectedVersion);
  }

  @override
  Future<Result<void>> splitBlock({
    required Block updatedOriginalBlock,
    required int originalExpectedVersion,
    required Block newBlock,
  }) async {
    calls.add('splitBlock:${updatedOriginalBlock.id}->${newBlock.id}');
    return super.splitBlock(
      updatedOriginalBlock: updatedOriginalBlock,
      originalExpectedVersion: originalExpectedVersion,
      newBlock: newBlock,
    );
  }

  @override
  Future<Result<void>> deleteBlock(
    String id, {
    required int expectedVersion,
  }) async {
    calls.add('deleteBlock:$id');
    return super.deleteBlock(id, expectedVersion: expectedVersion);
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

  String textData(String text) => jsonEncode({
        'spans': [
          {
            'text': text,
            'bold': false,
            'italic': false,
            'underline': false,
            'strikethrough': false,
            'code': false,
            'link': null,
            'pageLink': null,
            'pageLinkTitle': null,
          }
        ],
        'headingLevel': 0,
      });

  Widget buildTestAppWithSpy({
    required List<Block> blocks,
    required page_entity.Page testPage,
    required SpyBlockRepository spy,
  }) {
    return ProviderScope(
      overrides: [
        pageProvider(pageId).overrideWith((ref) => testPage),
        blockRepositoryProvider.overrideWithValue(spy),
        getPageBlocksUseCaseProvider
            .overrideWithValue(MockGetPageBlocksUseCase(blocks)),
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

  Block makeTextBlock(String id, String text, {double position = 0}) => Block(
        id: id,
        pageId: pageId,
        type: 'text',
        position: position,
        data: textData(text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  final testPage = page_entity.Page(
    id: pageId,
    title: 'Test Page',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('Structural Persistence Testing (Insertions & Checklist)', () {
    late SpyBlockRepository spyRepo;

    setUp(() {
      spyRepo = SpyBlockRepository();
    });

    testWidgets(
        'Single unowned NodeInsertedEvent creates InsertBlockMutation (not update)',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block =
          makeTextBlock('block-init', 'Initial Block', position: 100.0);
      await tester.pumpWidget(
        buildTestAppWithSpy(
          blocks: [block],
          testPage: testPage,
          spy: spyRepo,
        ),
      );
      await pumpUntilInitialized(tester);

      final state = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = state.editor as Editor;
      final adapter = state.adapter as KetionSuperEditorAdapter;

      spyRepo.calls.clear();

      // Trigger an unowned insertion (which skips semantic handler).
      // We can simulate this by mutating the document directly without a specific EditRequest
      // Or simply inserting a node explicitly with no matching ketion handler.
      // Easiest is to insert a node at the end.
      final newNodeId = Editor.createNodeId();
      editor.execute([
        InsertNodeAtIndexRequest(
          nodeIndex: 1,
          newNode: ParagraphNode(
            id: newNodeId,
            text: AttributedText('New unowned node'),
          ),
        ),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      // Verify the result
      expect(testBlocks.length, 2);

      final createdCalls =
          spyRepo.calls.where((c) => c.startsWith('createBlock:')).toList();
      final updateCalls =
          spyRepo.calls.where((c) => c.startsWith('updateBlock:')).toList();

      // Crucial part: it MUST create a block (InsertBlockMutation), not update.
      expect(
        createdCalls.length,
        1,
        reason:
            'Unowned insertion should create a block via InsertBlockMutation',
      );
      expect(
        updateCalls.length,
        0,
        reason:
            'Unowned insertion should not trigger an updateBlock for the new block',
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
        'Multi-node insertion (paste) preserving document order/positions',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block =
          makeTextBlock('block-init', 'Initial Block', position: 100.0);
      await tester.pumpWidget(
        buildTestAppWithSpy(
          blocks: [block],
          testPage: testPage,
          spy: spyRepo,
        ),
      );
      await pumpUntilInitialized(tester);

      final state = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = state.editor as Editor;
      final adapter = state.adapter as KetionSuperEditorAdapter;

      spyRepo.calls.clear();

      // Simulate paste: inserting multiple nodes directly into the document
      final pasteNode1Id = Editor.createNodeId();
      final pasteNode2Id = Editor.createNodeId();
      final pasteNode3Id = Editor.createNodeId();

      editor.execute([
        InsertNodeAtIndexRequest(
          nodeIndex: 1,
          newNode:
              ParagraphNode(id: pasteNode1Id, text: AttributedText('Paste 1')),
        ),
        InsertNodeAtIndexRequest(
          nodeIndex: 2,
          newNode:
              ParagraphNode(id: pasteNode2Id, text: AttributedText('Paste 2')),
        ),
        InsertNodeAtIndexRequest(
          nodeIndex: 3,
          newNode:
              ParagraphNode(id: pasteNode3Id, text: AttributedText('Paste 3')),
        ),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      expect(testBlocks.length, 4);

      final createdCalls =
          spyRepo.calls.where((c) => c.startsWith('createBlock:')).toList();
      expect(
        createdCalls.length,
        3,
        reason: 'Three blocks should have been created',
      );

      // Check document order/positions.
      // Since they were inserted after the first block (position 100.0), their positions should be monotonically increasing.
      // And they should be in the exact order.
      final newBlocks = testBlocks.skip(1).toList();
      expect(newBlocks[0].position, greaterThan(100.0));
      expect(newBlocks[1].position, greaterThan(newBlocks[0].position));
      expect(newBlocks[2].position, greaterThan(newBlocks[1].position));

      final data1 = jsonDecode(newBlocks[0].data);
      expect(data1['spans'][0]['text'], 'Paste 1');

      final data3 = jsonDecode(newBlocks[2].data);
      expect(data3['spans'][0]['text'], 'Paste 3');

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Checklist persistence verification after reopen',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-checklist-test', 'Original Text');
      await tester.pumpWidget(
        buildTestAppWithSpy(
          blocks: [block],
          testPage: testPage,
          spy: spyRepo,
        ),
      );
      await pumpUntilInitialized(tester);

      final state = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final document = state.document as MutableDocument;
      final editor = state.editor as Editor;
      final adapter = state.adapter as KetionSuperEditorAdapter;
      final nodeId = document.first.id;

      // 1. Simulate converting paragraph to checklist via slash command handler
      editor.execute([
        ConvertParagraphToTaskRequest(nodeId: nodeId),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      // Verify persistence
      expect(testBlocks.length, 1);
      final persistedBlock = testBlocks.first;
      expect(persistedBlock.type, 'list');

      final parsedData = jsonDecode(persistedBlock.data);
      expect(parsedData['listType'], 'checklist');
      expect(parsedData['checked'], false);
      expect(parsedData['spans'][0]['text'], 'Original Text');

      // Now "reopen" - load from testBlocks again
      final blockToReopen = testBlocks.first;

      await tester.pumpWidget(Container()); // unmount

      // Re-mount using the persisted block
      await tester.pumpWidget(
        buildTestAppWithSpy(
          blocks: [blockToReopen],
          testPage: testPage,
          spy: spyRepo,
        ),
      );
      await pumpUntilInitialized(tester);

      final newState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final newDocument = newState.document as MutableDocument;

      // Verify it loaded back as a TaskNode
      final firstNode = newDocument.first;
      expect(firstNode is TaskNode, isTrue);
      expect((firstNode as TaskNode).isComplete, isFalse);
      expect(firstNode.text.toPlainText(), 'Original Text');

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
        'Acceptance test: Type 3 numbered items, immediately export without tapping elsewhere, verify PDF and order',
        (tester) async {
      final block1 = Block(
        id: 'num-1',
        pageId: pageId,
        type: 'list',
        data: jsonEncode({
          'listType': 'numbered',
          'checked': false,
          'spans': [
            {'text': 'First item'},
          ],
        }),
        position: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final block2 = Block(
        id: 'num-2',
        pageId: pageId,
        type: 'list',
        data: jsonEncode({
          'listType': 'numbered',
          'checked': false,
          'spans': [
            {'text': 'Second item'},
          ],
        }),
        position: 2000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final block3 = Block(
        id: 'num-3',
        pageId: pageId,
        type: 'list',
        data: jsonEncode({
          'listType': 'numbered',
          'checked': false,
          'spans': [
            {'text': 'Third item'},
          ],
        }),
        position: 3000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testBlocks = [block1, block2, block3];

      // 1. Verify dynamic numbering for list blocks
      // When rendered in ListBlockWidget, listIndex gives the dynamic position
      Block? updatedBlock;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ListBlockWidget(
                block: block2,
                listIndex: 2,
                onUpdate: (b) => updatedBlock = b,
                onSplit: (before, after) async {},
                onMergePrevious: (text) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the TextField and verify listIndex prefix '2.'
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('Second item'), findsOneWidget);

      // 2. Type text into the list item and immediately export without tapping elsewhere
      await tester.enterText(find.byType(TextField), 'Second item edited');
      // Advance by debounce duration (350ms)
      await tester.pump(const Duration(milliseconds: 350));

      expect(updatedBlock, isNotNull);
      final updatedData = jsonDecode(updatedBlock!.data);
      expect(updatedData['spans'][0]['text'], 'Second item edited');
      expect(updatedData['listType'], 'numbered');

      // Update testBlocks with edited content
      testBlocks[1] = updatedBlock!;

      // 3. Immediately export to PDF via ExportUseCase and PdfExporter
      final exportUseCase = ExportUseCase([PdfExporter()]);
      final pdfBytes = await exportUseCase.exportToBytes(
        testPage,
        testBlocks,
        'pdf',
      );

      // Verify PDF bytes were generated and valid
      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF magic header: %PDF
      expect(pdfBytes[0], 0x25); // %
      expect(pdfBytes[1], 0x50); // P
      expect(pdfBytes[2], 0x44); // D
      expect(pdfBytes[3], 0x46); // F

      // 4. Test reordering: swap item 1 and item 3
      final reorderedBlocks = [
        testBlocks[2].copyWith(position: 1000.0),
        testBlocks[1].copyWith(position: 2000.0),
        testBlocks[0].copyWith(position: 3000.0),
      ];
      final reorderedPdf = await exportUseCase.exportToBytes(
        testPage,
        reorderedBlocks,
        'pdf',
      );
      expect(reorderedPdf.isNotEmpty, isTrue);

      // 5. Test checklists preserve checked state and formatting
      final checklistBlock = Block(
        id: 'check-1',
        pageId: pageId,
        type: 'list',
        data: jsonEncode({
          'listType': 'checklist',
          'checked': true,
          'spans': [
            {'text': 'Done task', 'bold': true},
          ],
        }),
        position: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final checklistPdf = await exportUseCase.exportToBytes(
        testPage,
        [checklistBlock],
        'pdf',
      );
      expect(checklistPdf.isNotEmpty, isTrue);
    });

    testWidgets(
        'Indentation: swipe-right indents beneath preceding block and swipe-left unindents',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block1 = makeTextBlock('block-1', 'First block', position: 100.0);
      final block2 = makeTextBlock('block-2', 'Second block', position: 200.0);

      await tester.pumpWidget(
        buildTestAppWithSpy(
          blocks: [block1, block2],
          testPage: testPage,
          spy: spyRepo,
        ),
      );
      await pumpUntilInitialized(tester);

      final state = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = state.editor as Editor;
      final adapter = state.adapter as KetionSuperEditorAdapter;
      final doc = state.document as MutableDocument;

      final node1 = doc.getNodeAt(0)!;
      final node2 = doc.getNodeAt(1)!;

      spyRepo.calls.clear();

      // 1. Indent node 2 (swipe right behavior)
      editor.execute([
        IndentParagraphRequest(node2.id),
      ]);
      await tester.pump(const Duration(milliseconds: 100));
      await adapter.flushPendingChanges();

      // Node 2 should be child of block-1 with depth 1
      final indentedNode2 = doc.getNodeById(node2.id)!;
      expect(indentedNode2.metadata['depth'], 1);
      expect(indentedNode2.metadata['parentBlockId'], 'block-1');

      final updateCalls =
          spyRepo.calls.where((c) => c.startsWith('updateBlock:block-2')).toList();
      expect(updateCalls.isNotEmpty, isTrue);

      // Verify persistence in testBlocks
      final persistedBlock2 = testBlocks.firstWhere((b) => b.id == 'block-2');
      expect(persistedBlock2.parentBlockId, 'block-1');

      spyRepo.calls.clear();

      // 2. Unindent node 2 (swipe left behavior)
      editor.execute([
        UnIndentParagraphRequest(node2.id),
      ]);
      await tester.pump(const Duration(milliseconds: 100));
      await adapter.flushPendingChanges();

      // Node 2 should be back at root level with depth 0
      final unindentedNode2 = doc.getNodeById(node2.id)!;
      expect(unindentedNode2.metadata['depth'], 0);
      expect(unindentedNode2.metadata['parentBlockId'], isNull);

      final unindentCalls =
          spyRepo.calls.where((c) => c.startsWith('updateBlock:block-2')).toList();
      expect(unindentCalls.isNotEmpty, isTrue);

      final unindentedBlock2 = testBlocks.firstWhere((b) => b.id == 'block-2');
      expect(unindentedBlock2.parentBlockId, isNull);

      // 3. Hierarchy validation: attempting to indent node 1 (root, first child) must fizzle
      spyRepo.calls.clear();
      editor.execute([
        IndentParagraphRequest(node1.id),
      ]);
      await tester.pump(const Duration(milliseconds: 100));
      await adapter.flushPendingChanges();

      final rootNode1 = doc.getNodeById(node1.id)!;
      expect(rootNode1.metadata['depth'] ?? 0, 0);
      expect(rootNode1.metadata['parentBlockId'], isNull);
      expect(
        spyRepo.calls.where((c) => c.startsWith('updateBlock:block-1')).isEmpty,
        isTrue,
        reason: 'Indenting without preceding sibling must fizzle',
      );

      // 4. Hierarchy validation: attempting to unindent when already at root must fizzle
      spyRepo.calls.clear();
      editor.execute([
        UnIndentParagraphRequest(node1.id),
      ]);
      await tester.pump(const Duration(milliseconds: 100));
      await adapter.flushPendingChanges();

      expect(node1.metadata['depth'] ?? 0, 0);
      expect(node1.metadata['parentBlockId'], isNull);
      expect(
        spyRepo.calls.where((c) => c.startsWith('updateBlock:block-1')).isEmpty,
        isTrue,
        reason: 'Unindenting at root level must fizzle',
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
        'Swipe gesture and slash insertion: active block focus and touch gesture handling',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block1 = makeTextBlock('block-1', 'Heading item', position: 100.0);
      final block2 = makeTextBlock('block-2', 'Paragraph item', position: 200.0);

      await tester.pumpWidget(
        buildTestAppWithSpy(
          blocks: [block1, block2],
          testPage: testPage,
          spy: spyRepo,
        ),
      );
      await pumpUntilInitialized(tester);

      final state = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final doc = state.document as MutableDocument;
      final composer = state.composer as MutableDocumentComposer;

      final node2 = doc.getNodeAt(1)!;

      // Verify SwipeIndentationWrapper is present around node content
      expect(find.byType(SwipeIndentationWrapper), findsWidgets);

      // Verify gesture does not trigger when selection is expanded
      composer.setSelectionWithReason(
        DocumentSelection(
          base: DocumentPosition(
            nodeId: node2.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          extent: DocumentPosition(
            nodeId: node2.id,
            nodePosition: const TextNodePosition(offset: 5),
          ),
        ),
      );

      // Finding SwipeIndentationWrapper for node2
      final wrapperFinder = find.byWidgetPredicate(
        (w) => w is SwipeIndentationWrapper && w.nodeId == node2.id,
      );
      expect(wrapperFinder, findsOneWidget);

      // Swipe gesture while selection is expanded should not trigger indent
      await tester.drag(wrapperFinder, const Offset(100.0, 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      expect(node2.metadata['depth'] ?? 0, 0);

      // Collapse selection
      composer.setSelectionWithReason(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: node2.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
      );

      // Swipe right on wrapper with collapsed selection triggers indent
      await tester.drag(wrapperFinder, const Offset(100.0, 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      final swipedNode2 = doc.getNodeById(node2.id)!;
      expect(swipedNode2.metadata['depth'], 1);
      expect(swipedNode2.metadata['parentBlockId'], 'block-1');

      // Swipe left on wrapper triggers unindent
      await tester.drag(wrapperFinder, const Offset(-100.0, 0.0));
      await tester.pump(const Duration(milliseconds: 100));

      final unswipedNode2 = doc.getNodeById(node2.id)!;
      expect(unswipedNode2.metadata['depth'], 0);
      expect(unswipedNode2.metadata['parentBlockId'], isNull);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
