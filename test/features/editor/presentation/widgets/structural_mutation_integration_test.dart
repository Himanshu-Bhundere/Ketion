import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/presentation/providers/editor_state_provider.dart';
import 'package:ketion/features/blocks/domain/usecases/get_page_blocks_usecase.dart';
import 'package:ketion/features/blocks/domain/repositories/block_repository.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/editor/domain/models/drop_intent.dart';
import 'package:ketion/features/editor/presentation/widgets/editor_history_controller.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_host.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as page_entity;
import 'package:ketion/features/pages/domain/repositories/page_repository.dart';
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

class _MockPageRepo implements PageRepository {
  final page_entity.Page page;
  _MockPageRepo(this.page);
  
  @override
  Future<Result<page_entity.Page>> getPage(String id) async => Success(page);
  
  @override
  Future<Result<page_entity.Page>> createPage(page_entity.Page newPage) async => Success(page);
  
  @override
  Future<Result<void>> deletePage(String id) async => const Success(null);
  
  Future<Result<List<page_entity.Page>>> getPages() async => Success([page]);
  
  @override
  Future<Result<page_entity.Page>> updatePage(page_entity.Page updatedPage) async => Success(updatedPage);

  @override
  Future<Result<List<page_entity.Page>>> getChildPages(String parentId) async => const Success([]);

  @override
  Future<Result<List<page_entity.Page>>> getFavoritePages() async => const Success([]);

  @override
  Future<Result<List<page_entity.Page>>> getRecentPages() async => const Success([]);

  @override
  Future<Result<List<page_entity.Page>>> getTemplatePages() async => const Success([]);
}

// Dummy block repository
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

  Future<Result<void>> deleteBlocks(List<String> ids) async => const Success(null);

  Future<Result<void>> hardDeleteBlock(String id) async => const Success(null);

  @override
  Future<Result<void>> restoreBlock(String id, String data, String? parentBlockId, double position) async {
    testBlocks.add(Block(
      id: id,
      pageId: 'test-page-id', // Using the constant from main() wouldn't work here, but we can hardcode for test
      type: 'text',
      data: data,
      parentBlockId: parentBlockId,
      position: position,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),);
    // Re-sort the blocks based on position to simulate DB ordering
    testBlocks.sort((a, b) => a.position.compareTo(b.position));
    return const Success(null);
  }
}

