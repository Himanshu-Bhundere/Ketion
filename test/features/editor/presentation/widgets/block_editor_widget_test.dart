import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/features/editor/presentation/providers/editor_state_provider.dart';
import 'package:ketion/features/editor/presentation/widgets/block_editor_widget.dart';
import 'package:ketion/features/editor/presentation/widgets/block_wrapper.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as page_entity;
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/blocks/domain/usecases/get_page_blocks_usecase.dart';
import 'package:ketion/features/blocks/domain/repositories/block_repository.dart';
import 'dart:convert';
import 'package:ketion/features/editor/domain/models/drop_intent.dart';
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';

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

  String listData(String text) => jsonEncode({
    'spans': [
      {
        'text': text,
        'bold': false,
        'italic': false,
        'underline': false,
        'strikethrough': false,
        'code': false,
      },
    ],
    'listType': 'checklist',
    'checked': false,
  });

  Widget buildTestApp({
    required List<Block> blocks,
    required page_entity.Page testPage,
    String? focusedBlockId,
  }) {
    return ProviderScope(
      overrides: [
        pageProvider(pageId).overrideWith((ref) => testPage),
        blockRepositoryProvider.overrideWithValue(DummyBlockRepository()),
        getPageBlocksUseCaseProvider.overrideWithValue(MockGetPageBlocksUseCase(blocks)),
        focusedBlockIdProvider.overrideWith((ref) => focusedBlockId),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: BlockEditorWidget(
            pageId: pageId,
            onTitleChanged: (title) async => const Success(null),
            onIconChanged: (icon) async => const Success(null),
          ),
        ),
      ),
    );
  }

  group('BlockEditorWidget Widget Tests', () {
    testWidgets('renders blocks correctly', (tester) async {
      final block1 = Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        position: 0,
        data: textData('Block 1 Text'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final block2 = Block(
        id: 'block2',
        pageId: pageId,
        type: 'text',
        position: 1,
        data: textData('Block 2 Text'),
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
      await tester.pumpAndSettle();

      expect(find.byType(BlockEditorWidget), findsOneWidget);
      expect(find.byType(BlockWrapper), findsNWidgets(2));
      expect(find.text('Block 1 Text'), findsOneWidget);
      expect(find.text('Block 2 Text'), findsOneWidget);
    });

    testWidgets('Focus restoration and isolation tests', (tester) async {
      final block1 = Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        position: 0,
        data: textData('Hello World'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final block2 = Block(
        id: 'block2',
        pageId: pageId,
        type: 'text',
        position: 1,
        data: textData('Second Block'),
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
      await tester.pumpAndSettle();

      // Focus on the first block
      await tester.tap(find.text('Hello World'));
      await tester.pumpAndSettle();

      final firstField = find.byType(TextField).first;
      final textField = tester.widget<TextField>(firstField);

      // Verify focusedBlockIdProvider
      final element = tester.element(find.byType(BlockEditorWidget));
      final container = ProviderScope.containerOf(element);
      expect(container.read(focusedBlockIdProvider), 'block1');

      // Move cursor to the end of the text so that arrowDown triggers focusNextBlock
      textField.controller?.selection = TextSelection.collapsed(offset: textField.controller!.text.length);
      await tester.pumpAndSettle();

      // Test focus isolation (Arrow Down)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      
      // Focus should move to block2
      expect(container.read(focusedBlockIdProvider), 'block2');

      // Move cursor to the beginning of the text so that arrowUp triggers focusPreviousBlock
      final secondField = find.byType(TextField).last;
      final secondTextField = tester.widget<TextField>(secondField);
      secondTextField.controller?.selection = const TextSelection.collapsed(offset: 0);
      await tester.pumpAndSettle();

      // Back to block1
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(container.read(focusedBlockIdProvider), 'block1');

      // Test Split focus restoration
      // Send Enter key at end of block1
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Verify a new block is inserted and focused
      // The pending block focus is consumed by the new TextBlockWidget, so we shouldn't check it directly.
      // Instead, we verify that there are now 3 BlockWrappers and focus has moved to the new block.
      expect(find.byType(BlockWrapper), findsNWidgets(3));
      
      final currentFocus = container.read(focusedBlockIdProvider);
      expect(currentFocus, isNotNull);
      expect(currentFocus, isNot('block1'));
      expect(currentFocus, isNot('block2'));
    });

    testWidgets('Focus restoration on Delete and Merge', (tester) async {
      final block1 = Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        position: 0,
        data: textData('Hello World'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final block2 = Block(
        id: 'block2',
        pageId: pageId,
        type: 'text',
        position: 1,
        data: textData(''), // Empty block
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final block3 = Block(
        id: 'block3',
        pageId: pageId,
        type: 'text',
        position: 2,
        data: textData('Third'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test Page',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestApp(blocks: [block1, block2, block3], testPage: testPage));
      await tester.pumpAndSettle();

      // Focus on the second block (which is the empty one, block2)
      final secondField = find.descendant(
        of: find.byType(BlockWrapper),
        matching: find.byType(TextField),
      ).at(1);
      await tester.tap(secondField);
      await tester.pumpAndSettle();
      
      final secondTextField = tester.widget<TextField>(secondField);
      secondTextField.controller?.selection = const TextSelection.collapsed(offset: 0);
      
      // Press Backspace in the empty block
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      // Block2 should be deleted. 2 blocks remain.
      expect(find.byType(BlockWrapper), findsNWidgets(2));
      
      final element = tester.element(find.byType(BlockEditorWidget));
      final container = ProviderScope.containerOf(element);
      
      // Focus should be on block1
      expect(container.read(focusedBlockIdProvider), 'block1');

      // Now we have block1 and block3. Let's merge block3 into block1.
      // Move to block3, offset 0.
      final lastFieldFinder = find.descendant(
        of: find.byType(BlockWrapper),
        matching: find.byType(TextField),
      ).last;
      await tester.tap(lastFieldFinder);
      await tester.pumpAndSettle();
      final lastField = tester.widget<TextField>(lastFieldFinder);
      lastField.controller?.selection = const TextSelection.collapsed(offset: 0);
      
      // Press Backspace
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      // Block3 merged into Block1. 1 block remains.
      expect(find.byType(BlockWrapper), findsNWidgets(1));
      
      // Focus should be on block1
      expect(container.read(focusedBlockIdProvider), 'block1');
    });

    testWidgets('Focus restoration on Indent and Unnest (Tab/Shift+Tab)', (tester) async {
      final block1 = Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        position: 0,
        data: textData('Parent'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final block2 = Block(
        id: 'block2',
        pageId: pageId,
        type: 'text',
        position: 1,
        data: textData('Child'),
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
      await tester.pumpAndSettle();

      // Focus on block2
      await tester.tap(find.text('Child'));
      await tester.pumpAndSettle();
      
      final element = tester.element(find.byType(BlockEditorWidget));
      final container = ProviderScope.containerOf(element);

      // Verify focus
      expect(container.read(focusedBlockIdProvider), 'block2');

      // Press Tab to Indent
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Verify focus is STILL on block2 after structural change
      expect(container.read(focusedBlockIdProvider), 'block2');
      // Verify structurally indented (parent should be block1)
      final blocksAfterIndent = container.read(editorStateProvider(pageId)).value ?? [];
      final childBlock = blocksAfterIndent.firstWhere((b) => b.id == 'block2');
      expect(childBlock.parentBlockId, 'block1');

      // Press Shift+Tab to Unnest
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      // Verify focus is STILL on block2
      expect(container.read(focusedBlockIdProvider), 'block2');
      // Verify structurally unnested (parent should be null)
      final blocksAfterUnnest = container.read(editorStateProvider(pageId)).value ?? [];
      final unnestedBlock = blocksAfterUnnest.firstWhere((b) => b.id == 'block2');
      expect(unnestedBlock.parentBlockId, isNull);
    });

    testWidgets('list blocks split on an IME newline', (tester) async {
      final listBlock = Block(
        id: 'list-1',
        pageId: pageId,
        type: 'list',
        position: 0,
        data: listData('Task'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final testPage = page_entity.Page(
        id: pageId,
        title: 'Test Page',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestApp(blocks: [listBlock], testPage: testPage));
      await tester.pumpAndSettle();

      final field = find.descendant(
        of: find.byType(BlockWrapper),
        matching: find.byType(TextField),
      );
      await tester.tap(field);
      await tester.enterText(field, 'Task\n');
      await tester.pumpAndSettle();
      expect(find.byType(BlockWrapper), findsNWidgets(2));
    });
  });
}
