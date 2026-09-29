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
import 'package:ketion/features/editor/presentation/widgets/editor_history_controller.dart';
import 'package:ketion/features/editor/presentation/widgets/editor_identity_registry.dart';
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
      await pumpUntilInitialized(tester);

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
      await pumpUntilInitialized(tester);
      
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
      final adapter = state.adapter as KetionSuperEditorAdapter;
      await adapter.flushPendingChanges();

      final editedBlocks = List<Block>.from(testBlocks);
      expect(editedBlocks.length, 1);
      final editedData = jsonDecode(editedBlocks.first.data) as Map<String, dynamic>;
      final editedSpans = editedData['spans'] as List<dynamic>;
      expect(editedSpans.first['text'], 'Initial Text and Edited Text');

      // Now Undo
      container.read(editorHistoryControllerProvider(pageId))?.undo();
      await tester.pump(const Duration(milliseconds: 500)); // wait for debounce
      
      final textAfterUndo = (document.first as ParagraphNode).text.toPlainText();
      debugPrint('DOCUMENT TEXT AFTER UNDO: $textAfterUndo');

      // Verify the block state is back to initial
      await adapter.flushPendingChanges();

      final undoneBlocks = List<Block>.from(testBlocks);
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
      container.read(editorHistoryControllerProvider(pageId))?.redo();
      await tester.pump(const Duration(milliseconds: 500)); // wait for debounce

      // Verify the block state is back to edited
      await adapter.flushPendingChanges();

      final redoneBlocks = List<Block>.from(testBlocks);
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
      await pumpUntilInitialized(tester);


      final superEditorFinder = find.byType(SuperEditor);
      await tester.tap(superEditorFinder);
      await pumpUntilInitialized(tester);
      
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

      final adapter = state.adapter as KetionSuperEditorAdapter;
      await adapter.flushPendingChanges();

      final blocksAfterInsert = List<Block>.from(testBlocks);
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
      await adapter.flushPendingChanges();
      
      final blocksAfterTask = List<Block>.from(testBlocks);
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
      await adapter.flushPendingChanges();
      
      final blocksAfterDelete = List<Block>.from(testBlocks);
      expect(blocksAfterDelete.length, 2);
      // The task block should now be the second block
      expect(blocksAfterDelete[1].type, 'list');

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Slash conversion persistence regression', () {
    late SpyBlockRepository spyRepo;

    setUp(() {
      spyRepo = SpyBlockRepository();
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

    Block makeTextBlock(String id, String text, {int version = 1}) => Block(
      id: id,
      pageId: pageId,
      type: 'text',
      position: 0,
      data: textData(text),
      version: version,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testPage = page_entity.Page(
      id: pageId,
      title: 'Test Page',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // --- Test A: Slash to Bullet produces exactly one updateBlock (the ChangeBlockTypeMutation) ---
    testWidgets('A. Slash to bullet: exactly one persistence call', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-a', 'Hello');
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

      spyRepo.calls.clear();

      // Issue the same conversion request that the slash menu issues
      editor.execute([
        ConvertParagraphToListItemRequest(nodeId: nodeId, type: ListItemType.unordered),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      // The ChangeBlockTypeMutation flows through updateBlock.
      // The critical assertion: there should be exactly ONE updateBlock call,
      // not two (which would indicate a duplicate from the adapter).
      final updateCalls = spyRepo.calls.where((c) => c.startsWith('updateBlock:')).toList();
      expect(updateCalls.length, 1,
          reason: 'Slash conversion must produce exactly one updateBlock call (ChangeBlockTypeMutation), not a duplicate',);

      // Verify the block was converted to list type
      final convertedBlock = testBlocks.firstWhere((b) => b.id == 'block-a');
      expect(convertedBlock.type, 'list');

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test B: Slash to Numbered ---
    testWidgets('B. Slash to numbered list: exactly one persistence call', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-b', 'Hello');
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

      spyRepo.calls.clear();

      editor.execute([
        ConvertParagraphToListItemRequest(nodeId: nodeId, type: ListItemType.ordered),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      final updateCalls = spyRepo.calls.where((c) => c.startsWith('updateBlock:')).toList();
      expect(updateCalls.length, 1);

      final convertedBlock = testBlocks.firstWhere((b) => b.id == 'block-b');
      expect(convertedBlock.type, 'list');

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test C: Slash to Checklist ---
    testWidgets('C. Slash to checklist: exactly one persistence call', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-c', 'Hello');
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

      spyRepo.calls.clear();

      editor.execute([
        ConvertParagraphToTaskRequest(nodeId: nodeId),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      final updateCalls = spyRepo.calls.where((c) => c.startsWith('updateBlock:')).toList();
      expect(updateCalls.length, 1);

      final convertedBlock = testBlocks.firstWhere((b) => b.id == 'block-c');
      expect(convertedBlock.type, 'list');

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test D: Slash to Heading 2 ---
    testWidgets('D. Slash to heading 2: exactly one persistence call', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-d', 'Hello');
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

      spyRepo.calls.clear();

      editor.execute([
        ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: header2Attribution),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      final updateCalls = spyRepo.calls.where((c) => c.startsWith('updateBlock:')).toList();
      expect(updateCalls.length, 1);

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test G: Version regression ---
    testWidgets('G. Version advances correctly: conversion then typing', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-g', 'Hello', version: 5);
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
      final registry = state.registry as EditorIdentityRegistry;
      final nodeId = document.first.id;
      final blockId = registry.blockIdForNode(nodeId)!;

      // Initial version should be 5
      expect(registry.getBlockVersion(blockId), 5);

      spyRepo.calls.clear();

      // Convert to bullet
      editor.execute([
        ConvertParagraphToListItemRequest(nodeId: nodeId, type: ListItemType.unordered),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      // After conversion: version should be 6
      expect(registry.getBlockVersion(blockId), 6,
          reason: 'ChangeBlockTypeMutation must increment version 5 to 6',);

      // The updateBlock call should have carried expectedVersion: 5
      final firstUpdateCall = spyRepo.calls.firstWhere((c) => c.startsWith('updateBlock:'));
      expect(firstUpdateCall.contains('v5'), true,
          reason: 'First updateBlock must carry expectedVersion 5',);

      // Now type into the converted list item
      final currentNodeId = document.first.id;
      final currentNode = document.first;
      final textLength = (currentNode as TextNode).text.length;

      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: currentNodeId,
            nodePosition: TextNodePosition(offset: textLength),
          ),
          textToInsert: ' World',
          attributions: {},
        ),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      // After typing: version should be 7
      final typingBlockId = registry.blockIdForNode(currentNodeId);
      if (typingBlockId == blockId) {
        expect(registry.getBlockVersion(blockId), 7,
            reason: 'UpdateBlockMutation must increment version 6 to 7',);
      }

      // Total: exactly 2 updateBlock calls (conversion + typing)
      final updateCalls = spyRepo.calls.where((c) => c.startsWith('updateBlock:')).toList();
      expect(updateCalls.length, 2,
          reason: 'Conversion + typing must produce exactly 2 updateBlock calls',);

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test I: Non-slash insertion still works ---
    testWidgets('I. Non-slash Enter creates exactly one new block', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-i', 'Hello World');
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

      spyRepo.calls.clear();

      // Split at offset 5 ("Hello" | " World")
      editor.execute([
        SplitParagraphRequest(
          nodeId: nodeId,
          splitPosition: const TextNodePosition(offset: 5),
          newNodeId: Editor.createNodeId(),
          replicateExistingMetadata: true,
        ),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      // Should produce exactly one splitBlock call
      final splitCalls = spyRepo.calls.where((c) => c.startsWith('splitBlock:')).toList();
      expect(splitCalls.length, 1,
          reason: 'Enter/split must produce exactly one splitBlock call',);

      // Document should have 2 nodes
      expect(document.nodeCount, 2);

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test J: Event ordering (the critical timing test) ---
    testWidgets('J. Event ordering: no duplicate updateBlock from adapter during conversion', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-j', 'Test');
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

      spyRepo.calls.clear();

      // Issue conversion
      editor.execute([
        ConvertParagraphToListItemRequest(nodeId: nodeId, type: ListItemType.unordered),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: exactly 1 updateBlock call (from the handler's ChangeBlockTypeMutation),
      // NOT 2 (which would indicate the adapter also produced a duplicate UpdateBlockMutation).
      final updateCalls = spyRepo.calls.where((c) => c.startsWith('updateBlock:')).toList();
      expect(updateCalls.length, 1,
          reason: 'Adapter suppression must prevent a duplicate updateBlock from conversion events',);

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test K: Multi-event conversion (task replaces node entirely) ---
    testWidgets('K. Multi-event conversion: all events suppressed during semantic scope', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-k', 'Multi event test');
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

      spyRepo.calls.clear();

      // Task conversion typically replaces the node entirely,
      // potentially generating both NodeInsertedEvent and NodeChangeEvent
      editor.execute([
        ConvertParagraphToTaskRequest(nodeId: nodeId),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      // Only 1 updateBlock from the semantic handler
      final updateCalls = spyRepo.calls.where((c) => c.startsWith('updateBlock:')).toList();
      expect(updateCalls.length, 1,
          reason: 'Task conversion must produce exactly one updateBlock (all events suppressed)',);

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test L: Conversion followed by typing ---
    testWidgets('L. Conversion then typing: 2 total updateBlock calls', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-l', '');
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

      spyRepo.calls.clear();

      // Step 1: Convert to bullet
      editor.execute([
        ConvertParagraphToListItemRequest(nodeId: nodeId, type: ListItemType.unordered),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      // Step 2: Type into the converted list item
      final currentNodeId = document.first.id;
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: currentNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: 'Hello',
          attributions: {},
        ),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      // Exactly 2: 1 from conversion (ChangeBlockTypeMutation) + 1 from typing (UpdateBlockMutation)
      final updateCalls = spyRepo.calls.where((c) => c.startsWith('updateBlock:')).toList();
      expect(updateCalls.length, 2,
          reason: 'Conversion + typing must produce exactly 2 updateBlock calls',);

      // Verify final block state
      final convertedBlock = testBlocks.firstWhere((b) => b.id == 'block-l');
      expect(convertedBlock.type, 'list');
      final data = jsonDecode(convertedBlock.data) as Map<String, dynamic>;
      expect(data['listType'], 'bullet');

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test M: The full integration scenario ---
    testWidgets('M. Full flow: Slash -> Numbered -> Enter -> Type -> Enter -> Slash -> Bullet', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-m', '');
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

      spyRepo.calls.clear();

      // 1. Slash -> Numbered List
      String currentNodeId = document.first.id;
      editor.execute([
        ConvertParagraphToListItemRequest(nodeId: currentNodeId, type: ListItemType.ordered),
      ]);
      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      
      // 2. Type "Hello"
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: currentNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: 'Hello',
          attributions: {},
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      // 3. Enter (Split)
      final splitNodeId = Editor.createNodeId();
      editor.execute([
        SplitListItemRequest(
          nodeId: currentNodeId,
          splitPosition: const TextNodePosition(offset: 5),
          newNodeId: splitNodeId,
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      currentNodeId = splitNodeId;

      // 4. Type "Hii"
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: currentNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: 'Hii',
          attributions: {},
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      // 5. Enter (Split again)
      final nextSplitNodeId = Editor.createNodeId();
      editor.execute([
        SplitListItemRequest(
          nodeId: currentNodeId,
          splitPosition: const TextNodePosition(offset: 3),
          newNodeId: nextSplitNodeId,
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      currentNodeId = nextSplitNodeId;

      // 6. Type "/"
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: currentNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: '/',
          attributions: {},
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      
      // Remove '/' and convert to bullet (simulating the user selecting 'Bulleted List')
      editor.execute([
        DeleteContentRequest(
          documentRange: DocumentSelection(
            base: DocumentPosition(nodeId: currentNodeId, nodePosition: const TextNodePosition(offset: 0)),
            extent: DocumentPosition(nodeId: currentNodeId, nodePosition: const TextNodePosition(offset: 1)),
          ),
        ),
        ChangeListItemTypeRequest(
          nodeId: currentNodeId,
          newType: ListItemType.unordered,
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();

      // Verify that three separate blocks exist
      expect(testBlocks.length, 3);
      
      final firstBlock = testBlocks.firstWhere((b) => b.id == 'block-m');
      expect(firstBlock.type, 'list');
      expect(jsonDecode(firstBlock.data)['listType'], 'numbered');
      
      // The other two blocks should have different IDs
      final blockIds = testBlocks.map((b) => b.id).toSet();
      expect(blockIds.length, 3, reason: 'Each split must create a new block ID');
      
      // Finding the other blocks
      final newBlocks = testBlocks.where((b) => b.id != 'block-m').toList();
      expect(newBlocks[0].type, 'list');
      expect(newBlocks[1].type, 'list');
      
      // The last one should be bulleted
      final lastBlock = testBlocks.lastWhere((b) => b.id == (state.registry as EditorIdentityRegistry).blockIdForNode(currentNodeId));
      expect(jsonDecode(lastBlock.data)['listType'], 'bullet');
      
      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test N: Single Insertion (Unowned NodeInsertedEvent routes to InsertBlockMutation) ---
    testWidgets('N. Single Insertion: unowned NodeInsertedEvent routes to InsertBlockMutation', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-n', 'Paragraph 1');
      await tester.pumpWidget(buildTestAppWithSpy(
        blocks: [block],
        testPage: testPage,
        spy: spyRepo,
      ),);
      await pumpUntilInitialized(tester);

      final state = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final document = state.document as MutableDocument;
      final adapter = state.adapter as KetionSuperEditorAdapter;

      spyRepo.calls.clear();

      // Trigger an unowned NodeInsertedEvent (simulating a paste or external insertion)
      final newNodeId = Editor.createNodeId();
      final newNode = ParagraphNode(id: newNodeId, text: AttributedText('Pasted Paragraph'));
      document.insertNodeAfter(existingNodeId: document.first.id, newNode: newNode);
      
      adapter.onDocumentChangeForTesting(DocumentChangeLog([
        NodeInsertedEvent(newNodeId, 1),
      ]),);

      // We wait for the adapter to flush
      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      // The adapter should have created exactly 1 InsertBlockMutation
      // which results in 1 call to createBlock on the repository.
      final createCalls = spyRepo.calls.where((c) => c.startsWith('createBlock:')).toList();
      final updateCalls = spyRepo.calls.where((c) => c.startsWith('updateBlock:')).toList();
      
      expect(createCalls.length, 1, reason: 'Must produce exactly one createBlock call');
      expect(updateCalls.length, 0, reason: 'Must NOT produce an updateBlock call for a newly inserted node');

      // Check testBlocks
      expect(testBlocks.length, 2);
      final newBlock = testBlocks.lastWhere((b) => b.id != 'block-n');
      final data = jsonDecode(newBlock.data) as Map<String, dynamic>;
      expect(data['spans'][0]['text'], 'Pasted Paragraph');

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test O: Multi-Node / Paste Ordering Test ---
    testWidgets('O. Paste Ordering: multiple nodes pasted maintain correct order', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-o', 'Block A');
      await tester.pumpWidget(buildTestAppWithSpy(
        blocks: [block],
        testPage: testPage,
        spy: spyRepo,
      ),);
      await pumpUntilInitialized(tester);

      final state = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final document = state.document as MutableDocument;
      final adapter = state.adapter as KetionSuperEditorAdapter;

      spyRepo.calls.clear();

      // We insert Block B, Block C, Block D in that order after Block A
      final nodeB = ParagraphNode(id: Editor.createNodeId(), text: AttributedText('Block B'));
      final nodeC = ParagraphNode(id: Editor.createNodeId(), text: AttributedText('Block C'));
      final nodeD = ParagraphNode(id: Editor.createNodeId(), text: AttributedText('Block D'));

      // Insert sequentially so their document index represents A < B < C < D
      document.insertNodeAfter(existingNodeId: document.first.id, newNode: nodeB);
      document.insertNodeAfter(existingNodeId: nodeB.id, newNode: nodeC);
      document.insertNodeAfter(existingNodeId: nodeC.id, newNode: nodeD);

      adapter.onDocumentChangeForTesting(DocumentChangeLog([
        NodeInsertedEvent(nodeB.id, 1),
        NodeInsertedEvent(nodeC.id, 2),
        NodeInsertedEvent(nodeD.id, 3),
      ]),);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      final createCalls = spyRepo.calls.where((c) => c.startsWith('createBlock:')).toList();
      expect(createCalls.length, 3, reason: 'Must produce exactly three createBlock calls');

      // Assert positional ordering A < B < C < D in testBlocks
      testBlocks.sort((b1, b2) => b1.position.compareTo(b2.position));
      expect(testBlocks.length, 4);
      
      expect(jsonDecode(testBlocks[0].data)['spans'][0]['text'], 'Block A');
      expect(jsonDecode(testBlocks[1].data)['spans'][0]['text'], 'Block B');
      expect(jsonDecode(testBlocks[2].data)['spans'][0]['text'], 'Block C');
      expect(jsonDecode(testBlocks[3].data)['spans'][0]['text'], 'Block D');

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test P: Checklist Persistence Test ---
    testWidgets('P. Checklist Persistence Test', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-p', 'My Task');
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

      spyRepo.calls.clear();

      // Convert to task (checklist)
      editor.execute([
        ConvertParagraphToTaskRequest(nodeId: nodeId),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert state
      final checklistBlock = testBlocks.firstWhere((b) => b.id == 'block-p');
      expect(checklistBlock.type, 'list');
      final data = jsonDecode(checklistBlock.data) as Map<String, dynamic>;
      expect(data['listType'], 'checklist');
      expect(data['checked'], false);

      // Now toggle the checklist
      editor.execute([
        ChangeTaskCompletionRequest(nodeId: nodeId, isComplete: true),
      ]);

      await tester.pump(const Duration(milliseconds: 500));
      await adapter.flushPendingChanges();
      await tester.pump(const Duration(milliseconds: 100));

      final toggledBlock = testBlocks.firstWhere((b) => b.id == 'block-p');
      final toggledData = jsonDecode(toggledBlock.data) as Map<String, dynamic>;
      expect(toggledData['listType'], 'checklist');
      expect(toggledData['checked'], true);

      debugDefaultTargetPlatformOverride = null;
    });

    // --- Test Q: Heading Visual Test ---
    testWidgets('Q. Heading Visual: Text styles are applied correctly', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block = makeTextBlock('block-q', 'Heading Test');
      await tester.pumpWidget(buildTestAppWithSpy(
        blocks: [block],
        testPage: testPage,
        spy: spyRepo,
      ),);
      await pumpUntilInitialized(tester);

      final state = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final document = state.document as MutableDocument;
      final editor = state.editor as Editor;
      final nodeId = document.first.id;

      // Verify default paragraph style
      final paragraphElement = find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == 'Heading Test',
      ).evaluate().first.widget as RichText;
      
      expect(paragraphElement.text.style?.fontSize, 18);

      // Convert to H1
      editor.execute([
        ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: header1Attribution),
      ]);
      await tester.pump();
      
      final h1Element = find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == 'Heading Test',
      ).evaluate().first.widget as RichText;
      
      expect(h1Element.text.style!.fontSize! > 18.0, true);

      // Convert to H2
      editor.execute([
        ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: header2Attribution),
      ]);
      await tester.pump();
      
      final h2Element = find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == 'Heading Test',
      ).evaluate().first.widget as RichText;
      
      expect(h2Element.text.style!.fontSize! > 18.0, true);

      // Convert to H3
      editor.execute([
        ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: header3Attribution),
      ]);
      await tester.pump();
      
      final h3Element = find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == 'Heading Test',
      ).evaluate().first.widget as RichText;
      
      expect(h3Element.text.style!.fontSize! > 18.0, true);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
