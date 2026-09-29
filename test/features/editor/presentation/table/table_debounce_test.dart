import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'package:ketion/features/editor/presentation/table/ketion_table_component.dart';

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
    throw Exception('pumpUntilInitialized timed out');
  }
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  const pageId = 'test-page';

  Widget buildTestApp({required List<Block> blocks, required page_entity.Page testPage, double width = 800, double height = 600}) {
    return ProviderScope(
      overrides: [
        getPageBlocksUseCaseProvider.overrideWithValue(MockGetPageBlocksUseCase(blocks)),
        blockRepositoryProvider.overrideWithValue(DummyBlockRepository()),
        pageRepositoryProvider.overrideWithValue(_MockPageRepo(testPage)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: Consumer(
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
        ),
      ),
    );
  }

  final testPage = page_entity.Page(
    id: pageId,
    title: 'Test',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  List<Block> createInitialTableBlock() {
    return [
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
  }

  testWidgets('T1: Cell autosave after 300 ms', (tester) async {
    await tester.pumpWidget(buildTestApp(blocks: createInitialTableBlock(), testPage: testPage));
    await pumpUntilInitialized(tester);

    blocksUpdatedCount = 0;

    final textFields = find.descendant(
      of: find.byType(KetionTableComponent),
      matching: find.byType(TextField),
    );
    expect(textFields, findsNWidgets(4));

    // Type in the first cell
    await tester.enterText(textFields.at(0), 'Hello T1');
    
    // Immediate after typing: no save yet
    expect(blocksUpdatedCount, 0);

    // Wait 200 ms (less than debounce)
    await tester.pump(const Duration(milliseconds: 200));
    expect(blocksUpdatedCount, 0);

    // Wait another 150 ms (total > 300 ms)
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    
    // Now it should be saved
    expect(blocksUpdatedCount, 1);
    
    final tableBlock = testBlocks.firstWhere((b) => b.type == 'table');
    final data = jsonDecode(tableBlock.data);
    expect(data['rows'][0]['cells'][0]['spans'][0]['text'], 'Hello T1');
  });

  testWidgets('T2: Edit then Add Row (flush-before-structural)', (tester) async {
    await tester.pumpWidget(buildTestApp(blocks: createInitialTableBlock(), testPage: testPage));
    await pumpUntilInitialized(tester);
    blocksUpdatedCount = 0;

    final textFields = find.descendant(
      of: find.byType(KetionTableComponent),
      matching: find.byType(TextField),
    );
    // Type in the first cell
    await tester.enterText(textFields.at(0), 'Survive Row');
    
    // Immediately press "Row" button before debounce fires
    final rowButton = find.widgetWithText(TextButton, 'Row');
    await tester.tap(rowButton);
    
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    
    final tableBlock = testBlocks.firstWhere((b) => b.type == 'table');
    final data = jsonDecode(tableBlock.data);
    
    // Cell should contain the text
    expect(data['rows'][0]['cells'][0]['spans'][0]['text'], 'Survive Row');
    // Row count should have increased to 3
    expect((data['rows'] as List).length, 3);
  });

  testWidgets('T3: Edit then Add Column (flush-before-structural)', (tester) async {
    await tester.pumpWidget(buildTestApp(blocks: createInitialTableBlock(), testPage: testPage));
    await pumpUntilInitialized(tester);
    blocksUpdatedCount = 0;

    final textFields = find.descendant(
      of: find.byType(KetionTableComponent),
      matching: find.byType(TextField),
    );
    // Type in the first cell
    await tester.enterText(textFields.at(0), 'Survive Col');
    
    // Immediately press "Column" button before debounce fires
    final colButton = find.widgetWithText(TextButton, 'Column');
    await tester.tap(colButton);
    
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    
    final tableBlock = testBlocks.firstWhere((b) => b.type == 'table');
    final data = jsonDecode(tableBlock.data);
    
    // Cell should contain the text
    expect(data['rows'][0]['cells'][0]['spans'][0]['text'], 'Survive Col');
    // Column count should have increased to 3
    expect(data['columnCount'], 3);
  });

  testWidgets('T4: Two cells edited within debounce window', (tester) async {
    await tester.pumpWidget(buildTestApp(blocks: createInitialTableBlock(), testPage: testPage));
    await pumpUntilInitialized(tester);
    blocksUpdatedCount = 0;

    final textFields = find.descendant(
      of: find.byType(KetionTableComponent),
      matching: find.byType(TextField),
    );
    
    // Type in cell 1
    await tester.enterText(textFields.at(0), 'Cell 1');
    // Wait 100ms
    await tester.pump(const Duration(milliseconds: 100));
    
    // Type in cell 2
    await tester.enterText(textFields.at(1), 'Cell 2');
    
    // Wait 350ms (debounce triggers once from the last edit)
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    
    final tableBlock = testBlocks.firstWhere((b) => b.type == 'table');
    final data = jsonDecode(tableBlock.data);
    
    expect(data['rows'][0]['cells'][0]['spans'][0]['text'], 'Cell 1');
    expect(data['rows'][0]['cells'][1]['spans'][0]['text'], 'Cell 2');
    
    // Ensure they were committed in one mutation (plus the persistence coordinator batching)
    expect(blocksUpdatedCount, 1);
  });

  testWidgets('T5: Horizontal overflow scrollable viewport', (tester) async {
    // 10 columns * 150 = 1500px, but our widget is 800px wide
    final largeTableBlock = [
      Block(
        id: 'table_large',
        pageId: pageId,
        type: 'table',
        data: jsonEncode({
          'columnCount': 10,
          'rows': <Map<String, dynamic>>[
            {'id': 'row_1', 'cells': List.generate(10, (i) => {'id': '1_$i', 'spans': <dynamic>[]})},
          ],
        }),
        position: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    
    await tester.pumpWidget(buildTestApp(blocks: largeTableBlock, testPage: testPage, width: 800));
    await pumpUntilInitialized(tester);

    final singleChildScrollViewFinder = find.descendant(
      of: find.byType(KetionTableComponent),
      matching: find.byType(SingleChildScrollView),
    ).first;
    
    expect(singleChildScrollViewFinder, findsOneWidget);
    
    final scrollView = tester.widget<SingleChildScrollView>(singleChildScrollViewFinder);
    expect(scrollView.scrollDirection, Axis.horizontal);

    // The table should be scrollable
    final scrollable = tester.state<ScrollableState>(find.descendant(
      of: singleChildScrollViewFinder,
      matching: find.byType(Scrollable),
    ).first,);
    
    final position = scrollable.position;
    expect(position.maxScrollExtent, greaterThan(0));
  });
}
