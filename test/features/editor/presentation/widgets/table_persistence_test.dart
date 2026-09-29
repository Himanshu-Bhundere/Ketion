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
import 'package:ketion/features/editor/presentation/widgets/ketion_slash_command_registry.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as page_entity;
import 'package:ketion/features/pages/domain/repositories/page_repository.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/editor/presentation/table/ketion_table_node.dart';
import 'package:ketion/features/editor/presentation/table/ketion_table_commands.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_edit_requests.dart';

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

  testWidgets('Table persistence structural round-trip, duplicate-persistence regression, and rapid-edit', (tester) async {
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
          'spans': [{'text': 'Current Paragraph'}],
          'headingLevel': 0,
        }),
        position: 1000,
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

    expect(document.nodeCount, 1);
    final currentParaId = document.first.id;

    // Convert to Table via slash command
    final List<SlashCommandOption> options = hostState.getSlashOptionsForTesting('') as List<SlashCommandOption>;
    final tableOption = options.firstWhere((o) => o.title == 'Table');
    
    List<EditRequest> requests = [];
    if (tableOption is KetionSlashCommand) {
      requests = tableOption.getEditRequestsWithDoc(currentParaId, document);
    } else if (tableOption is SuperEditorSlashCommandOption) {
      requests = tableOption.getEditRequests(currentParaId);
    }
    editor.execute(requests);
    
    // Allow for persistence coordinator to sync
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Structural check in Document
    expect(document.nodeCount, 2);
    expect(document.getNodeAt(0) is KetionTableNode, isTrue);
    final tableNode = document.getNodeAt(0) as KetionTableNode;
    expect(tableNode.metadata['columnCount'], 3); // Default 3x3 table
    List<dynamic> rows = tableNode.metadata['rows'] as List<dynamic>;
    expect(rows.length, 3);
    for (var row in rows) {
      expect((row['cells'] as List).length, 3);
    }

    // Verify SQLite block persistence (DummyBlockRepository)
    final tableBlock = testBlocks.firstWhere((b) => b.type == 'table');
    expect(tableBlock.type, 'table');
    
    final data = jsonDecode(tableBlock.data);
    expect(data['columnCount'], 3); 
    expect(data['runtimeType'], 'table');
    expect((data['rows'] as List).length, 3);
    
    // Verify Regression 1: Duplicate persistence (SuperEditor generic persistence vs Ketion persistence)
    // Coalescing in persistence coordinator should ensure only 1 update for the slash command (which is immediate).
    // Or if immediate doesn't count towards updates, just a small number of updates.
    // Reset counter for rapid typing test
    blocksUpdatedCount = 0;
    
    // Perform rapid edits
    // 5 edits to a cell
    for (int i = 1; i <= 5; i++) {
       editor.execute([
         UpdateTableRequest(
           nodeId: tableNode.id,
           innerCommand: UpdateTableCellCommand(
             nodeId: tableNode.id,
             rowIndex: 0,
             colIndex: 0,
             text: 'Test $i',
           ),
         ),
       ],);
       // Minor delay
       await tester.pump(const Duration(milliseconds: 50));
    }
    
    // Wait for debounce period (PersistenceCoordinator has 500ms delay)
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    
    // Validate that we saved exactly 5 times (1 per edit), and not 10 times (which would happen without suppression)
    // The coordinator uses microtasks, so each pump(50ms) allows it to process the queue.
    expect(blocksUpdatedCount, 5);
    
    // Validate final state
    final tableBlockAfterEdits = testBlocks.firstWhere((b) => b.type == 'table');
    final dataAfterEdits = jsonDecode(tableBlockAfterEdits.data);
    final cell0_0 = dataAfterEdits['rows'][0]['cells'][0];
    // check text span
    expect(cell0_0['spans'][0]['text'], 'Test 5');

    // Add row and column
    editor.execute([
      UpdateTableRequest(
        nodeId: tableNode.id,
        innerCommand: AddTableRowCommand(
          nodeId: tableNode.id,
          afterRowIndex: 2,
        ),
      ),
      UpdateTableRequest(
        nodeId: tableNode.id,
        innerCommand: AddTableColumnCommand(
          nodeId: tableNode.id,
          afterColIndex: 2,
        ),
      ),
    ]);
    
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    
    // Validate added row/col
    final tableBlockExpanded = testBlocks.firstWhere((b) => b.type == 'table');
    final dataExpanded = jsonDecode(tableBlockExpanded.data);
    expect(dataExpanded['columnCount'], 4);
    expect((dataExpanded['rows'] as List).length, 4);

    // Now let's "reopen" the editor with the persisted blocks and verify
    // the document nodes are correctly reconstructed.
    
    await tester.pumpWidget(const SizedBox()); // Clear
    await tester.pumpWidget(buildTestApp(blocks: testBlocks, testPage: testPage));
    await pumpUntilInitialized(tester);

    final State stateReopened = tester.state(find.byType(SuperEditorHost));
    final dynamic hostStateReopened = stateReopened;
    final documentReopened = hostStateReopened.document as MutableDocument;

    expect(documentReopened.nodeCount, 2);
    final reopenedTable = documentReopened.getNodeAt(0) as KetionTableNode;
    
    expect(reopenedTable.metadata['columnCount'], 4,
      reason: 'Reopened table must have updated column count',);
      
    final reopenedRows = reopenedTable.metadata['rows'] as List;
    expect(reopenedRows.length, 4);
  });

  testWidgets('SuperEditorAdapter discards generic NodeChangeEvents for KetionTableNode', (tester) async {
    final testPage = page_entity.Page(
      id: pageId,
      title: 'Test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final initialBlocks = [
      Block(
        id: 'table1',
        pageId: pageId,
        type: 'table',
        data: jsonEncode({
          'columnCount': 2,
          'rows': <Map<String, dynamic>>[
            {'id': 'row_1', 'cells': <Map<String, dynamic>>[{'id': '1_1', 'spans': <dynamic>[]}, {'id': '1_2', 'spans': <dynamic>[]}]},
            {'id': 'row_2', 'cells': <Map<String, dynamic>>[{'id': '2_1', 'spans': <dynamic>[]}, {'id': '2_2', 'spans': <dynamic>[]}]},
          ],
        }),
        position: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(buildTestApp(blocks: initialBlocks, testPage: testPage));
    await pumpUntilInitialized(tester);

    final State state = tester.state(find.byType(SuperEditorHost));
    final dynamic hostState = state;
    final editor = hostState.editor as Editor;
    
    // Reset the count before our generic edit
    blocksUpdatedCount = 0;

    // Dispatch a generic NodeChangeEvent that isn't wrapped in UpdateTableRequest
    // by replacing the node with an identical copy using a standard request.
    final tableNode = editor.context.document.first as KetionTableNode;
    editor.execute([
      ReplaceNodeRequest(
        existingNodeId: tableNode.id,
        newNode: KetionTableNode(
          id: tableNode.id,
          metadata: Map.from(tableNode.metadata),
        ),
      ),
    ]);
    
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    
    // Validate that no updates were queued/processed for the table because
    // the generic NodeChangeEvent should be discarded by SuperEditorAdapter
    expect(blocksUpdatedCount, 0, reason: 'Generic NodeChangeEvent for KetionTableNode must be discarded');
  });
}

