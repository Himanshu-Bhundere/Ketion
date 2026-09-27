import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:super_editor/super_editor.dart';

import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/blocks/data/repositories/block_repository_impl.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart' as domain;
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/features/pages/data/repositories/page_repository_impl.dart';
import 'package:ketion/core/utils/logger.dart';
import 'package:drift/drift.dart' as drift;

import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/editor/presentation/providers/editor_state_provider.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/sync/presentation/providers/sync_providers.dart';
import 'package:ketion/features/editor/domain/models/drop_intent.dart';
import 'package:ketion/features/editor/presentation/widgets/editor_history_controller.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_host.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';

void main() {
  late AppDatabase database;
  late BlockRepositoryImpl blockRepo;
  late PageRepositoryImpl pageRepo;

  late SyncQueueRepositoryImpl syncQueue;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    syncQueue = SyncQueueRepositoryImpl(database);
    final logger = AppLogger();
    blockRepo = BlockRepositoryImpl(database, syncQueue, logger);
    pageRepo = PageRepositoryImpl(database, syncQueue, logger);
  });

  tearDown(() {
    database.close();
  });

  String textData(String text) {
    return jsonEncode({
      'spans': [
        {'text': text},
      ],
      'headingLevel': 0,
    });
  }

  Future<void> pumpUntilInitialized(WidgetTester tester) async {
    int attempts = 0;
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
        attempts < 50) {
      await tester.pump(const Duration(milliseconds: 50));
      attempts++;
    }
    if (attempts >= 50) {
      throw Exception(
        'pumpUntilInitialized timed out waiting for CircularProgressIndicator to disappear',
      );
    }
    await tester.pump(const Duration(milliseconds: 50));
  }

  Widget buildTestApp(String pageId) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        syncQueueRepositoryProvider.overrideWithValue(syncQueue),
        blockRepositoryProvider.overrideWithValue(blockRepo),
        pageRepositoryProvider.overrideWithValue(pageRepo),
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

  group('Block Movement Persistence & Lifecycle Tests', () {
    testWidgets('Drag block1 before block2 persists in SQLite and survives reload', (tester) async {
      const String pageId = 'test-page-move';

      // 1. Setup Data in DB
      await database.into(database.pages).insert(
            PagesCompanion.insert(
              id: pageId,
              title: const drift.Value('Test Movement Page'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final block1 = domain.Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        data: textData('Block 1'),
        position: 1.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final block2 = domain.Block(
        id: 'block2',
        pageId: pageId,
        type: 'text',
        data: textData('Block 2'),
        position: 2.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await blockRepo.createBlock(block1);
      await blockRepo.createBlock(block2);

      // 2. Load Editor UI
      await tester.pumpWidget(buildTestApp(pageId));
      await pumpUntilInitialized(tester);

      // Verify Initial State in Document
      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final document = hostState.document as MutableDocument;

      expect(document.nodeCount, 2);
      expect((document.first as TextNode).text.toPlainText(), 'Block 1');
      expect((document.last as TextNode).text.toPlainText(), 'Block 2');

      // 3. Simulate DropIntent (drag block2 before block1)
      final providerContainer = ProviderScope.containerOf(tester.element(find.byType(SuperEditorHost)));
      await providerContainer
          .read(editorStateProvider(pageId).notifier)
          .handleDropIntent('block2', const DropIntent.before('block1'));

      await tester.pump(const Duration(milliseconds: 350));

      // Flush persistence explicitly
      final adapter = hostState.adapter as KetionSuperEditorAdapter;
      await adapter.flushPendingChanges();

      // 4. Verify SQLite directly
      final dbBlocks = await (database.select(database.blocks)
            ..where((t) => t.pageId.equals(pageId))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.position, mode: drift.OrderingMode.asc)]))
          .get();

      expect(dbBlocks.length, 2);

      expect(dbBlocks[0].id, 'block2');
      expect(dbBlocks[1].id, 'block1');
      expect(dbBlocks[0].position < dbBlocks[1].position, isTrue);

      // 5. Close editor and Re-open (simulate reload)
      await tester.pumpWidget(Container()); // unmount
      await tester.pumpWidget(buildTestApp(pageId)); // mount new instance
      await pumpUntilInitialized(tester);

      final newHostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final newDocument = newHostState.document as MutableDocument;

      // 6. Verify SuperEditor Document after reload
      expect(newDocument.nodeCount, 2);
      expect((newDocument.first as TextNode).text.toPlainText(), 'Block 2');
      expect((newDocument.last as TextNode).text.toPlainText(), 'Block 1');
    });

    testWidgets('Nest block2 as child of block1 persists and restores correctly', (tester) async {
      const String pageId = 'test-page-nest';

      await database.into(database.pages).insert(
            PagesCompanion.insert(
              id: pageId,
              title: const drift.Value('Test Nesting Page'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final block1 = domain.Block(
        id: 'block1',
        pageId: pageId,
        type: 'text',
        data: textData('Parent'),
        position: 1.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final block2 = domain.Block(
        id: 'block2',
        pageId: pageId,
        type: 'text',
        data: textData('Child'),
        position: 2.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await blockRepo.createBlock(block1);
      await blockRepo.createBlock(block2);

      await tester.pumpWidget(buildTestApp(pageId));
      await pumpUntilInitialized(tester);

      final providerContainer = ProviderScope.containerOf(tester.element(find.byType(SuperEditorHost)));
      await providerContainer
          .read(editorStateProvider(pageId).notifier)
          .handleDropIntent('block2', const DropIntent.child('block1'));

      await tester.pump(const Duration(milliseconds: 350));

      final hostState = tester.state(find.byType(SuperEditorHost)) as dynamic;
      final adapter = hostState.adapter as KetionSuperEditorAdapter;
      await adapter.flushPendingChanges();

      // Verify SQLite
      final dbBlocks = await (database.select(database.blocks)
            ..where((t) => t.pageId.equals(pageId))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.position, mode: drift.OrderingMode.asc)]))
          .get();

      final dbBlock1 = dbBlocks.firstWhere((b) => b.id == 'block1');
      final dbBlock2 = dbBlocks.firstWhere((b) => b.id == 'block2');

      expect(dbBlock1.parentBlockId, isNull);
      expect(dbBlock2.parentBlockId, 'block1');

      // Reload
      await tester.pumpWidget(Container());
      await tester.pumpWidget(buildTestApp(pageId));
      await pumpUntilInitialized(tester);

      // Verify in Super Editor (Ketion displays children somehow - if it doesn't display visually yet, 
      // the Block mapping still reflects it. We will verify via internal registry if needed).
      final newProviderContainer = ProviderScope.containerOf(tester.element(find.byType(SuperEditorHost)));
      final restoredBlock2 = newProviderContainer.read(editorStateProvider(pageId)).value!.firstWhere((b) => b.id == 'block2');
      expect(restoredBlock2.parentBlockId, 'block1');
    });
  });
}
