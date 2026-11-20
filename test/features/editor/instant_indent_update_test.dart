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
import 'package:ketion/features/editor/presentation/widgets/depth_wrapping_component_builder.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_host.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as page_entity;
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';

List<Block> _testBlocks = [];

class _MockGetPageBlocksUseCase implements GetPageBlocksUseCase {
  _MockGetPageBlocksUseCase(List<Block> initialBlocks) {
    _testBlocks = initialBlocks;
  }

  @override
  Future<Result<List<Block>>> call(String pageId) async {
    return Success(_testBlocks);
  }
}

class _DummyBlockRepository implements BlockRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<Block>> createBlock(Block block) async {
    _testBlocks.add(block);
    return Success(block);
  }

  @override
  Future<Result<void>> deleteBlock(String id, {required int expectedVersion}) async {
    _testBlocks.removeWhere((b) => b.id == id);
    return const Success(null);
  }

  @override
  Future<Result<Block>> getBlock(String id) async {
    final block = _testBlocks.firstWhere((b) => b.id == id);
    return Success(block);
  }

  @override
  Future<Result<List<Block>>> getBlocksForPage(String pageId) async => Success(_testBlocks);

  @override
  Future<Result<List<Block>>> getChildBlocks(String parentBlockId) async {
    return Success(_testBlocks.where((b) => b.parentBlockId == parentBlockId && !b.deleted).toList());
  }

  @override
  Future<Result<void>> updateBlock(Block block, {required int expectedVersion}) async {
    final index = _testBlocks.indexWhere((b) => b.id == block.id);
    if (index != -1) {
      _testBlocks[index] = block;
    }
    return const Success(null);
  }
}

Future<void> _pumpUntilReady(WidgetTester tester) async {
  int attempts = 0;
  while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty && attempts < 50) {
    await tester.pump(const Duration(milliseconds: 50));
    attempts++;
  }
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  const pageId = 'instant-indent-test-page';

  String textData(String text) => jsonEncode({
        'spans': [
          {
            'text': text,
            'bold': false,
            'italic': false,
            'underline': false,
            'strikethrough': false,
            'code': false,
            'link': null,
            'pageLink': null,
            'pageLinkTitle': null,
          }
        ],
        'headingLevel': 0,
      });

  Block makeTextBlock(String id, String text, {double position = 0.0, String? parentBlockId}) {
    return Block(
      id: id,
      pageId: pageId,
      type: 'text',
      position: position,
      parentBlockId: parentBlockId,
      data: textData(text),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  final testPage = page_entity.Page(
    id: pageId,
    title: 'Instant Indent Test Page',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget buildTestApp(List<Block> blocks) {
    return ProviderScope(
      overrides: [
        pageProvider(pageId).overrideWith((ref) => testPage),
        blockRepositoryProvider.overrideWithValue(_DummyBlockRepository()),
        getPageBlocksUseCaseProvider.overrideWithValue(_MockGetPageBlocksUseCase(blocks)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SuperEditorHost(
            pageId: pageId,
            onTitleChanged: (_) async => const Success(null),
            onIconChanged: (_) async => const Success(null),
          ),
        ),
      ),
    );
  }

  group('Instant Tab and Shift-Tab Indentation Visual Updates', () {
    testWidgets('Indenting and unindenting a paragraph visibly updates padding on next pump without moving selection', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final block1 = makeTextBlock('block-1', 'First line', position: 100.0);
      final block2 = makeTextBlock('block-2', 'Second line', position: 200.0);

      await tester.pumpWidget(buildTestApp([block1, block2]));
      await _pumpUntilReady(tester);

      final state = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final editor = state.editor as Editor;
      final adapter = state.adapter as KetionSuperEditorAdapter;
      final doc = state.document as MutableDocument;

      final node2 = doc.getNodeAt(1)!;

      // 1. Initial state: depth is 0
      expect(getNodeDepth(doc.getNodeById(node2.id)), 0);

      // Verify DepthIndentWrapper for node2 is present
      final wrapperFinder = find.byWidgetPredicate(
        (w) => w is DepthIndentWrapper && w.nodeId == node2.id,
      );
      expect(wrapperFinder, findsOneWidget);

      // Before indenting, no left-padded container inside DepthIndentWrapper
      Finder paddingFinder = find.descendant(
        of: wrapperFinder,
        matching: find.byWidgetPredicate(
          (w) => w is Padding && w.padding.resolve(TextDirection.ltr).left == 24.0,
        ),
      );
      expect(paddingFinder, findsNothing);

      // 2. Execute Indent (Tab equivalent)
      editor.execute([
        IndentParagraphRequest(node2.id),
      ]);
      await tester.pump();
      await adapter.flushPendingChanges();

      // Verify node metadata depth updated to 1
      expect(getNodeDepth(doc.getNodeById(node2.id)), 1);

      // CRITICAL VERIFICATION: Padding of 24.0 must be visibly present in DepthIndentWrapper immediately!
      paddingFinder = find.descendant(
        of: wrapperFinder,
        matching: find.byWidgetPredicate(
          (w) => w is Padding && w.padding.resolve(TextDirection.ltr).left == 24.0,
        ),
      );
      expect(
        paddingFinder,
        findsOneWidget,
        reason: 'Text must visibly indent by 24.0 instantly without clicking another line',
      );

      // 3. Execute Unindent (Shift-Tab equivalent)
      editor.execute([
        UnIndentParagraphRequest(node2.id),
      ]);
      await tester.pump();
      await adapter.flushPendingChanges();

      // Verify node metadata depth returned to 0
      expect(getNodeDepth(doc.getNodeById(node2.id)), 0);

      // CRITICAL VERIFICATION: Padding of 24.0 must be immediately removed without clicking another line!
      paddingFinder = find.descendant(
        of: wrapperFinder,
        matching: find.byWidgetPredicate(
          (w) => w is Padding && w.padding.resolve(TextDirection.ltr).left == 24.0,
        ),
      );
      expect(
        paddingFinder,
        findsNothing,
        reason: 'Text must visibly outdent instantly without clicking another line',
      );

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
