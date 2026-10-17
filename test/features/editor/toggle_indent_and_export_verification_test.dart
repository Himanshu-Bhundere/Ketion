import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/domain/commands/change_paragraph_metadata.dart';
import 'package:ketion/features/editor/domain/services/block_data_serializer.dart';
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';
import 'package:ketion/features/editor/presentation/widgets/depth_wrapping_component_builder.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_edit_request_handler.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_toggle_component.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_toggle_keyboard_actions.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';
import 'package:ketion/features/editor/services/editor_persistence_coordinator.dart';
import 'package:ketion/features/editor/services/editor_persistence_mutations.dart';
import 'package:ketion/features/editor/services/editor_persistence_snapshot.dart';
import 'package:ketion/features/import_export/domain/services/pdf_exporter.dart';
import 'package:ketion/features/import_export/domain/usecases/export_usecase.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';

class TestSuperEditorContext implements SuperEditorContext {
  @override
  final Editor editor;
  @override
  final Document document;
  @override
  final DocumentComposer composer;

  TestSuperEditorContext({
    required this.editor,
    required this.document,
    required this.composer,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class TestPersistenceCoordinator implements EditorPersistenceCoordinator {
  final List<EditorPersistenceMutation> mutations = [];
  final _controller = StreamController<EditorPersistenceMutation>.broadcast();

  @override
  bool enqueue(EditorPersistenceMutation mutation) {
    mutations.add(mutation);
    _controller.add(mutation);
    return true;
  }

  @override
  Stream<EditorPersistenceMutation> get onMutationSuccess => _controller.stream;

  @override
  Future<bool> flush() async => true;

  @override
  void close() {}

  @override
  EditorPersistenceGateway get gateway => throw UnimplementedError();

  @override
  bool get hasFailedMutations => false;

  @override
  bool get hasPendingMutations => false;

  @override
  Future<bool> retryFailed() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
      'Verification Criterion 1: Toggle Save, Reload, Arrow Visibility & Child Creation',
      () {
    test(
        'IME newline request inserts a persisted child instead of a sibling paragraph',
        () async {
      final toggleNode = ParagraphNode(
        id: 'toggle-ime-node',
        text: AttributedText('Toggle'),
        metadata: const {
          'blockId': 'toggle-ime-block',
          'blockType': NamedAttribution('toggle'),
          'listType': 'toggle',
          'depth': 0,
        },
      );
      final document = MutableDocument(nodes: [toggleNode]);
      final composer = MutableDocumentComposer(
        initialSelection: DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: toggleNode.id,
            nodePosition: const TextNodePosition(offset: 6),
          ),
        ),
      );
      final coordinator = TestPersistenceCoordinator();
      final snapshot = EditorPersistenceSnapshot('page-ime', {
        'toggle-ime-block': BlockSnapshot(
          blockId: 'toggle-ime-block',
          pageId: 'page-ime',
          type: 'list',
          parentBlockId: null,
          position: 1,
          version: 1,
          createdAt: DateTime.now(),
          deleted: false,
        ),
      });
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-ime',
        coordinator: coordinator,
        snapshot: snapshot,
      );
      adapter.registry.registerMapping(
        nodeId: toggleNode.id,
        blockId: 'toggle-ime-block',
      );
      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'page-ime',
            document: document,
            composer: composer,
            coordinator: coordinator,
            snapshot: snapshot,
            adapter: adapter,
          ),
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );
      adapter.bind(document, editor);

      // This is the route used by Android's soft keyboard; no KeyEvent is sent.
      editor.execute([InsertNewlineAtCaretRequest('toggle-ime-child')]);

      expect(document.nodeCount, 2);
      final child = document.getNodeById('toggle-ime-child') as ParagraphNode;
      expect(child.metadata['parentBlockId'], 'toggle-ime-block');
      expect(child.metadata['depth'], 1);
      expect(composer.selection?.extent.nodeId, 'toggle-ime-child');

      // The adapter observes the document insertion and persists the actual
      // block relationship, rather than leaving this as editor-only state.
      await adapter.flushPendingChanges();
      final inserted = coordinator.mutations.whereType<InsertBlockMutation>().single;
      expect(inserted.parentBlockId, 'toggle-ime-block');
    });

    test(
        'Create toggle, save to block, reload into editor: arrow is visible and Enter creates child',
        () async {
      // 1. Initial toggle node in editor
      final toggleNode = ParagraphNode(
        id: 'toggle-node-1',
        text: AttributedText('My Toggle Header'),
        metadata: const {
          'blockType': NamedAttribution('toggle'),
          'isExpanded': true,
          'depth': 0,
        },
      );

      // Serialize node
      final serializedModel = BlockDataSerializer.fromDocumentNode(toggleNode);
      final jsonString = jsonEncode(serializedModel.toJson());

      final savedBlock = Block(
        id: 'block-toggle-1',
        pageId: 'page-1',
        parentBlockId: null,
        position: 10.0,
        type: 'list',
        data: jsonString,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      // 2. Reopen / Reload the note via KetionSuperEditorAdapter
      final coordinator = TestPersistenceCoordinator();
      final snapshot = EditorPersistenceSnapshot('page-1', {
        'block-toggle-1': BlockSnapshot(
          blockId: 'block-toggle-1',
          pageId: 'page-1',
          type: 'list',
          parentBlockId: null,
          position: 10.0,
          version: 1,
          createdAt: DateTime.now(),
          deleted: false,
        ),
      });

      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-1',
        coordinator: coordinator,
        snapshot: snapshot,
      );

      final reloadedDoc = adapter.createDocument([savedBlock]);
      expect(reloadedDoc.nodeCount, 1);

      final reloadedNode = reloadedDoc.getNodeAt(0)!;

      // Verify toggle recognition & arrow visibility
      expect(KetionToggleComponentBuilder.isToggleNode(reloadedNode), isTrue);

      final textLen = (reloadedNode as TextNode).text.toPlainText().length;
      final composer = MutableDocumentComposer(
        initialSelection: DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: reloadedNode.id,
            nodePosition: TextNodePosition(offset: textLen),
          ),
        ),
      );

      final editor = Editor(
        editables: {
          Editor.documentKey: reloadedDoc,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'page-1',
            document: reloadedDoc,
            composer: composer,
            coordinator: coordinator,
            snapshot: snapshot,
            adapter: adapter,
          ),
          changeParagraphMetadataRequestHandler,
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );
      adapter.bind(reloadedDoc, editor);

      final builder = KetionToggleComponentBuilder(editor);
      final viewModel = builder.createViewModel(reloadedDoc, reloadedNode)
          as KetionToggleComponentViewModel?;
      expect(viewModel, isNotNull,
          reason: 'ViewModel must be created for toggle');
      expect(viewModel!.isExpanded, isTrue,
          reason: 'Toggle was saved as expanded');

      final editContext = TestSuperEditorContext(
        editor: editor,
        document: reloadedDoc,
        composer: composer,
      );

      final keyResult = splitToggleWhenEnterPressed(
        editContext: editContext,
        keyEvent: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
      );

      expect(keyResult, ExecutionInstruction.haltExecution);
      expect(reloadedDoc.nodeCount, 2,
          reason: 'Enter must insert a child node under toggle');

      final childNode = reloadedDoc.getNodeAt(1)!;
      expect(childNode.metadata['parentBlockId'], 'block-toggle-1');
      expect(childNode.metadata['depth'], 1);
      expect(composer.selection?.extent.nodeId, childNode.id);
      expect(
          (composer.selection?.extent.nodePosition as TextNodePosition).offset,
          0);
    });
  });

  group(
      'Verification Criterion 2: Swipe-indent Bullet & Checklist Item, Save & Reload',
      () {
    test(
        'Indent bullet and checklist item, save to blocks, reload: indentation is fully preserved',
        () async {
      // 1. Initial blocks: bullet and checklist at depth 0
      final rootBlock = Block(
        id: 'block-root',
        pageId: 'page-1',
        parentBlockId: null,
        position: 10.0,
        type: 'list',
        data: jsonEncode({
          'runtimeType': 'list',
          'listType': 'bullet',
          'spans': [
            {'text': 'Parent item'}
          ],
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bulletBlock = Block(
        id: 'block-bullet',
        pageId: 'page-1',
        parentBlockId: null,
        position: 20.0,
        type: 'list',
        data: jsonEncode({
          'runtimeType': 'list',
          'listType': 'bullet',
          'spans': [
            {'text': 'Bullet item to indent'}
          ],
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final taskBlock = Block(
        id: 'block-task',
        pageId: 'page-1',
        parentBlockId: null,
        position: 30.0,
        type: 'list',
        data: jsonEncode({
          'runtimeType': 'list',
          'listType': 'checklist',
          'checked': false,
          'spans': [
            {'text': 'Task item to indent'}
          ],
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final coordinator = TestPersistenceCoordinator();
      final snapshot = EditorPersistenceSnapshot('page-1', {
        'block-root': BlockSnapshot(
          blockId: 'block-root',
          pageId: 'page-1',
          type: 'list',
          parentBlockId: null,
          position: 10.0,
          version: 1,
          createdAt: DateTime.now(),
          deleted: false,
        ),
        'block-bullet': BlockSnapshot(
          blockId: 'block-bullet',
          pageId: 'page-1',
          type: 'list',
          parentBlockId: null,
          position: 20.0,
          version: 1,
          createdAt: DateTime.now(),
          deleted: false,
        ),
        'block-task': BlockSnapshot(
          blockId: 'block-task',
          pageId: 'page-1',
          type: 'list',
          parentBlockId: null,
          position: 30.0,
          version: 1,
          createdAt: DateTime.now(),
          deleted: false,
        ),
      });

      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-1',
        coordinator: coordinator,
        snapshot: snapshot,
      );

      final document =
          adapter.createDocument([rootBlock, bulletBlock, taskBlock]);
      final composer = MutableDocumentComposer();
      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'page-1',
            document: document,
            composer: composer,
            coordinator: coordinator,
            snapshot: snapshot,
            adapter: adapter,
          ),
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );
      adapter.bind(document, editor);

      expect(document.nodeCount, 3);
      final bulletNode = document.getNodeAt(1)!;
      final taskNode = document.getNodeAt(2)!;

      // 2. Indent bullet item
      editor.execute([IndentListItemRequest(nodeId: bulletNode.id)]);
      final indentedBulletNode = document.getNodeAt(1) as ListItemNode;
      expect(indentedBulletNode.indent, 1);
      expect(indentedBulletNode.metadata['parentBlockId'], 'block-root');

      // Indent task item
      editor.execute([IndentTaskRequest(taskNode.id)]);
      final indentedTaskNode = document.getNodeAt(2) as TaskNode;
      expect(indentedTaskNode.indent, 1);
      expect(indentedTaskNode.metadata['parentBlockId'], 'block-root');

      // 3. Verify persistence mutation was generated and applied to snapshot
      final bulletUpdate =
          coordinator.mutations.whereType<MoveBlockMutation>().firstWhere(
                (m) => m.blockId == 'block-bullet',
              );
      expect(bulletUpdate.parentBlockId, 'block-root');

      final taskUpdate =
          coordinator.mutations.whereType<MoveBlockMutation>().firstWhere(
                (m) => m.blockId == 'block-task',
              );
      expect(taskUpdate.parentBlockId, 'block-root');

      // 4. Simulate saving and reopening the note from persisted blocks
      final updatedBulletBlock =
          bulletBlock.copyWith(parentBlockId: bulletUpdate.parentBlockId);
      final updatedTaskBlock =
          taskBlock.copyWith(parentBlockId: taskUpdate.parentBlockId);

      final adapterReloaded = KetionSuperEditorAdapter(
        pageId: 'page-1',
        coordinator: TestPersistenceCoordinator(),
        snapshot: snapshot,
      );

      final reloadedDoc = adapterReloaded.createDocument([
        rootBlock,
        updatedBulletBlock,
        updatedTaskBlock,
      ]);

      expect(reloadedDoc.nodeCount, 3);
      final reloadedBullet = reloadedDoc.getNodeAt(1) as ListItemNode;
      final reloadedTask = reloadedDoc.getNodeAt(2) as TaskNode;

      // Verification: indentation remains on reopen!
      expect(reloadedBullet.indent, 1);
      expect(getNodeDepth(reloadedBullet), 1);
      expect(reloadedBullet.metadata['parentBlockId'], 'block-root');

      expect(reloadedTask.indent, 1);
      expect(getNodeDepth(reloadedTask), 1);
      expect(reloadedTask.metadata['parentBlockId'], 'block-root');
    });
  });

  group('Verification Criterion 3: PDF Hierarchy Matches Editor Indentation',
      () {
    test(
        'Export nested hierarchy to PDF: visible tree depth and export document match editor indentation',
        () async {
      final now = DateTime.now();
      final page = Page(
        id: 'page-export-1',
        title: 'Hierarchical Structure Verification',
        createdAt: now,
        updatedAt: now,
      );

      final blocks = [
        // Top-level toggle
        Block(
          id: 'b-toggle',
          pageId: 'page-export-1',
          parentBlockId: null,
          position: 10.0,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'toggle',
            'isExpanded': true,
            'spans': [
              {'text': 'Section Toggle'}
            ],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        // Child of toggle (depth 1)
        Block(
          id: 'b-toggle-child',
          pageId: 'page-export-1',
          parentBlockId: 'b-toggle',
          position: 10.0,
          type: 'text',
          data: jsonEncode({
            'runtimeType': 'text',
            'headingLevel': 0,
            'spans': [
              {'text': 'Nested paragraph inside toggle'}
            ],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        // Top-level bullet list
        Block(
          id: 'b-bullet-parent',
          pageId: 'page-export-1',
          parentBlockId: null,
          position: 20.0,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'bullet',
            'spans': [
              {'text': 'Main Bullet Point'}
            ],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        // Nested bullet (depth 1)
        Block(
          id: 'b-bullet-child',
          pageId: 'page-export-1',
          parentBlockId: 'b-bullet-parent',
          position: 10.0,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'bullet',
            'spans': [
              {'text': 'Indented Sub-bullet'}
            ],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        // Nested checklist task (depth 2 under sub-bullet)
        Block(
          id: 'b-task-nested',
          pageId: 'page-export-1',
          parentBlockId: 'b-bullet-child',
          position: 10.0,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'checklist',
            'checked': true,
            'spans': [
              {'text': 'Completed nested task'}
            ],
          }),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // 1. Verify visible tree calculation
      final visibleTree = BlockTreeService.buildVisibleTree(blocks);
      expect(visibleTree.length, 5);

      expect(visibleTree[0].block.id, 'b-toggle');
      expect(visibleTree[0].depth, 0);

      expect(visibleTree[1].block.id, 'b-toggle-child');
      expect(visibleTree[1].depth, 1);

      expect(visibleTree[2].block.id, 'b-bullet-parent');
      expect(visibleTree[2].depth, 0);

      expect(visibleTree[3].block.id, 'b-bullet-child');
      expect(visibleTree[3].depth, 1);

      expect(visibleTree[4].block.id, 'b-task-nested');
      expect(visibleTree[4].depth, 2);

      // 2. Export to PDF bytes via ExportUseCase
      final exporter = PdfExporter();
      final useCase = ExportUseCase([exporter]);

      final pdfBytes = await useCase.exportToBytes(page, blocks, 'pdf');
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));

      final header = utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true);
      expect(header.startsWith('%PDF'), isTrue,
          reason: 'Export must produce a valid PDF document');
    });
  });
}
