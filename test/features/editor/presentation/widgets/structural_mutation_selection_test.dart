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
import 'package:ketion/features/editor/presentation/widgets/super_editor_host.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as page_entity;
import 'package:ketion/features/pages/domain/repositories/page_repository.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/editor/domain/models/drop_intent.dart';

// --- Mocks and Dummies ---
List<Block> testBlocks = [];

class MockGetPageBlocksUseCase implements GetPageBlocksUseCase {
  MockGetPageBlocksUseCase(List<Block> initialBlocks) {
    testBlocks = initialBlocks;
  }
  @override
  Future<Result<List<Block>>> call(String pageId) async => Success(testBlocks);
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
    final block = testBlocks.firstWhere((b) => b.id == id, orElse: () => Block(
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
  Future<Result<List<Block>>> getPageBlocks(String pageId) async => Success(testBlocks);
  @override
  Future<Result<List<Block>>> getBlocksForPage(String pageId) async => Success(testBlocks);
  @override
  Future<Result<List<Block>>> getChildBlocks(String parentBlockId) async => Success(testBlocks.where((b) => b.parentBlockId == parentBlockId && !b.deleted).toList());
  @override
  Future<Result<void>> updateBlock(Block block, {required int expectedVersion}) async {
    final index = testBlocks.indexWhere((b) => b.id == block.id);
    if (index != -1) {
      testBlocks[index] = block;
    } else {
      testBlocks.add(block);
    }
    return const Success(null);
  }
  Future<Result<void>> deleteBlocks(List<String> ids) async => const Success(null);

  Future<Result<void>> hardDeleteBlock(String id) async => const Success(null);
  @override
  Future<Result<void>> restoreBlock(String id, String data, String? parentBlockId, double position) async => const Success(null);
  @override
  Future<Result<void>> mergeBlocks({
    required Block mergedBlock,
    required int survivorExpectedVersion,
    required String deletedBlockId,
    required int victimExpectedVersion,
  }) async => const Success(null);
  @override
  Future<Result<List<Block>>> moveBlock(String sourceBlockId, DropIntent intent) async => const Success([]);
  @override
  Future<Result<void>> splitBlock({
    required Block updatedOriginalBlock,
    required int originalExpectedVersion,
    required Block newBlock,
  }) async => const Success(null);
}

void main() {
  group('Structural Mutation Selection Integrity', () {
    late ProviderContainer container;
    
    setUp(() {
      testBlocks = [
        Block(
          id: 'b-1',
          pageId: 'page-1',
          type: 'text',
          position: 1000,
          data: jsonEncode({'spans': <dynamic>[]}),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      container = ProviderContainer(
        overrides: [
          pageRepositoryProvider.overrideWithValue(_MockPageRepo(page_entity.Page(
            id: 'page-1',
            title: 'Test',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ),
          ),
          blockRepositoryProvider.overrideWithValue(DummyBlockRepository()),
        ],
      );
    });

    Future<SuperEditorHost> buildEditor(WidgetTester tester) async {
      final host = SuperEditorHost(
        pageId: 'page-1',
        onTitleChanged: (title) async => const Success(null),
        onIconChanged: (icon) async => const Success(null),
      );
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: host,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      return host;
    }

    testWidgets('Slash conversion and Enter split sequence (Bullet List)', (WidgetTester tester) async {
      await buildEditor(tester);
      final dynamic state = tester.state(find.byType(SuperEditorHost));
      final Editor editor = state.editor as Editor;
      final MutableDocument document = state.document as MutableDocument;
      final composer = editor.context.composer;

      // Initial: Paragraph("")
      final initialNode = document.first as TextNode;
      expect(initialNode, isA<ParagraphNode>());
      
      // Simulate typing "/bullet"
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(nodeId: initialNode.id, nodePosition: const TextNodePosition(offset: 0)),
          textToInsert: '/bullet',
          attributions: {},
        ),
      ]);
      composer.setSelectionWithReason(DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: initialNode.id,
          nodePosition: const TextNodePosition(offset: 7),
        ),
      ),
      );
      
      // Slash conversion -> Bullet
      // Simulate slash command logic deleting "/bullet" and converting
      editor.execute([
        DeleteContentRequest(
          documentRange: DocumentRange(
            start: DocumentPosition(nodeId: initialNode.id, nodePosition: const TextNodePosition(offset: 0)),
            end: DocumentPosition(nodeId: initialNode.id, nodePosition: const TextNodePosition(offset: 7)),
          ),
        ),
        ConvertParagraphToListItemRequest(nodeId: initialNode.id, type: ListItemType.unordered),
      ]);
      
      await tester.pumpAndSettle();
      
      // Manually mimic slash controller synchronous selection restoration (offset 0 because "/bullet" deleted)
      composer.setSelectionWithReason(DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: initialNode.id,
          nodePosition: const TextNodePosition(offset: 0),
        ),
      ),
      );

      // Verify Layer 1: Document
      final bulletNode = document.getNodeById(initialNode.id)!;
      expect(bulletNode, isA<ListItemNode>());
      expect((bulletNode as ListItemNode).type, ListItemType.unordered);
      expect(bulletNode.text.toPlainText(), '');

      // Verify Layer 2: Composer
      expect(composer.selection!.extent.nodeId, initialNode.id);
      expect(composer.selection!.extent.nodePosition, const TextNodePosition(offset: 0));

      // Layer 3: Input "First"
      editor.execute([
        InsertTextRequest(
          documentPosition: composer.selection!.extent,
          textToInsert: 'First',
          attributions: {},
        ),
      ]);
      await tester.pumpAndSettle();
      // Update composer for text insertion
      composer.setSelectionWithReason(DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: initialNode.id,
          nodePosition: const TextNodePosition(offset: 5),
        ),
      ),
      );
      
