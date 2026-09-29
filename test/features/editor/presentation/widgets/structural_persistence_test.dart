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
  Future<Result<void>> deleteBlock(String id, {required int expectedVersion}) async {
    testBlocks.removeWhere((b) => b.id == id);
    return const Success(null);
  }

  @override
  Future<Result<Block>> getBlock(String id) async {
    final block = testBlocks.firstWhere((b) => b.id == id, orElse: () => Block(
        id: id,
        pageId: 'page',
        type: 'text',
        position: 0,
        data: '{}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),);
    return Success(block);
  }

  Future<Result<List<Block>>> getPageBlocks(String pageId) async => Success(testBlocks);

  @override
  Future<Result<List<Block>>> getBlocksForPage(String pageId) async => Success(testBlocks);

  @override
  Future<Result<List<Block>>> getChildBlocks(String parentBlockId) async {
    return Success(testBlocks.where((b) => b.parentBlockId == parentBlockId && !b.deleted).toList());
  }

  @override
  Future<Result<void>> updateBlock(Block block, {required int expectedVersion}) async {
    final index = testBlocks.indexWhere((b) => b.id == block.id);
    if (index != -1) {
      testBlocks[index] = block;
    }
    return const Success(null);
  }

  @override
  Future<Result<List<Block>>> moveBlock(String sourceBlockId, DropIntent intent) async {
    final updatedBlocks = BlockTreeService.moveBlock(sourceBlockId, intent, testBlocks);
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

  Future<Result<void>> deleteBlocks(List<String> ids) async => const Success(null);

  Future<Result<void>> hardDeleteBlock(String id) async => const Success(null);

  @override
  Future<Result<void>> restoreBlock(String id, String data, String? parentBlockId, double position) async => const Success(null);
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
  Future<Result<void>> updateBlock(Block block, {required int expectedVersion}) async {
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
  Future<Result<void>> deleteBlock(String id, {required int expectedVersion}) async {
    calls.add('deleteBlock:$id');
    return super.deleteBlock(id, expectedVersion: expectedVersion);
  }
}

Future<void> pumpUntilInitialized(WidgetTester tester) async {
  int attempts = 0;
  while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty && attempts < 50) {
    await tester.pump(const Duration(milliseconds: 50));
    attempts++;
  }
  if (attempts >= 50) {
    throw Exception('pumpUntilInitialized timed out waiting for CircularProgressIndicator to disappear');
  }
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  const pageId = 'test-page';

  String textData(String text) => jsonEncode({
    'spans': [{
      'text': text, 
      'bold': false, 
      'italic': false, 
      'underline': false, 
      'strikethrough': false, 
      'code': false,
      'link': null,
      'pageLink': null,
      'pageLinkTitle': null,
    }],
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
        getPageBlocksUseCaseProvider.overrideWithValue(MockGetPageBlocksUseCase(blocks)),
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

    testWidgets('Single unowned NodeInsertedEvent creates InsertBlockMutation (not update)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-init', 'Initial Block', position: 100.0);
      await tester.pumpWidget(buildTestAppWithSpy(
        blocks: [block],
        testPage: testPage,
        spy: spyRepo,
      ),);
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
      
      final createdCalls = spyRepo.calls.where((c) => c.startsWith('createBlock:')).toList();
      final updateCalls = spyRepo.calls.where((c) => c.startsWith('updateBlock:')).toList();
      
      // Crucial part: it MUST create a block (InsertBlockMutation), not update.
      expect(createdCalls.length, 1, reason: 'Unowned insertion should create a block via InsertBlockMutation');
      expect(updateCalls.length, 0, reason: 'Unowned insertion should not trigger an updateBlock for the new block');

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Multi-node insertion (paste) preserving document order/positions', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-init', 'Initial Block', position: 100.0);
      await tester.pumpWidget(buildTestAppWithSpy(
        blocks: [block],
        testPage: testPage,
        spy: spyRepo,
      ),);
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
          newNode: ParagraphNode(id: pasteNode1Id, text: AttributedText('Paste 1')),
        ),
        InsertNodeAtIndexRequest(
          nodeIndex: 2,
          newNode: ParagraphNode(id: pasteNode2Id, text: AttributedText('Paste 2')),
        ),
        InsertNodeAtIndexRequest(
          nodeIndex: 3,
          newNode: ParagraphNode(id: pasteNode3Id, text: AttributedText('Paste 3')),
        ),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      
      expect(testBlocks.length, 4);
      
      final createdCalls = spyRepo.calls.where((c) => c.startsWith('createBlock:')).toList();
      expect(createdCalls.length, 3, reason: 'Three blocks should have been created');

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

    testWidgets('Checklist persistence verification after reopen', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-checklist-test', 'Original Text');
      await tester.pumpWidget(buildTestAppWithSpy(
        blocks: [block],
        testPage: testPage,
        spy: spyRepo,
      ),);
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
      await tester.pumpWidget(buildTestAppWithSpy(
        blocks: [blockToReopen],
        testPage: testPage,
        spy: spyRepo,
      ),);
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
  });
}
