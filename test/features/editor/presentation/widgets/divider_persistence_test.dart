import 'dart:convert';
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
import 'package:ketion/features/editor/presentation/widgets/slash_command_menu.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_slash_command.dart';
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
  Future<Result<List<Block>>> getPageBlocks(String pageId) async {
    final sorted = List<Block>.from(testBlocks)..sort((a, b) => a.position.compareTo(b.position));
    return Success(sorted);
  }
  @override
  Future<Result<List<Block>>> getBlocksForPage(String pageId) async {
    final sorted = List<Block>.from(testBlocks)..sort((a, b) => a.position.compareTo(b.position));
    return Success(sorted);
  }
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

  testWidgets('Divider persistence and ordering round-trip', (tester) async {
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
          'spans': [{'text': 'Previous Block'}],
          'headingLevel': 0,
        }),
        position: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Block(
        id: 'b2',
        pageId: pageId,
        type: 'text',
        data: jsonEncode({
          'spans': [{'text': 'Current Paragraph'}],
          'headingLevel': 0,
        }),
        position: 2000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(buildTestApp(blocks: initialBlocks, testPage: testPage));
    await pumpUntilInitialized(tester);

    final State state = tester.state(find.byType(SuperEditorHost));
    final dynamic hostState = state;
    final editor = hostState.editor as Editor;
    final document = hostState.document as MutableDocument;

    // The document should have 2 nodes initially
    expect(document.nodeCount, 2);
    final currentParaId = document.elementAt(1).id;

    // Simulate inserting divider before the current paragraph (by calling the slash option)
    final List<SlashCommandOption> options = hostState.getSlashOptionsForTesting('') as List<SlashCommandOption>;
    final dividerOption = options.firstWhere((o) => o.title == 'Divider') as SuperEditorSlashCommandOption;
    
    final requests = dividerOption.getEditRequests(currentParaId);
    editor.execute(requests);
    
    // Allow for persistence coordinator to sync
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Structural check
    expect(document.nodeCount, 3);
    expect(document.elementAt(0) is ParagraphNode, isTrue); // Previous block
    expect(document.elementAt(1) is HorizontalRuleNode, isTrue); // Divider
    expect(document.elementAt(2) is ParagraphNode, isTrue); // Current Paragraph
    expect(document.elementAt(2).id, currentParaId);

    // Verify SQLite block persistence (DummyBlockRepository)
    // Find the newly added block (it should have type 'divider')
    final dividerBlock = testBlocks.firstWhere((b) => b.type == 'divider');
    expect(dividerBlock.type, 'divider');
    
    final data = jsonDecode(dividerBlock.data);
    expect(data['runtimeType'], 'divider');
    
    // Now simulate "Enter" (InsertNodeAtCaret or similar) on the current paragraph
    editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: currentParaId,
            nodePosition: const TextNodePosition(offset: 17), // End of 'Current Paragraph'
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      SplitParagraphRequest(
        nodeId: currentParaId, 
        splitPosition: const TextNodePosition(offset: 17),
        newNodeId: 'new-para-id',
        replicateExistingMetadata: false,
      ),
    ]);

    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // After Enter, the order should be:
    // [previous block] [divider] [current paragraph] [new paragraph]
    expect(document.nodeCount, 4);
    expect(document.elementAt(0) is ParagraphNode, isTrue);
    expect(document.elementAt(1) is HorizontalRuleNode, isTrue);
    expect(document.elementAt(2) is ParagraphNode, isTrue);
    expect(document.elementAt(3) is ParagraphNode, isTrue);

    // Now let's "reopen" the editor with the persisted blocks and verify
    // the document nodes are correctly reconstructed.
    
    // We clear the tree and rebuild the widget with testBlocks from DummyBlockRepository
    await tester.pumpWidget(const SizedBox()); // Clear
    await tester.pumpWidget(buildTestApp(blocks: testBlocks, testPage: testPage));
    await pumpUntilInitialized(tester);

    final State stateReopened = tester.state(find.byType(SuperEditorHost));
    final dynamic hostStateReopened = stateReopened;
    final documentReopened = hostStateReopened.document as MutableDocument;

    expect(documentReopened.nodeCount, 4);
    expect(documentReopened.elementAt(1) is HorizontalRuleNode, isTrue, 
      reason: 'Reopened divider block must map back to HorizontalRuleNode',);
  });
}
