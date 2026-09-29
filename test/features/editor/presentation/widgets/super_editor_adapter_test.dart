import 'dart:convert';
import 'package:flutter/foundation.dart';
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
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';
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
  Future<Result<void>> deleteBlock(String id) async {
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
  Future<Result<Block>> updateBlock(Block block) async {
    final index = testBlocks.indexWhere((b) => b.id == block.id);
    if (index != -1) {
      testBlocks[index] = block;
    }
    return Success(block);
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
    required String deletedBlockId,
  }) async {
    final index = testBlocks.indexWhere((b) => b.id == mergedBlock.id);
    if (index != -1) {
      testBlocks[index] = mergedBlock;
    }
    testBlocks.removeWhere((b) => b.id == deletedBlockId);
    return const Success(null);
  }
}

void main() {
  const pageId = 'test-page';

  String textData(String text) => jsonEncode({
    'spans': [{'text': text, 'bold': false, 'italic': false, 'underline': false, 'strikethrough': false, 'code': false}],
    'headingLevel': 0,
  });

  Widget buildTestApp({
    required List<Block> blocks,
    required page_entity.Page testPage,
  }) {
    return ProviderScope(
      overrides: [
        pageProvider(pageId).overrideWith((ref) => testPage),
        blockRepositoryProvider.overrideWithValue(DummyBlockRepository()),
        getPageBlocksUseCaseProvider.overrideWithValue(MockGetPageBlocksUseCase(blocks)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SuperEditorHost(
            pageId: pageId,
            onTitleChanged: (title) async => const Success(null),
            onIconChanged: (icon) async => const Success(null),
          ),
        ),
      ),
    );
  }

  group('KetionSuperEditorAdapter Undo/Redo validation', () {
    testWidgets('Validate standard edit round-trip and semantic equality without data loss', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block1 = Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        position: 0,
        data: textData('Initial Text'),
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
      await tester.pumpAndSettle();

      // Wait for provider to load and adapter to initialize
      final element = tester.element(find.byType(SuperEditorHost));
      final container = ProviderScope.containerOf(element);
      
      // Get initial state
      final initialBlocks = container.read(editorStateProvider(pageId)).value ?? [];
      expect(initialBlocks.length, 1);
      
      // Initial text is 'Initial Text'
      final initialData = jsonDecode(initialBlocks.first.data) as Map<String, dynamic>;
      final initialSpans = initialData['spans'] as List<dynamic>;
      expect(initialSpans.first['text'], 'Initial Text');

      // Find SuperEditor
      final superEditorFinder = find.byType(SuperEditor);
      expect(superEditorFinder, findsOneWidget);

      // Type some new text
      await tester.tap(superEditorFinder);
      await tester.pumpAndSettle();
      
      final state = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final document = state.document as MutableDocument;
      final editor = state.editor as Editor;
      final nodeId = document.first.id;

      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: nodeId,
            nodePosition: const TextNodePosition(offset: 12),
          ),
          textToInsert: ' and Edited Text',
          attributions: {},
        ),
      ]);

      await tester.pump(const Duration(milliseconds: 500)); // wait for debounce

      // Verify the block state changed
      final editedBlocks = container.read(editorStateProvider(pageId)).value ?? [];
      expect(editedBlocks.length, 1);
      final editedData = jsonDecode(editedBlocks.first.data) as Map<String, dynamic>;
      final editedSpans = editedData['spans'] as List<dynamic>;
      expect(editedSpans.first['text'], 'Initial Text and Edited Text');

      // Now Undo
      editor.undo();
      await tester.pump(const Duration(milliseconds: 500)); // wait for debounce

      // Verify the block state is back to initial
      final undoneBlocks = container.read(editorStateProvider(pageId)).value ?? [];
      for (final b in undoneBlocks) {
         debugPrint("Block ID: ${b.id}, text: ${jsonDecode(b.data)['spans']}");
      }
      expect(undoneBlocks.length, 1);
      final undoneData = jsonDecode(undoneBlocks.first.data) as Map<String, dynamic>;
      final undoneSpans = undoneData['spans'] as List<dynamic>;
      expect(undoneSpans.first['text'], 'Initial Text');
      
      // Validate semantic equality of initial vs undone state
      expect(undoneBlocks.first.id, initialBlocks.first.id);
      expect(undoneBlocks.first.type, initialBlocks.first.type);
      expect(undoneSpans, initialSpans); // data is identical

      // Now Redo
      editor.redo();
      await tester.pump(const Duration(milliseconds: 500)); // wait for debounce

      // Verify the block state is back to edited
      final redoneBlocks = container.read(editorStateProvider(pageId)).value ?? [];
      expect(redoneBlocks.length, 1);
      final redoneData = jsonDecode(redoneBlocks.first.data) as Map<String, dynamic>;
      final redoneSpans = redoneData['spans'] as List<dynamic>;
      expect(redoneSpans.first['text'], 'Initial Text and Edited Text');
      
      // Validate semantic equality of edited vs redone state
      expect(redoneBlocks.first.id, editedBlocks.first.id);
      expect(redoneBlocks.first.type, editedBlocks.first.type);
      expect(redoneSpans, editedSpans); // data is identical

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('KetionSuperEditorAdapter Structural edits', () {
    testWidgets('Validate node insertion, deletion and block mapping', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block1 = Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        position: 0,
        data: textData('Initial Text'),
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
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(SuperEditorHost));
      final container = ProviderScope.containerOf(element);
      
      final superEditorFinder = find.byType(SuperEditor);
      await tester.tap(superEditorFinder);
      await tester.pumpAndSettle();
      
      final state = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final document = state.document as MutableDocument;
      final editor = state.editor as Editor;
      
      final initialNodeId = document.first.id;

      // 1. Test Node Insertion
      final newNodeId = Editor.createNodeId();
      editor.execute([
        InsertNodeAfterNodeRequest(
          existingNodeId: initialNodeId,
          newNode: ParagraphNode(
            id: newNodeId,
            text: AttributedText('New Block Text'),
          ),
        ),
      ]);

      await tester.pump(const Duration(milliseconds: 500));

      final blocksAfterInsert = container.read(editorStateProvider(pageId)).value ?? [];
      expect(blocksAfterInsert.length, 2);
      
      final insertedData = jsonDecode(blocksAfterInsert[1].data) as Map<String, dynamic>;
      final insertedSpans = insertedData['spans'] as List<dynamic>;
      expect(insertedSpans.first['text'], 'New Block Text');
      expect(blocksAfterInsert[1].type, 'text');

      // 2. Test List Conversion (Checklist)
      // Super Editor's way of converting to a task node usually involves replacing the node.
      // But we can just test if creating a TaskNode maps correctly.
      final taskNodeId = Editor.createNodeId();
      editor.execute([
        InsertNodeAfterNodeRequest(
          existingNodeId: newNodeId,
          newNode: TaskNode(
            id: taskNodeId,
            text: AttributedText('Task Text'),
            isComplete: true,
          ),
        ),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      
      final blocksAfterTask = container.read(editorStateProvider(pageId)).value ?? [];
      expect(blocksAfterTask.length, 3);
      expect(blocksAfterTask[2].type, 'list');
      
      final taskData = jsonDecode(blocksAfterTask[2].data) as Map<String, dynamic>;
      expect(taskData['listType'], 'checklist');
      expect(taskData['checked'], true);
      expect((taskData['spans'] as List).first['text'], 'Task Text');

      // 3. Test Node Deletion
      editor.execute([
        DeleteNodeRequest(nodeId: newNodeId),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      
      final blocksAfterDelete = container.read(editorStateProvider(pageId)).value ?? [];
      expect(blocksAfterDelete.length, 2);
      // The task block should now be the second block
      expect(blocksAfterDelete[1].type, 'list');

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
