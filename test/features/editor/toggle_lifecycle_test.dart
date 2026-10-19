import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/editor/services/editor_persistence_mutations.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';
import 'package:ketion/features/editor/services/editor_persistence_coordinator.dart';
import 'package:ketion/features/editor/services/editor_persistence_snapshot.dart';
import 'package:ketion/features/editor/domain/commands/change_paragraph_metadata.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_edit_requests.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_edit_request_handler.dart';
import 'package:super_editor/super_editor.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/presentation/widgets/depth_wrapping_component_builder.dart';
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';

class MockPersistenceCoordinator implements EditorPersistenceCoordinator {
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
  group('Toggle Lifecycle Verification', () {
    test('collapsing and expanding a toggle should preserve children in cache',
        () async {
      final snapshot = EditorPersistenceSnapshot('page-1', {});
      final coordinator = MockPersistenceCoordinator();
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-1',
        coordinator: coordinator,
        snapshot: snapshot,
      );

      var block1 = Block(
        id: 'toggle-1',
        pageId: 'page-1',
        parentBlockId: null,
        position: 0,
        type: 'list',
        data: jsonEncode({
          'spans': [
            {'text': 'Toggle parent'},
          ],
          'listType': 'toggle',
          'isExpanded': true,
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      final childBlock = Block(
        id: 'child-1',
        pageId: 'page-1',
        parentBlockId: 'toggle-1',
        position: 0,
        type: 'text',
        data: jsonEncode({
          'spans': [
            {'text': 'Child'},
          ],
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      // 1. Create editor with expanded toggle
      final document = adapter.createDocument([block1, childBlock]);
      final editor = Editor(
        editables: {
          Editor.documentKey: document,
        },
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'page-1',
            document: document,
            composer: MutableDocumentComposer(),
            coordinator: coordinator,
            snapshot: snapshot,
            adapter: adapter,
          ),
          changeParagraphMetadataRequestHandler,
        ],
      );
      adapter.bind(document, editor);

      expect(document.nodeCount, 2, reason: 'Child should be loaded');

      final toggleNode = document.getNodeAt(0) as ParagraphNode;
      expect(toggleNode.metadata['isExpanded'], true);

      // 2. Collapse the toggle via ToggleExpandedRequest
      editor.execute([
        ToggleExpandedRequest(
          nodeId: toggleNode.id,
          isExpanded: false,
        ),
      ]);

      await adapter.flushPendingChanges();

      // At this point, the adapter intercepts the mutation and enqueues an UpdateBlockMutation
      final updateMutation = coordinator.mutations.lastWhere(
        (m) => m is UpdateBlockMutation && m.blockId == 'toggle-1',
      ) as UpdateBlockMutation;

      final updatedData = jsonDecode(updateMutation.data);
      expect(
        updatedData['isExpanded'],
        false,
        reason: 'Toggle should be saved as collapsed',
      );

      // Wait for the stream event to be processed by the adapter
      await Future<void>.delayed(Duration.zero);

      // Check the projection
      expect(
        document.nodeCount,
        1,
        reason: 'Child node was removed from SuperEditor when collapsed',
      );

      // 3. Simulate Restart / Reload
      block1 = block1.copyWith(data: updateMutation.data);

      final adapter2 = KetionSuperEditorAdapter(
        pageId: 'page-1',
        coordinator: MockPersistenceCoordinator(),
        snapshot: EditorPersistenceSnapshot('page-1', {}),
      );

      final document2 = adapter2.createDocument([block1, childBlock]);

      // Because isExpanded is false, the child is omitted from createDocument, but kept in hidden node cache
      expect(
        document2.nodeCount,
        1,
        reason: 'Child node omitted on reload because parent is collapsed',
      );

      // 4. Expand the toggle via ToggleExpandedRequest
      final editor2 = Editor(
        editables: {
          Editor.documentKey: document2,
        },
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter2.registry,
            pageId: 'page-1',
            document: document2,
            composer: MutableDocumentComposer(),
            coordinator: adapter2.coordinator,
            snapshot: adapter2.snapshot,
            adapter: adapter2,
          ),
          changeParagraphMetadataRequestHandler,
        ],
      );
      adapter2.bind(document2, editor2);

      editor2.execute([
        ToggleExpandedRequest(
          nodeId: document2.getNodeAt(0)!.id,
          isExpanded: true,
        ),
      ]);

      await adapter2.flushPendingChanges();
      // Wait for the stream event to be processed by the adapter
      await Future<void>.delayed(Duration.zero);

      expect(
        document2.nodeCount,
        2,
        reason: 'Child node is restored from cache when toggle is expanded!',
      );
      final restoredChildNode = document2.getNodeAt(1);
      final childBlockId =
          adapter2.registry.blockIdForNode(restoredChildNode!.id);
      expect(childBlockId, 'child-1');
    });

    test('nested toggles: expanding outer toggle preserves inner toggle collapsed state',
        () async {
      final snapshot = EditorPersistenceSnapshot('page-1', {});
      final coordinator = MockPersistenceCoordinator();
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-1',
        coordinator: coordinator,
        snapshot: snapshot,
      );

      final outerToggle = Block(
        id: 'toggle-outer',
        pageId: 'page-1',
        parentBlockId: null,
        position: 0,
        type: 'list',
        data: jsonEncode({
          'spans': [{'text': 'Outer Toggle'}],
          'listType': 'toggle',
          'isExpanded': false,
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      final innerToggle = Block(
        id: 'toggle-inner',
        pageId: 'page-1',
        parentBlockId: 'toggle-outer',
        position: 0,
        type: 'list',
        data: jsonEncode({
          'spans': [{'text': 'Inner Toggle'}],
          'listType': 'toggle',
          'isExpanded': false,
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      final innerChild = Block(
        id: 'inner-child',
        pageId: 'page-1',
        parentBlockId: 'toggle-inner',
        position: 0,
        type: 'text',
        data: jsonEncode({
          'spans': [{'text': 'Deep nested content'}],
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      // On initial document creation, both are collapsed so only outer toggle is visible
      final document =
          adapter.createDocument([outerToggle, innerToggle, innerChild]);
      expect(document.nodeCount, 1);
      expect(
        (document.getNodeAt(0) as ParagraphNode).text.toPlainText(),
        'Outer Toggle',
      );

      final editor = Editor(
        editables: {Editor.documentKey: document},
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'page-1',
            document: document,
            composer: MutableDocumentComposer(),
            coordinator: coordinator,
            snapshot: snapshot,
            adapter: adapter,
          ),
          changeParagraphMetadataRequestHandler,
        ],
      );
      adapter.bind(document, editor);

      // Expand outer toggle
      editor.execute([
        ToggleExpandedRequest(
          nodeId: document.getNodeAt(0)!.id,
          isExpanded: true,
        ),
      ]);
      await adapter.flushPendingChanges();
      await Future<void>.delayed(Duration.zero);

      // Outer is expanded: now inner toggle is visible (2 nodes), BUT innerChild remains hidden!
      expect(document.nodeCount, 2);
      expect(
        (document.getNodeAt(1) as ParagraphNode).text.toPlainText(),
        'Inner Toggle',
      );

      // Expand inner toggle
      editor.execute([
        ToggleExpandedRequest(
          nodeId: document.getNodeAt(1)!.id,
          isExpanded: true,
        ),
      ]);
      await adapter.flushPendingChanges();
      await Future<void>.delayed(Duration.zero);

      // Both expanded: all 3 nodes visible
      expect(document.nodeCount, 3);
      expect(
        (document.getNodeAt(2) as ParagraphNode).text.toPlainText(),
        'Deep nested content',
      );
    });

    test('Insert child via InsertNodeAfterNodeRequest sets parentBlockId in persistence',
        () async {
      final snapshot = EditorPersistenceSnapshot('page-1', {});
      final coordinator = MockPersistenceCoordinator();
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-1',
        coordinator: coordinator,
        snapshot: snapshot,
      );

      final toggle = Block(
        id: 'toggle-p',
        pageId: 'page-1',
        parentBlockId: null,
        position: 0,
        type: 'list',
        data: jsonEncode({
          'spans': [{'text': 'Parent Toggle'}],
          'listType': 'toggle',
          'isExpanded': true,
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      final document = adapter.createDocument([toggle]);
      final editor = Editor(
        editables: {Editor.documentKey: document},
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'page-1',
            document: document,
            composer: MutableDocumentComposer(),
            coordinator: coordinator,
            snapshot: snapshot,
            adapter: adapter,
          ),
          changeParagraphMetadataRequestHandler,
        ],
      );
      adapter.bind(document, editor);

      final childNodeId = Editor.createNodeId();
      editor.execute([
        InsertNodeAfterNodeRequest(
          existingNodeId: document.getNodeAt(0)!.id,
          newNode: ParagraphNode(
            id: childNodeId,
            text: AttributedText('New Child Content'),
            metadata: {
              'depth': 1,
              'parentBlockId': document.getNodeAt(0)!.id,
            },
          ),
        ),
      ]);

      await adapter.flushPendingChanges();
      await Future<void>.delayed(Duration.zero);

      final insertMutation = coordinator.mutations.lastWhere(
        (m) => m is InsertBlockMutation,
      ) as InsertBlockMutation;

      expect(
        insertMutation.parentBlockId,
        'toggle-p',
        reason: 'Child block must persist parentBlockId = toggle-p',
      );
    });

    test('InsertNewlineAtCaretRequest at end of collapsed toggle expands it and inserts child',
        () async {
      final snapshot = EditorPersistenceSnapshot('page-1', {});
      final coordinator = MockPersistenceCoordinator();
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-1',
        coordinator: coordinator,
        snapshot: snapshot,
      );

      final toggle = Block(
        id: 'toggle-collapsed',
        pageId: 'page-1',
        parentBlockId: null,
        position: 0,
        type: 'list',
        data: jsonEncode({
          'spans': [
            {'text': 'Heading'},
          ],
          'listType': 'toggle',
          'isExpanded': false,
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      final document = adapter.createDocument([toggle]);
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
          changeParagraphMetadataRequestHandler,
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );
      adapter.bind(document, editor);

      // Place caret at end of toggle heading
      final toggleNode = document.getNodeAt(0)! as ParagraphNode;
      composer.setSelectionWithReason(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: toggleNode.id,
            nodePosition: TextNodePosition(offset: toggleNode.text.length),
          ),
        ),
      );

      // Press Enter (software IME or hardware)
      editor.execute([
        InsertNewlineAtCaretRequest(),
      ]);

      await adapter.flushPendingChanges();
      await Future<void>.delayed(Duration.zero);

      // Should expand toggle and insert new child block
      expect(document.getNodeById(toggleNode.id)!.metadata['isExpanded'], isTrue);
      expect(document.nodeCount, 2);

      final childNode = document.getNodeAt(1)! as ParagraphNode;
      expect(childNode.metadata['parentBlockId'], 'toggle-collapsed');
      expect(childNode.metadata['depth'], 1);

      // Caret should be inside new child
      expect(composer.selection?.extent.nodeId, childNode.id);
    });

    test('exitToggle exits descendant to outside sibling or creates new outside paragraph',
        () async {
      final snapshot = EditorPersistenceSnapshot('page-1', {});
      final coordinator = MockPersistenceCoordinator();
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-1',
        coordinator: coordinator,
        snapshot: snapshot,
      );

      final toggle = Block(
        id: 'toggle-exit',
        pageId: 'page-1',
        parentBlockId: null,
        position: 0,
        type: 'list',
        data: jsonEncode({
          'spans': [
            {'text': 'Parent'},
          ],
          'listType': 'toggle',
          'isExpanded': true,
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      final child = Block(
        id: 'child-exit',
        pageId: 'page-1',
        parentBlockId: 'toggle-exit',
        position: 0,
        type: 'text',
        data: jsonEncode({
          'spans': [
            {'text': 'Child item'},
          ],
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      final document = adapter.createDocument([toggle, child]);
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
          changeParagraphMetadataRequestHandler,
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );
      adapter.bind(document, editor);

      final childNode = document.getNodeAt(1)!;
      // Call exitToggle on the child node
      exitToggle(
        editor: editor,
        document: document,
        nodeId: childNode.id,
      );

      await adapter.flushPendingChanges();
      await Future<void>.delayed(Duration.zero);

      // Since child was last node in doc, a new sibling paragraph outside the toggle was created
      expect(document.nodeCount, 3);
      final outsideNode = document.getNodeAt(2)! as ParagraphNode;
      expect(outsideNode.metadata['depth'], 0);
      expect(outsideNode.metadata['parentBlockId'], isNull);
      expect(composer.selection?.extent.nodeId, outsideNode.id);
    });

    test(
        'InsertNewlineAtCaretRequest at end of toggle with existing children appends new child to end of subtree',
        () async {
      final snapshot = EditorPersistenceSnapshot('page-1', {});
      final coordinator = MockPersistenceCoordinator();
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-1',
        coordinator: coordinator,
        snapshot: snapshot,
      );

      final toggle = Block(
        id: 'toggle-multi',
        pageId: 'page-1',
        parentBlockId: null,
        position: 0,
        type: 'list',
        data: jsonEncode({
          'spans': [
            {'text': 'Parent Toggle'},
          ],
          'listType': 'toggle',
          'isExpanded': true,
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      final child1 = Block(
        id: 'child-1',
        pageId: 'page-1',
        parentBlockId: 'toggle-multi',
        position: 0,
        type: 'text',
        data: jsonEncode({
          'spans': [
            {'text': 'First child'},
          ],
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      final child2 = Block(
        id: 'child-2',
        pageId: 'page-1',
        parentBlockId: 'toggle-multi',
        position: 1,
        type: 'text',
        data: jsonEncode({
          'spans': [
            {'text': 'Second child'},
          ],
        }),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
      );

      final document = adapter.createDocument([toggle, child1, child2]);
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
          changeParagraphMetadataRequestHandler,
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );
      adapter.bind(document, editor);

      // Place caret at end of toggle heading
      final toggleNode = document.getNodeAt(0)! as ParagraphNode;
      composer.setSelectionWithReason(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: toggleNode.id,
            nodePosition: TextNodePosition(offset: toggleNode.text.length),
          ),
        ),
      );

      // Execute newline at end of toggle heading
      editor.execute([
        InsertNewlineAtCaretRequest(),
      ]);

      await adapter.flushPendingChanges();
      await Future<void>.delayed(Duration.zero);

      // Total nodes should now be 4: toggle, child1, child2, child3
      expect(document.nodeCount, 4);
      final firstChildInDoc = document.getNodeAt(1)! as ParagraphNode;
      expect(firstChildInDoc.text.toPlainText(), 'First child');

      final secondChildInDoc = document.getNodeAt(2)! as ParagraphNode;
      expect(secondChildInDoc.text.toPlainText(), 'Second child');

      // The new child must be at index 3 (end of subtree, NOT index 1)
      final newChild = document.getNodeAt(3)! as ParagraphNode;
      expect(newChild.metadata['depth'], 1);
      expect(newChild.metadata['parentBlockId'], 'toggle-multi');
      expect(composer.selection?.extent.nodeId, newChild.id);
    });

    test('BlockTreeService.findLastDescendant finds the final node in a multi-level subtree', () {
      final rootToggle = ParagraphNode(
        id: 'root-toggle',
        text: AttributedText('Root'),
        metadata: const {
          'blockId': 'b-root',
          'blockType': NamedAttribution('toggle'),
          'isExpanded': true,
          'depth': 0,
        },
      );
      final c1 = ParagraphNode(
        id: 'c1',
        text: AttributedText('Child 1'),
        metadata: const {
          'blockId': 'b-c1',
          'parentBlockId': 'b-root',
          'depth': 1,
        },
      );
      final c1Nested = ParagraphNode(
        id: 'c1-nested',
        text: AttributedText('Grandchild 1.1'),
        metadata: const {
          'blockId': 'b-c1-nested',
          'parentBlockId': 'b-c1',
          'depth': 2,
        },
      );
      final c2 = ParagraphNode(
        id: 'c2',
        text: AttributedText('Child 2'),
        metadata: const {
          'blockId': 'b-c2',
          'parentBlockId': 'b-root',
          'depth': 1,
        },
      );
      final sibling = ParagraphNode(
        id: 'outside-sibling',
        text: AttributedText('Outside sibling'),
        metadata: const {
          'blockId': 'b-outside',
          'depth': 0,
        },
      );

      final doc = MutableDocument(nodes: [rootToggle, c1, c1Nested, c2, sibling]);

      final last = BlockTreeService.findLastDescendant(
        doc,
        rootToggle,
        getNodeDepth,
      );

      // Must be c2 (final contiguous descendant before depth drops back to 0)
      expect(last.id, 'c2');
    });

    test('BlockTreeService hierarchy queries accurately report depth, parent, children, siblings', () {
      final now = DateTime.now();
      final bRoot = Block(
        id: 'b-root',
        pageId: 'page-1',
        parentBlockId: null,
        position: 0,
        type: 'list',
        data: '{}',
        createdAt: now,
        updatedAt: now,
        version: 1,
        deleted: false,
      );
      final bChild1 = Block(
        id: 'b-child-1',
        pageId: 'page-1',
        parentBlockId: 'b-root',
        position: 0,
        type: 'text',
        data: '{}',
        createdAt: now,
        updatedAt: now,
        version: 1,
        deleted: false,
      );
      final bChild2 = Block(
        id: 'b-child-2',
        pageId: 'page-1',
        parentBlockId: 'b-root',
        position: 1,
        type: 'text',
        data: '{}',
        createdAt: now,
        updatedAt: now,
        version: 1,
        deleted: false,
      );
      final bGrandchild = Block(
        id: 'b-grandchild',
        pageId: 'page-1',
        parentBlockId: 'b-child-1',
        position: 0,
        type: 'text',
        data: '{}',
        createdAt: now,
        updatedAt: now,
        version: 1,
        deleted: false,
      );

      final blocks = [bRoot, bChild1, bChild2, bGrandchild];

      expect(BlockTreeService.effectiveDepth('b-root', blocks), 0);
      expect(BlockTreeService.effectiveDepth('b-child-1', blocks), 1);
      expect(BlockTreeService.effectiveDepth('b-grandchild', blocks), 2);

      expect(BlockTreeService.parentOf('b-root', blocks), isNull);
      expect(BlockTreeService.parentOf('b-child-1', blocks)?.id, 'b-root');
      expect(BlockTreeService.parentOf('b-grandchild', blocks)?.id, 'b-child-1');

      final rootChildren = BlockTreeService.childrenOf('b-root', blocks);
      expect(rootChildren.map((b) => b.id).toList(), ['b-child-1', 'b-child-2']);

      final childSiblings = BlockTreeService.siblingsOf('b-child-1', blocks);
      expect(childSiblings.map((b) => b.id).toList(), ['b-child-1', 'b-child-2']);

      expect(BlockTreeService.lastDescendantOf('b-root', blocks)?.id, 'b-child-2');
    });
  });
}