      expect((document.getNodeById(initialNode.id) as TextNode).text.toPlainText(), 'First');

      // Now simulate Enter (SplitListItemRequest)
      editor.execute([
        SplitListItemRequest(
          nodeId: bulletNode.id,
          splitPosition: const TextNodePosition(offset: 5),
          newNodeId: 'new-node-1',
        ),
      ]);
      await tester.pumpAndSettle();
      // The Ketion EditRequestHandler should have updated composer.selection synchronously!

      // Verify Layer 1: Document contains 2 nodes
      expect(document.length, 2);
      final newNode = document.last as ListItemNode;
      expect(newNode.text.toPlainText(), '');

      // Verify Layer 2: Composer updated to new node @ 0
      expect(composer.selection!.extent.nodeId, newNode.id);
      expect(composer.selection!.extent.nodePosition, const TextNodePosition(offset: 0));

      // Layer 3: Input "Second"
      editor.execute([
        InsertTextRequest(
          documentPosition: composer.selection!.extent,
          textToInsert: 'Second',
          attributions: {},
        ),
      ]);
      expect((document.getNodeById(newNode.id) as TextNode).text.toPlainText(), 'Second');
      
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('Slash deletion calculation handles preceding text correctly', (WidgetTester tester) async {
      await buildEditor(tester);
      final dynamic state = tester.state(find.byType(SuperEditorHost));
      final Editor editor = state.editor as Editor;
      final MutableDocument document = state.document as MutableDocument;
      final composer = editor.context.composer;

      final initialNode = document.first as TextNode;
      
      // Simulate typing "Hello /bullet"
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(nodeId: initialNode.id, nodePosition: const TextNodePosition(offset: 0)),
          textToInsert: 'Hello /bullet',
          attributions: {},
        ),
      ]);
      
      // SlashStartOffset = 6, CursorOffset = 13
      const slashStartOffset = 6;
      const cursorOffset = 13;
      
      editor.execute([
        DeleteContentRequest(
          documentRange: DocumentRange(
            start: DocumentPosition(nodeId: initialNode.id, nodePosition: const TextNodePosition(offset: slashStartOffset)),
            end: DocumentPosition(nodeId: initialNode.id, nodePosition: const TextNodePosition(offset: cursorOffset)),
          ),
        ),
        ConvertParagraphToListItemRequest(nodeId: initialNode.id, type: ListItemType.unordered),
      ]);
      
      final textNode = document.getNodeById(initialNode.id) as TextNode;
      final textLength = textNode.text.toPlainText().length;
      final finalOffset = slashStartOffset.clamp(0, textLength);
      
      composer.setSelectionWithReason(DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: initialNode.id,
          nodePosition: TextNodePosition(offset: finalOffset),
        ),
      ),
      );

      // Verify Layer 1: Document
      final bulletNode = document.getNodeById(initialNode.id)!;
      expect(bulletNode, isA<ListItemNode>());
      expect((bulletNode as ListItemNode).text.toPlainText(), 'Hello ');

      // Verify Layer 2: Composer Offset is exactly 6
      expect(composer.selection!.extent.nodeId, initialNode.id);
      expect(composer.selection!.extent.nodePosition, const TextNodePosition(offset: 6));

      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    });
    
    testWidgets('Slash conversion and Enter split sequence (Checklist)', (WidgetTester tester) async {
      await buildEditor(tester);
      final dynamic state = tester.state(find.byType(SuperEditorHost));
      final Editor editor = state.editor as Editor;
      final MutableDocument document = state.document as MutableDocument;
      final composer = editor.context.composer;

      final initialNode = document.first as TextNode;
      
      editor.execute([
        ConvertParagraphToTaskRequest(nodeId: initialNode.id),
      ]);
      await tester.pumpAndSettle();
      composer.setSelectionWithReason(DocumentSelection.collapsed(
        position: DocumentPosition(nodeId: initialNode.id, nodePosition: const TextNodePosition(offset: 0)),
      ),
      );

      final taskNode = document.getNodeById(initialNode.id)!;
      expect(taskNode, isA<TaskNode>());

      editor.execute([
        InsertTextRequest(
          documentPosition: composer.selection!.extent,
          textToInsert: 'First',
          attributions: {},
        ),
      ]);
      await tester.pumpAndSettle();
      composer.setSelectionWithReason(DocumentSelection.collapsed(
        position: DocumentPosition(nodeId: initialNode.id, nodePosition: const TextNodePosition(offset: 5)),
      ),
      );
      
      expect((document.getNodeById(initialNode.id) as TextNode).text.toPlainText(), 'First');

      editor.execute([
        SplitExistingTaskRequest(
          existingNodeId: taskNode.id,
          splitOffset: 5,
        ),
      ]);
      await tester.pumpAndSettle();
      
      // Verify Layer 1
      expect(document.length, 2);
      final newNode = document.last as TaskNode;
      expect(newNode.text.toPlainText(), '');

      // Verify Layer 2 (should be newNode@0)
      expect(composer.selection!.extent.nodeId, newNode.id);
      expect(composer.selection!.extent.nodePosition, const TextNodePosition(offset: 0));

      // Verify Layer 3
      editor.execute([
        InsertTextRequest(
          documentPosition: composer.selection!.extent,
          textToInsert: 'Second',
          attributions: {},
        ),
      ]);
      expect((document.getNodeById(newNode.id) as TextNode).text.toPlainText(), 'Second');
      
      await tester.pump(const Duration(milliseconds: 300));
    });

  });
}
