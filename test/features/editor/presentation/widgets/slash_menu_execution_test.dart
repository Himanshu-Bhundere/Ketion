import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import 'package:ketion/features/editor/presentation/widgets/slash_command_menu.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_slash_command.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_slash_command_registry.dart';

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

List<Block> testBlocks = [];
int blocksUpdatedCount = 0;

class MockGetPageBlocksUseCase implements GetPageBlocksUseCase {
  MockGetPageBlocksUseCase(List<Block> initialBlocks) {
    testBlocks = List.from(initialBlocks);
    blocksUpdatedCount = 0;
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
    final block = testBlocks.firstWhere((b) => b.id == id);
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
      blocksUpdatedCount++;
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
        blocksUpdatedCount++;
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
      pageId: 'test-page',
      type: 'text',
      data: data,
      parentBlockId: parentBlockId,
      position: position,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),);
    return const Success(null);
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

  Widget buildTestApp({required List<Block> blocks, required page_entity.Page testPage}) {
    return ProviderScope(
      overrides: [
        getPageBlocksUseCaseProvider.overrideWithValue(MockGetPageBlocksUseCase(blocks)),
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

  final optionsToTest = [
    'Heading 1',
    'Heading 2',
    'Heading 3',
    'Quote',
    'Divider',
    'Code Block',
    'Callout',
    'Table',
    'Checklist',
    'Bulleted List',
    'Numbered List',
    'Reminder',
  ];

  for (final optionName in optionsToTest) {
    testWidgets('Slash menu option "$optionName" has a complete execution pipeline', (tester) async {
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final initialBlock = Block(
        id: 'b1',
        pageId: pageId,
        type: 'text',
        data: jsonEncode({
          'spans': [{'text': 'Test item'}],
          'headingLevel': 0,
        }),
        position: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestApp(blocks: [initialBlock], testPage: testPage));
      await pumpUntilInitialized(tester);

      final State state = tester.state(find.byType(SuperEditorHost));
      final dynamic hostState = state;
      
      final List<SlashCommandOption> options = hostState.getSlashOptionsForTesting('') as List<SlashCommandOption>;
      final option = options.firstWhere((o) => o.title == optionName, orElse: () => throw Exception('Option $optionName not found'));
      
      if (!option.isSupported) return;
      
      if (option is SuperEditorSlashCommandOption) {
        final dynamic currentHostState = tester.state(find.byType(SuperEditorHost));
        final editor = currentHostState.editor as Editor;
        final document = currentHostState.document as MutableDocument;
        
        final oldNodeCount = document.nodeCount;
        final firstNodeId = document.first.id;
        final oldBlockType = document.first is ParagraphNode ? (document.first as ParagraphNode).metadata['blockType'] : null;
        
        // Ensure selection is active on the node to mimic real behavior
        editor.execute([
          ChangeSelectionRequest(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: firstNodeId,
                nodePosition: const TextNodePosition(offset: 9),
              ),
            ),
            SelectionChangeType.placeCaret,
            SelectionReason.userInteraction,
          ),
        ]);
        
        List<EditRequest> requests = [];
        if (option is KetionSlashCommand) {
          requests = option.getEditRequestsWithDoc(firstNodeId, document);
        } else {
          requests = option.getEditRequests(firstNodeId);
        }
        
        try {
          editor.execute(requests);
        } catch (e) {
          fail('Option "${option.title}" threw an exception during execution: $e');
        }
        
        // Use fixed pump instead of pumpAndSettle to prevent timeout from blinking caret
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        
        // Verify mutation
        final newBlockType = document.first is ParagraphNode ? (document.first as ParagraphNode).metadata['blockType'] : null;
        final mutated = document.nodeCount != oldNodeCount || 
                        document.first.id != firstNodeId || 
                        document.first is! ParagraphNode ||
                        newBlockType != oldBlockType;
                        
        expect(mutated, isTrue, reason: 'Option "${option.title}" executed but did not mutate the document as expected.');
      }
    });
  }

  testWidgets('S6: Pending persistence cancelled on semantic mutation', (tester) async {
    final testPage = page_entity.Page(
      id: pageId,
      title: 'Test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final initialBlock = Block(
      id: 'b1',
      pageId: pageId,
      type: 'text',
      data: jsonEncode({
        'spans': [{'text': 'Test item'}],
        'headingLevel': 0,
      }),
      position: 1000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(buildTestApp(blocks: [initialBlock], testPage: testPage));
    await pumpUntilInitialized(tester);

    blocksUpdatedCount = 0;
    
    final State state = tester.state(find.byType(SuperEditorHost));
    final dynamic hostState = state;
    final editor = hostState.editor as Editor;
    final document = hostState.document as MutableDocument;
    
    final firstNodeId = document.first.id;
    
    // Simulate generic edit to queue it
    editor.execute([
      ReplaceNodeRequest(
        existingNodeId: firstNodeId,
        newNode: ParagraphNode(
          id: firstNodeId,
          text: AttributedText('Test item mutated'),
        ),
      ),
    ]);
    
    // adapter._pendingNodeIds should have firstNodeId now
    
    // Convert via slash
    final List<SlashCommandOption> options = hostState.getSlashOptionsForTesting('') as List<SlashCommandOption>;
    final headingOption = options.firstWhere((o) => o.title == 'Heading 1');
    
    List<EditRequest> requests = [];
    if (headingOption is KetionSlashCommand) {
      requests = headingOption.getEditRequestsWithDoc(firstNodeId, document);
    } else if (headingOption is SuperEditorSlashCommandOption) {
      requests = headingOption.getEditRequests(firstNodeId);
    }
    
    editor.execute(requests);
    
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    
    // Check it only resulted in 1 save for this node, not 2
    expect(blocksUpdatedCount, 1);
  });

  testWidgets('S7: Numbered list item -> Heading 1', (tester) async {
    final testPage = page_entity.Page(
      id: pageId,
      title: 'Test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final initialBlock = Block(
      id: 'b1',
      pageId: pageId,
      type: 'list',
      data: jsonEncode({
        'spans': [{'text': 'List item'}],
        'listType': 'numbered',
      }),
      position: 1000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(buildTestApp(blocks: [initialBlock], testPage: testPage));
    await pumpUntilInitialized(tester);

    final State state = tester.state(find.byType(SuperEditorHost));
    final dynamic hostState = state;
    final editor = hostState.editor as Editor;
    final document = hostState.document as MutableDocument;
    
    final firstNodeId = document.first.id;
    
    // verify it's a ListItemNode
    expect(document.first is ListItemNode, isTrue);
    
    final List<SlashCommandOption> options = hostState.getSlashOptionsForTesting('') as List<SlashCommandOption>;
    final headingOption = options.firstWhere((o) => o.title == 'Heading 1');
    
    List<EditRequest> requests = [];
    if (headingOption is KetionSlashCommand) {
      requests = headingOption.getEditRequestsWithDoc(firstNodeId, document);
    } else if (headingOption is SuperEditorSlashCommandOption) {
      requests = headingOption.getEditRequests(firstNodeId);
    }
    
    editor.execute(requests);
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    
    expect(document.nodeCount, 1, reason: 'No orphaned nodes should remain');
    expect(document.first is ParagraphNode, isTrue);
    expect((document.first as ParagraphNode).metadata['blockType'], header1Attribution);
  });

  testWidgets('S8: Numbered list item -> Bulleted List', (tester) async {
    final testPage = page_entity.Page(
      id: pageId,
      title: 'Test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final initialBlock = Block(
      id: 'b1',
      pageId: pageId,
      type: 'list',
      data: jsonEncode({
        'spans': [{'text': 'List item'}],
        'listType': 'numbered',
      }),
      position: 1000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(buildTestApp(blocks: [initialBlock], testPage: testPage));
    await pumpUntilInitialized(tester);

    final State state = tester.state(find.byType(SuperEditorHost));
    final dynamic hostState = state;
    final editor = hostState.editor as Editor;
    final document = hostState.document as MutableDocument;
    
    final firstNodeId = document.first.id;
    
    final List<SlashCommandOption> options = hostState.getSlashOptionsForTesting('') as List<SlashCommandOption>;
    final unorderedOption = options.firstWhere((o) => o.title == 'Bulleted List');
    
    List<EditRequest> requests = [];
    if (unorderedOption is KetionSlashCommand) {
      requests = unorderedOption.getEditRequestsWithDoc(firstNodeId, document);
    } else if (unorderedOption is SuperEditorSlashCommandOption) {
      requests = unorderedOption.getEditRequests(firstNodeId);
    }
    
    editor.execute(requests);
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    
    expect(document.nodeCount, 1);
    expect(document.first is ListItemNode, isTrue);
    expect((document.first as ListItemNode).type, ListItemType.unordered);
  });

  testWidgets('S9: Code block + / retains slash and does not open menu', (tester) async {
    final testPage = page_entity.Page(
      id: pageId,
      title: 'Test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final initialBlock = Block(
      id: 'b1',
      pageId: pageId,
      type: 'text',
      data: jsonEncode({
        'spans': [{'text': 'Code'}],
        'blockType': 'code',
      }),
      position: 1000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(buildTestApp(blocks: [initialBlock], testPage: testPage));
    await pumpUntilInitialized(tester);

    final State state = tester.state(find.byType(SuperEditorHost));
    final dynamic hostState = state;
    final editor = hostState.editor as Editor;
    final document = hostState.document as MutableDocument;
    
    final firstNodeId = document.first.id;
    
    // Simulate user typing / in code block
    editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: firstNodeId,
            nodePosition: const TextNodePosition(offset: 4),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      InsertCharacterAtCaretRequest(character: '/'),
    ]);
    
    await tester.pumpAndSettle();
    
    // Slash menu should not be open
    final slashCommandController = hostState.slashCommandController as SuperEditorSlashCommandController;
    expect(slashCommandController.isOpen, isFalse);
    
    // Slash should be retained
    final text = (document.first as ParagraphNode).text.toPlainText();
    expect(text, endsWith('/'));
  });
}