String textData(String text) {
  return jsonEncode({
    'spans': [{'text': text}],
    'headingLevel': 0,
  });
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
  const String pageId = 'test-page-id';

  Widget buildTestApp({required List<Block> blocks, required page_entity.Page testPage}) {
    return ProviderScope(
      overrides: [
        getPageBlocksUseCaseProvider.overrideWithValue(MockGetPageBlocksUseCase(blocks)),
        blockRepositoryProvider.overrideWithValue(DummyBlockRepository()),
        pageRepositoryProvider.overrideWithValue(
          // Dummy page repo that just returns the testPage
          _MockPageRepo(testPage),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, child) {
              // Watch the provider to keep it alive during the test
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

  group('Ketion Structural Mutation Integration Tests', () {
    testWidgets('Split: K1 ID stable, K2 gets exactly one new UUID', (tester) async {
      final block1 = Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        position: 0,
        data: textData('Line 1'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test Page',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestApp(blocks: [block1], testPage: testPage));
      await pumpUntilInitialized(tester);

      final element = tester.element(find.byType(SuperEditorHost));
      final container = ProviderScope.containerOf(element);
      
      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;
      final registry = hostState.registry;

      final initialBlocks = container.read(editorStateProvider(pageId)).value ?? [];
      expect(initialBlocks.length, 1);
      
      final firstNode = document.first as TextNode;
      expect(registry.blockIdForNode(firstNode.id), 'block1');

      // Trigger split via EditRequest
      editor.execute([
        SplitParagraphRequest(
          nodeId: firstNode.id,
          splitPosition: const TextPosition(offset: 4), // "Line" | " 1"
          newNodeId: 'new-split-node',
          replicateExistingMetadata: false,
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 350));
      await pumpUntilInitialized(tester);

      // Flush persistence
      final adapter = hostState.adapter as KetionSuperEditorAdapter;
      await adapter.flushPendingChanges();

      final blocksAfterSplit = List<Block>.from(testBlocks);
      expect(blocksAfterSplit.length, 2);
      expect(blocksAfterSplit[0].id, 'block1', reason: 'K1 ID should be stable');
      expect(blocksAfterSplit[1].id, isNot('block1'), reason: 'K2 gets new UUID');
      
      expect(document.nodeCount, 2);
      final node1 = document.first as TextNode;
      final node2 = document.last as TextNode;
      expect(registry.blockIdForNode(node1.id), blocksAfterSplit[0].id);
      expect(registry.blockIdForNode(node2.id), blocksAfterSplit[1].id);
      expect(node1.text.toPlainText(), 'Line');
      expect(node2.text.toPlainText(), ' 1');
    });

    testWidgets('Delete: tombstone recorded, block deleted, Undo/Redo logic', (tester) async {
      final block1 = Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        position: 0,
        data: textData('Line 1'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final block2 = Block(
        id: 'block2',
        pageId: pageId,
        type: 'text',
        position: 1000,
        data: textData('Line 2'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test Page',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestApp(blocks: [block1, block2], testPage: testPage));
      await pumpUntilInitialized(tester);

      final element = tester.element(find.byType(SuperEditorHost));
      final container = ProviderScope.containerOf(element);
      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;
      final registry = hostState.registry;

      expect(document.nodeCount, 2);
      final node2 = document.last as TextNode;
      final node2Id = node2.id;
      
      expect(registry.blockIdForNode(node2Id), 'block2');

      // Trigger delete
      editor.execute([
        DeleteNodeRequest(nodeId: node2Id),
      ]);
      await tester.pump(const Duration(milliseconds: 350));
      await pumpUntilInitialized(tester);

      // Flush persistence
      final adapter = hostState.adapter as KetionSuperEditorAdapter;
      await adapter.flushPendingChanges();

      // Verify deletion and tombstone
      final blocksAfterDelete = List<Block>.from(testBlocks);
      expect(blocksAfterDelete.length, 1);
      expect(document.nodeCount, 1);
      expect(registry.hasTombstone(node2Id), isTrue);

      // Trigger Undo
      // Need to execute the undo command
      final historyController = container.read(editorHistoryControllerProvider(pageId));
      expect(historyController, isNotNull, reason: 'History controller should be initialized');
      historyController!.undo();
      await tester.pump(const Duration(milliseconds: 350));
      await pumpUntilInitialized(tester);

      await adapter.flushPendingChanges();

      // Verify restoration
      final blocksAfterUndo = List<Block>.from(testBlocks);
      expect(blocksAfterUndo.length, 2);
      expect(document.nodeCount, 2);
      
      final restoredNode2 = document.last as TextNode;
      expect(restoredNode2.id, node2Id);
      expect(registry.blockIdForNode(restoredNode2.id), 'block2', reason: 'Should restore from tombstone');
      expect(blocksAfterUndo.last.id, 'block2');

      // Trigger Redo
      final redoController = container.read(editorHistoryControllerProvider(pageId));
      redoController!.redo();
      await tester.pump(const Duration(milliseconds: 350));
      await pumpUntilInitialized(tester);

      await adapter.flushPendingChanges();

      // Verify deletion again
      final blocksAfterRedo = List<Block>.from(testBlocks);
      expect(blocksAfterRedo.length, 1);
      expect(document.nodeCount, 1);
      expect(registry.hasTombstone(node2Id), isTrue);
    });

    testWidgets('Merge: survivor ID stable, victim deleted + tombstoned', (tester) async {
      final block1 = Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        position: 0,
        data: textData('Line 1'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final block2 = Block(
        id: 'block2',
        pageId: pageId,
        type: 'text',
        position: 1,
        data: textData('Line 2'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test Page',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestApp(blocks: [block1, block2], testPage: testPage));
      await pumpUntilInitialized(tester);

      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;
      final registry = hostState.registry;

      final node1Id = document.first.id;
      final node2Id = document.last.id;

      // Execute a CombineParagraphsRequest
      editor.execute([
        CombineParagraphsRequest(firstNodeId: node1Id, secondNodeId: node2Id),
      ]);
      await tester.pump(const Duration(milliseconds: 350));
      await pumpUntilInitialized(tester);

      // Flush persistence
      final adapter = hostState.adapter as KetionSuperEditorAdapter;
      await adapter.flushPendingChanges();

      // Verify node2 is gone
      expect(document.nodeCount, 1);
      final survivingNode = document.first as TextNode;
      expect(survivingNode.id, node1Id);
      expect(survivingNode.text.toPlainText(), 'Line 1Line 2');
      
      // Verify registry mapping
      expect(registry.blockIdForNode(node1Id), 'block1');
      expect(registry.hasTombstone(node2Id), isTrue);

      final blocks = List<Block>.from(testBlocks);
      expect(blocks.length, 1);
      expect(blocks.first.id, 'block1');
    });

    testWidgets('Missing mapping prevents arbitrary execution', (tester) async {
      final block1 = Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        position: 0,
        data: textData('Line 1'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test Page',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestApp(blocks: [block1], testPage: testPage));
      await pumpUntilInitialized(tester);

      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;

      // Try to split a non-existent node
      editor.execute([
        SplitParagraphRequest(
          nodeId: 'ghost-node',
          splitPosition: const TextPosition(offset: 0),
          newNodeId: 'ghost-split',
          replicateExistingMetadata: false,
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 350));
      await pumpUntilInitialized(tester);

      // Should do nothing
      expect(document.nodeCount, 1);
      expect(document.first.id, isNot('ghost-node'));
      expect(document.first.id, isNot('ghost-split'));
    });

    testWidgets('Conversion to TaskNode preserves text and identity', (tester) async {
      final block1 = Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        position: 0,
        data: textData('Test Checkbox'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test Page',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestApp(blocks: [block1], testPage: testPage));
      await pumpUntilInitialized(tester);

      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = hostState.editor as Editor;
      final document = hostState.document as MutableDocument;

      final node1 = document.first as ParagraphNode;
      final node1Id = node1.id;
      
      expect(node1.text.toPlainText(), 'Test Checkbox');

      // 1. Convert Paragraph to Task
      editor.execute([
        ConvertParagraphToTaskRequest(nodeId: node1Id),
      ]);
      await tester.pump(const Duration(milliseconds: 350));
      await pumpUntilInitialized(tester);

      // Check A: Super Editor conversion result
      final convertedNode = document.first;
      expect(convertedNode, isA<TaskNode>());
      expect(convertedNode.id, node1Id, reason: 'ID must remain stable across conversion');
      final taskNode = convertedNode as TaskNode;
      expect(taskNode.text.toPlainText(), 'Test Checkbox', reason: 'Text MUST be preserved during conversion');

      // Check C: Ketion Persistence logic via the flush
      final adapter = hostState.adapter as KetionSuperEditorAdapter;
      await adapter.flushPendingChanges();

      final blocks = List<Block>.from(testBlocks);
      expect(blocks.length, 1);
      final persistedBlock = blocks.first;
      expect(persistedBlock.id, 'block1', reason: 'Ketion block ID should be preserved');
      
      final data = jsonDecode(persistedBlock.data);
      expect(data['listType'], 'checklist');
      final spans = data['spans'] as List;
      expect(spans.isNotEmpty, true);
      expect(spans[0]['text'], 'Test Checkbox', reason: 'Ketion persistence MUST save the text');
    });
  });
}
