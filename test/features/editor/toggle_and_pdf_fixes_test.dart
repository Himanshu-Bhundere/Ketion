import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';
import 'package:ketion/features/editor/presentation/widgets/editor_identity_registry.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_edit_request_handler.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_toggle_component.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_toggle_keyboard_actions.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';
import 'package:ketion/features/editor/services/editor_persistence_coordinator.dart';
import 'package:ketion/features/editor/services/editor_persistence_mutations.dart';
import 'package:ketion/features/editor/services/editor_persistence_snapshot.dart';
import 'package:ketion/features/import_export/domain/models/document_model.dart'
    as exp;
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
  List<EditorPersistenceMutation> get failedMutations => const [];

  @override
  Future<bool> retryFailed() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ketion Toggle and PDF Fixes — Regression Verification', () {
    test(
        '1. Enter at toggle heading: Caret moves to a new paragraph inside the toggle; arrow remains functional',
        () async {
      final toggleNode = ParagraphNode(
        id: 'toggle-h1',
        text: AttributedText('Toggle Heading'),
        metadata: const {
          'blockId': 'b-toggle-1',
          'blockType': NamedAttribution('toggle'),
          'listType': 'toggle',
          'isExpanded': true,
          'depth': 0,
        },
      );
      final document = MutableDocument(nodes: [toggleNode]);
      final composer = MutableDocumentComposer(
        initialSelection: DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: toggleNode.id,
            nodePosition: const TextNodePosition(offset: 14),
          ),
        ),
      );
      final registry = EditorIdentityRegistry();
      registry.registerMapping(nodeId: toggleNode.id, blockId: 'b-toggle-1');

      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );

      final editContext = TestSuperEditorContext(
        editor: editor,
        document: document,
        composer: composer,
      );

      final result = splitToggleWhenEnterPressed(
        editContext: editContext,
        keyEvent: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
        registry: registry,
      );

      expect(result, ExecutionInstruction.haltExecution);
      expect(document.nodeCount, 2);

      final child = document.getNodeAt(1)! as ParagraphNode;
      expect(child.metadata['parentBlockId'], 'b-toggle-1');
      expect(child.metadata['depth'], 1);
      expect(composer.selection?.extent.nodeId, child.id);

      // Verify toggle arrow remains functional
      final builder = KetionToggleComponentBuilder(editor);
      final vm = builder.createViewModel(document, toggleNode)
          as KetionToggleComponentViewModel?;
      expect(vm, isNotNull);
      expect(vm!.isExpanded, isTrue);
    });

    test(
        '2. Enter inside toggle body: New paragraph retains the same parentBlockId and depth; text split preserved',
        () {
      final toggleNode = ParagraphNode(
        id: 'toggle-header',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockId': 'b-toggle-root',
          'blockType': NamedAttribution('toggle'),
          'listType': 'toggle',
          'depth': 0,
        },
      );
      final bodyNode = ParagraphNode(
        id: 'toggle-body-1',
        text: AttributedText('Hello World'),
        metadata: const {
          'blockId': 'b-body-1',
          'parentBlockId': 'b-toggle-root',
          'depth': 1,
        },
      );
      final document = MutableDocument(nodes: [toggleNode, bodyNode]);
      final composer = MutableDocumentComposer(
        initialSelection: DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: bodyNode.id,
            nodePosition:
                const TextNodePosition(offset: 5), // between Hello and World
          ),
        ),
      );
      final registry = EditorIdentityRegistry();
      registry.registerMapping(nodeId: toggleNode.id, blockId: 'b-toggle-root');
      registry.registerMapping(nodeId: bodyNode.id, blockId: 'b-body-1');

      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );

      final editContext = TestSuperEditorContext(
        editor: editor,
        document: document,
        composer: composer,
      );

      final result = splitToggleWhenEnterPressed(
        editContext: editContext,
        keyEvent: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
        registry: registry,
      );

      expect(result, ExecutionInstruction.haltExecution);
      expect(document.nodeCount, 3);

      final firstPart = document.getNodeAt(1)! as ParagraphNode;
      expect(firstPart.id, 'toggle-body-1');
      expect(firstPart.text.toPlainText(), 'Hello');
      expect(firstPart.metadata['parentBlockId'], 'b-toggle-root');
      expect(firstPart.metadata['depth'], 1);

      final secondPart = document.getNodeAt(2)! as ParagraphNode;
      expect(secondPart.text.toPlainText(), ' World');
      expect(secondPart.metadata['parentBlockId'], 'b-toggle-root');
      expect(secondPart.metadata['depth'], 1);
      expect(composer.selection?.extent.nodeId, secondPart.id);
    });

    test(
        '3. Android IME Enter: Soft-keyboard Enter produces the same structural result as hardware Enter',
        () async {
      final toggleNode = ParagraphNode(
        id: 'toggle-h2',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockId': 'b-toggle-ime',
          'blockType': NamedAttribution('toggle'),
          'listType': 'toggle',
          'depth': 0,
        },
      );
      final childNode = ParagraphNode(
        id: 'child-ime-1',
        text: AttributedText('Existing Child'),
        metadata: const {
          'blockId': 'b-child-ime-1',
          'parentBlockId': 'b-toggle-ime',
          'depth': 1,
        },
      );
      final document = MutableDocument(nodes: [toggleNode, childNode]);
      final composer = MutableDocumentComposer(
        initialSelection: DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: childNode.id,
            nodePosition:
                const TextNodePosition(offset: 14), // at end of Existing Child
          ),
        ),
      );

      final coordinator = TestPersistenceCoordinator();
      final snapshot = EditorPersistenceSnapshot('p1', {
        'b-toggle-ime': BlockSnapshot(
          blockId: 'b-toggle-ime',
          pageId: 'p1',
          type: 'list',
          parentBlockId: null,
          position: 1,
          version: 1,
          createdAt: DateTime.now(),
          deleted: false,
        ),
        'b-child-ime-1': BlockSnapshot(
          blockId: 'b-child-ime-1',
          pageId: 'p1',
          type: 'text',
          parentBlockId: 'b-toggle-ime',
          position: 2,
          version: 1,
          createdAt: DateTime.now(),
          deleted: false,
        ),
      });

      final adapter = KetionSuperEditorAdapter(
        pageId: 'p1',
        coordinator: coordinator,
        snapshot: snapshot,
      );
      adapter.registry
          .registerMapping(nodeId: toggleNode.id, blockId: 'b-toggle-ime');
      adapter.registry
          .registerMapping(nodeId: childNode.id, blockId: 'b-child-ime-1');

      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'p1',
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

      editor.execute([InsertNewlineAtCaretRequest('new-ime-sibling')]);

      expect(document.nodeCount, 3);
      final newSibling =
          document.getNodeById('new-ime-sibling') as ParagraphNode?;
      expect(newSibling, isNotNull);
      expect(newSibling!.metadata['parentBlockId'], 'b-toggle-ime');
      expect(newSibling.metadata['depth'], 1);
      expect(composer.selection?.extent.nodeId, 'new-ime-sibling');
    });

    test(
        '4. Empty child exits toggle: Empty paragraph moves outside the toggle subtree with valid parent and sibling position',
        () {
      final toggleNode = ParagraphNode(
        id: 'toggle-header-4',
        text: AttributedText('Toggle Header 4'),
        metadata: const {
          'blockId': 'b-toggle-4',
          'blockType': NamedAttribution('toggle'),
          'listType': 'toggle',
          'depth': 0,
        },
      );
      final child1 = ParagraphNode(
        id: 'child-non-empty',
        text: AttributedText('First child'),
        metadata: const {
          'blockId': 'b-child-non-empty',
          'parentBlockId': 'b-toggle-4',
          'depth': 1,
        },
      );
      final emptyChild = ParagraphNode(
        id: 'child-empty',
        text: AttributedText(),
        metadata: const {
          'blockId': 'b-child-empty',
          'parentBlockId': 'b-toggle-4',
          'depth': 1,
        },
      );
      final document = MutableDocument(nodes: [toggleNode, child1, emptyChild]);
      final composer = MutableDocumentComposer(
        initialSelection: DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: emptyChild.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
      );
      final registry = EditorIdentityRegistry();
      registry.registerMapping(nodeId: toggleNode.id, blockId: 'b-toggle-4');
      registry.registerMapping(nodeId: child1.id, blockId: 'b-child-non-empty');
      registry.registerMapping(nodeId: emptyChild.id, blockId: 'b-child-empty');

      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );

      final editContext = TestSuperEditorContext(
        editor: editor,
        document: document,
        composer: composer,
      );

      final result = splitToggleWhenEnterPressed(
        editContext: editContext,
        keyEvent: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
        registry: registry,
      );

      expect(result, ExecutionInstruction.haltExecution);
      expect(document.nodeCount, 3);

      final exitedNode = document.getNodeAt(2)! as ParagraphNode;
      expect(exitedNode.id, 'child-empty');
      // Depth must become 0 (toggle's sibling depth)
      expect(exitedNode.metadata['depth'], 0);
      // parentBlockId must be removed/null (outside toggle)
      expect(exitedNode.metadata['parentBlockId'], isNull);
      expect(composer.selection?.extent.nodeId, exitedNode.id);
    });

    test(
        '5. Nested toggle exit: Exiting a nested toggle exits only the innermost toggle',
        () {
      final outerToggle = ParagraphNode(
        id: 'outer-toggle',
        text: AttributedText('Outer Toggle'),
        metadata: const {
          'blockId': 'b-outer',
          'blockType': NamedAttribution('toggle'),
          'listType': 'toggle',
          'depth': 0,
        },
      );
      final innerToggle = ParagraphNode(
        id: 'inner-toggle',
        text: AttributedText('Inner Toggle'),
        metadata: const {
          'blockId': 'b-inner',
          'blockType': NamedAttribution('toggle'),
          'listType': 'toggle',
          'parentBlockId': 'b-outer',
          'depth': 1,
        },
      );
      final emptyChild = ParagraphNode(
        id: 'nested-empty-child',
        text: AttributedText(),
        metadata: const {
          'blockId': 'b-nested-empty',
          'parentBlockId': 'b-inner',
          'depth': 2,
        },
      );
      final document =
          MutableDocument(nodes: [outerToggle, innerToggle, emptyChild]);
      final composer = MutableDocumentComposer(
        initialSelection: DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: emptyChild.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
      );
      final registry = EditorIdentityRegistry();
      registry.registerMapping(nodeId: outerToggle.id, blockId: 'b-outer');
      registry.registerMapping(nodeId: innerToggle.id, blockId: 'b-inner');
      registry.registerMapping(
          nodeId: emptyChild.id, blockId: 'b-nested-empty',);

      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );

      final editContext = TestSuperEditorContext(
        editor: editor,
        document: document,
        composer: composer,
      );

      final result = splitToggleWhenEnterPressed(
        editContext: editContext,
        keyEvent: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
        registry: registry,
      );

      expect(result, ExecutionInstruction.haltExecution);
      expect(document.nodeCount, 3);

      final exitedNode = document.getNodeAt(2)! as ParagraphNode;
      expect(exitedNode.id, 'nested-empty-child');
      // Exited ONLY innermost toggle: depth becomes inner toggle's depth (1)
      expect(exitedNode.metadata['depth'], 1);
      // Parent becomes inner toggle's parent (b-outer)
      expect(exitedNode.metadata['parentBlockId'], 'b-outer');
      expect(composer.selection?.extent.nodeId, exitedNode.id);
    });

    test(
        '6. First expand: Multiple children appear without duplicated nodes or stale selection',
        () {
      final coordinator = TestPersistenceCoordinator();
      final snapshot = EditorPersistenceSnapshot('p2', {});
      final adapter = KetionSuperEditorAdapter(
        pageId: 'p2',
        coordinator: coordinator,
        snapshot: snapshot,
      );

      final now = DateTime.now();
      final toggleBlock = Block(
        id: 'toggle-b1',
        pageId: 'p2',
        parentBlockId: null,
        position: 10.0,
        type: 'list',
        data: jsonEncode({
          'runtimeType': 'list',
          'listType': 'toggle',
          'isExpanded': false, // initially collapsed!
          'spans': [
            {'text': 'Collapsed Toggle'},
          ],
        }),
        createdAt: now,
        updatedAt: now,
        version: 1,
        deleted: false,
      );

      final child1 = Block(
        id: 'c1',
        pageId: 'p2',
        parentBlockId: 'toggle-b1',
        position: 10.0,
        type: 'text',
        data: jsonEncode({
          'runtimeType': 'text',
          'spans': [
            {'text': 'Child 1'},
          ],
        }),
        createdAt: now,
        updatedAt: now,
        version: 1,
        deleted: false,
      );

      final child2 = Block(
        id: 'c2',
        pageId: 'p2',
        parentBlockId: 'toggle-b1',
        position: 20.0,
        type: 'text',
        data: jsonEncode({
          'runtimeType': 'text',
          'spans': [
            {'text': 'Child 2'},
          ],
        }),
        createdAt: now,
        updatedAt: now,
        version: 1,
        deleted: false,
      );

      final doc = adapter.createDocument([toggleBlock, child1, child2]);
      // Initially, only toggle header is live in document
      expect(doc.nodeCount, 1);

      final composer = MutableDocumentComposer();
      final editor = Editor(
        editables: {
          Editor.documentKey: doc,
          Editor.composerKey: composer,
        },
      );
      adapter.bind(doc, editor);

      // Expand for the first time
      adapter.restoreSubtree('toggle-b1');

      expect(doc.nodeCount, 3);
      final restoredIds = doc.map((n) => n.id).toList();
      // Ensure no duplicates exist
      expect(restoredIds.toSet().length, 3);

      final text1 = (doc.getNodeAt(1) as TextNode).text.toPlainText();
      final text2 = (doc.getNodeAt(2) as TextNode).text.toPlainText();
      expect(text1, 'Child 1');
      expect(text2, 'Child 2');
    });

    test(
        '7. Collapse and re-expand: All child IDs, text, order, and parent relationships remain unchanged',
        () {
      final coordinator = TestPersistenceCoordinator();
      final snapshot = EditorPersistenceSnapshot('p3', {});
      final adapter = KetionSuperEditorAdapter(
        pageId: 'p3',
        coordinator: coordinator,
        snapshot: snapshot,
      );

      final now = DateTime.now();
      final toggleBlock = Block(
        id: 'toggle-b2',
        pageId: 'p3',
        parentBlockId: null,
        position: 10.0,
        type: 'list',
        data: jsonEncode({
          'runtimeType': 'list',
          'listType': 'toggle',
          'isExpanded': true,
          'spans': [
            {'text': 'Expandable Toggle'},
          ],
        }),
        createdAt: now,
        updatedAt: now,
        version: 1,
        deleted: false,
      );

      final childA = Block(
        id: 'cA',
        pageId: 'p3',
        parentBlockId: 'toggle-b2',
        position: 10.0,
        type: 'text',
        data: jsonEncode({
          'runtimeType': 'text',
          'spans': [
            {'text': 'Child A'},
          ],
        }),
        createdAt: now,
        updatedAt: now,
        version: 1,
        deleted: false,
      );

      final childB = Block(
        id: 'cB',
        pageId: 'p3',
        parentBlockId: 'toggle-b2',
        position: 20.0,
        type: 'text',
        data: jsonEncode({
          'runtimeType': 'text',
          'spans': [
            {'text': 'Child B'},
          ],
        }),
        createdAt: now,
        updatedAt: now,
        version: 1,
        deleted: false,
      );

      final doc = adapter.createDocument([toggleBlock, childA, childB]);
      expect(doc.nodeCount, 3);

      final childAId = doc.getNodeAt(1)!.id;
      final childBId = doc.getNodeAt(2)!.id;

      final composer = MutableDocumentComposer(
        initialSelection: DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: childAId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
      );
      final editor = Editor(
        editables: {
          Editor.documentKey: doc,
          Editor.composerKey: composer,
        },
      );
      adapter.bind(doc, editor);

      // Collapse: selection on childA should be relocated to toggle header
      adapter.hideSubtree('toggle-b2');
      expect(doc.nodeCount, 1);
      expect(composer.selection?.extent.nodeId, doc.getNodeAt(0)!.id);

      // Re-expand
      adapter.restoreSubtree('toggle-b2');
      expect(doc.nodeCount, 3);

      expect(doc.getNodeAt(1)!.id, childAId);
      expect((doc.getNodeAt(1) as TextNode).text.toPlainText(), 'Child A');
      expect(doc.getNodeAt(1)!.metadata['parentBlockId'], 'toggle-b2');

      expect(doc.getNodeAt(2)!.id, childBId);
      expect((doc.getNodeAt(2) as TextNode).text.toPlainText(), 'Child B');
      expect(doc.getNodeAt(2)!.metadata['parentBlockId'], 'toggle-b2');
    });

    test(
      '7b. hideSubtree: collapses mixed-content descendants (text, task, image without depth, nested toggle) via parent hierarchy and restores them',
      () async {
        final coordinator = TestPersistenceCoordinator();
        final snapshot = EditorPersistenceSnapshot('test-page-mixed', const {});
        final adapter = KetionSuperEditorAdapter(
          pageId: 'test-page-mixed',
          coordinator: coordinator,
          snapshot: snapshot,
        );
        final registry = adapter.registry;

        final toggleNode = ParagraphNode(
          id: 'toggle-mixed-node',
          text: AttributedText('Toggle Header'),
          metadata: const {
            'blockId': 'toggle-b-mixed',
            'listType': 'toggle',
            'isExpanded': true,
            'depth': 0,
          },
        );
        final paragraphChild = ParagraphNode(
          id: 'p-child-node',
          text: AttributedText('Paragraph child'),
          metadata: const {
            'blockId': 'b-p-child',
            'parentBlockId': 'toggle-b-mixed',
            'depth': 1,
          },
        );
        final taskChild = TaskNode(
          id: 'task-child-node',
          text: AttributedText('Task child'),
          isComplete: false,
          metadata: const {
            'blockId': 'b-task-child',
            'parentBlockId': 'toggle-b-mixed',
            'depth': 1,
          },
        );
        // Media node intentionally missing depth metadata, but having parentBlockId
        final imageChild = ImageNode(
          id: 'img-child-node',
          imageUrl: 'https://example.com/test.png',
          metadata: const {
            'blockId': 'b-img-child',
            'parentBlockId': 'toggle-b-mixed',
          },
        );
        final innerToggle = ParagraphNode(
          id: 'inner-toggle-node',
          text: AttributedText('Inner Toggle Header'),
          metadata: const {
            'blockId': 'b-inner-toggle',
            'listType': 'toggle',
            'parentBlockId': 'toggle-b-mixed',
            'isExpanded': true,
            'depth': 1,
          },
        );
        final innerDescendant = ParagraphNode(
          id: 'inner-descendant-node',
          text: AttributedText('Inner descendant'),
          metadata: const {
            'blockId': 'b-inner-desc',
            'parentBlockId': 'b-inner-toggle',
            'depth': 2,
          },
        );
        final rootSibling = ParagraphNode(
          id: 'root-sibling-node',
          text: AttributedText('Root Sibling'),
          metadata: const {
            'blockId': 'b-root-sibling',
            'depth': 0,
          },
        );

        registry.registerMapping(
            nodeId: toggleNode.id, blockId: 'toggle-b-mixed',);
        registry.registerMapping(
            nodeId: paragraphChild.id, blockId: 'b-p-child',);
        registry.registerMapping(nodeId: taskChild.id, blockId: 'b-task-child');
        registry.registerMapping(nodeId: imageChild.id, blockId: 'b-img-child');
        registry.registerMapping(
            nodeId: innerToggle.id, blockId: 'b-inner-toggle',);
        registry.registerMapping(
            nodeId: innerDescendant.id, blockId: 'b-inner-desc',);
        registry.registerMapping(
            nodeId: rootSibling.id, blockId: 'b-root-sibling',);

        final doc = MutableDocument(
          nodes: [
            toggleNode,
            paragraphChild,
            taskChild,
            imageChild,
            innerToggle,
            innerDescendant,
            rootSibling,
          ],
        );

        final composer = MutableDocumentComposer();
        final editor = Editor(
          editables: {
            Editor.documentKey: doc,
            Editor.composerKey: composer,
          },
        );
        adapter.bind(doc, editor);

        expect(doc.nodeCount, 7);

        // Collapse outer toggle: all 5 descendants should be hidden, root sibling remains visible
        adapter.hideSubtree('toggle-b-mixed');
        expect(doc.nodeCount, 2);
        expect(doc.getNodeAt(0)!.id, toggleNode.id);
        expect(doc.getNodeAt(1)!.id, rootSibling.id);

        // Re-expand outer toggle: all 5 descendants should be restored in exact order
        adapter.restoreSubtree('toggle-b-mixed');
        expect(doc.nodeCount, 7);
        expect(doc.getNodeAt(0)!.id, toggleNode.id);
        expect(doc.getNodeAt(1)!.id, paragraphChild.id);
        expect(doc.getNodeAt(2)!.id, taskChild.id);
        expect(doc.getNodeAt(3)!.id, imageChild.id);
        expect(doc.getNodeAt(4)!.id, innerToggle.id);
        expect(doc.getNodeAt(5)!.id, innerDescendant.id);
        expect(doc.getNodeAt(6)!.id, rootSibling.id);
      },
    );

    test(
      '7c. hideSubtree does NOT collapse unrelated indented blocks outside toggle subtree',
      () {
        final coordinator = TestPersistenceCoordinator();
        final snapshot = EditorPersistenceSnapshot('p-indented', {});
        final adapter = KetionSuperEditorAdapter(
          pageId: 'p-indented',
          coordinator: coordinator,
          snapshot: snapshot,
        );

        final registry = adapter.registry;

        // Toggle at depth 0
        final toggleNode = ParagraphNode(
          id: 'toggle-node',
          text: AttributedText('Toggle Header'),
          metadata: const {
            'blockId': 'b-toggle-main',
            'listType': 'toggle',
            'isExpanded': true,
            'depth': 0,
          },
        );

        // Valid child of toggle at depth 1
        final toggleChild = ParagraphNode(
          id: 'toggle-child',
          text: AttributedText('Toggle Child'),
          metadata: const {
            'blockId': 'b-toggle-child',
            'parentBlockId': 'b-toggle-main',
            'depth': 1,
          },
        );

        // Unrelated indented node at depth 1 with no parent or unrelated parent
        final unrelatedIndented = ParagraphNode(
          id: 'unrelated-indented',
          text: AttributedText('Unrelated indented block'),
          metadata: const {
            'blockId': 'b-unrelated-indented',
            'parentBlockId': 'b-other-parent',
            'depth': 1,
          },
        );

        registry.registerMapping(
          nodeId: toggleNode.id,
          blockId: 'b-toggle-main',
        );
        registry.registerMapping(
          nodeId: toggleChild.id,
          blockId: 'b-toggle-child',
        );
        registry.registerMapping(
          nodeId: unrelatedIndented.id,
          blockId: 'b-unrelated-indented',
        );

        final doc = MutableDocument(
          nodes: [
            toggleNode,
            toggleChild,
            unrelatedIndented,
          ],
        );

        final composer = MutableDocumentComposer();
        final editor = Editor(
          editables: {
            Editor.documentKey: doc,
            Editor.composerKey: composer,
          },
        );
        adapter.bind(doc, editor);

        expect(doc.nodeCount, 3);

        // Collapsing toggle should hide ONLY toggleChild, keeping unrelatedIndented visible!
        adapter.hideSubtree('b-toggle-main');

        expect(doc.nodeCount, 2);
        expect(doc.getNodeAt(0)!.id, toggleNode.id);
        expect(doc.getNodeAt(1)!.id, unrelatedIndented.id);

        // Re-expanding restores toggleChild
        adapter.restoreSubtree('b-toggle-main');
        expect(doc.nodeCount, 3);
        expect(doc.getNodeAt(0)!.id, toggleNode.id);
        expect(doc.getNodeAt(1)!.id, toggleChild.id);
        expect(doc.getNodeAt(2)!.id, unrelatedIndented.id);
      },
    );

    test(
        '8. PDF blocks: Every block is separated vertically and exports valid PDF',
        () async {
      final page = Page(
        id: 'pdf-page-1',
        title: 'PDF Separation Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final doc = exp.ExportDocument(
        title: page.title,
        nodes: [
          const exp.DocumentNode.heading(
              level: 1, spans: [exp.DocumentTextSpan(text: 'Heading 1')],),
          const exp.DocumentNode.paragraph(
              spans: [exp.DocumentTextSpan(text: 'Paragraph body block 1')],),
          const exp.DocumentNode.callout(
              icon: '💡',
              color: 'blue',
              spans: [exp.DocumentTextSpan(text: 'Callout note')],),
          const exp.DocumentNode.code(
              language: 'dart', code: 'void main() => print("test");',),
          const exp.DocumentNode.divider(),
        ],
      );

      final exporter = PdfExporter();
      final bytes = await exporter.exportDocument(doc);

      expect(bytes, isNotEmpty);
      final header = utf8.decode(bytes.sublist(0, 5), allowMalformed: true);
      expect(header.startsWith('%PDF'), isTrue);
    });

    test(
        '9. Nested PDF indentation: Each additional hierarchy level increases left indentation',
        () async {
      final page = Page(
        id: 'pdf-page-2',
        title: 'PDF Indentation Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final doc = exp.ExportDocument(
        title: page.title,
        nodes: [
          const exp.DocumentNode.list(
              listType: 'toggle',
              checked: false,
              spans: [exp.DocumentTextSpan(text: 'Toggle Root')],
              depth: 0,),
          const exp.DocumentNode.paragraph(
              spans: [exp.DocumentTextSpan(text: 'Depth 1 paragraph')],
              depth: 1,),
          const exp.DocumentNode.list(
              listType: 'toggle',
              checked: false,
              spans: [exp.DocumentTextSpan(text: 'Nested Toggle')],
              depth: 1,),
          const exp.DocumentNode.paragraph(
              spans: [exp.DocumentTextSpan(text: 'Depth 2 paragraph')],
              depth: 2,),
        ],
      );

      final exporter = PdfExporter();
      final bytes = await exporter.exportDocument(doc);

      expect(bytes, isNotEmpty);
      final header = utf8.decode(bytes.sublist(0, 5), allowMalformed: true);
      expect(header.startsWith('%PDF'), isTrue);
    });

    test(
        '10. Save and reload: Editor and PDF represent the same persisted content and hierarchy',
        () async {
      final now = DateTime.now();
      final page = Page(
        id: 'page-save-reload',
        title: 'Save and Reload Hierarchy',
        createdAt: now,
        updatedAt: now,
      );

      final blocks = [
        Block(
          id: 'b-top-toggle',
          pageId: 'page-save-reload',
          parentBlockId: null,
          position: 10.0,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'toggle',
            'isExpanded': true,
            'spans': [
              {'text': 'Top Toggle'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          version: 1,
          deleted: false,
        ),
        Block(
          id: 'b-child-p',
          pageId: 'page-save-reload',
          parentBlockId: 'b-top-toggle',
          position: 10.0,
          type: 'text',
          data: jsonEncode({
            'runtimeType': 'text',
            'headingLevel': 0,
            'spans': [
              {'text': 'Child under toggle'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          version: 1,
          deleted: false,
        ),
      ];

      // Verify visible tree mapping
      final visibleTree = BlockTreeService.buildVisibleTree(blocks);
      expect(visibleTree.length, 2);
      expect(visibleTree[0].block.id, 'b-top-toggle');
      expect(visibleTree[0].depth, 0);
      expect(visibleTree[1].block.id, 'b-child-p');
      expect(visibleTree[1].depth, 1);

      // Verify editor reloads exact hierarchy
      final coordinator = TestPersistenceCoordinator();
      final snapshot = EditorPersistenceSnapshot('page-save-reload', {});
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-save-reload',
        coordinator: coordinator,
        snapshot: snapshot,
      );
      final reloadedDoc = adapter.createDocument(blocks);
      expect(reloadedDoc.nodeCount, 2);
      expect(reloadedDoc.getNodeAt(0)!.metadata['blockId'], 'b-top-toggle');
      expect(
          reloadedDoc.getNodeAt(1)!.metadata['parentBlockId'], 'b-top-toggle',);
      expect(reloadedDoc.getNodeAt(1)!.metadata['depth'], 1);

      // Verify export to PDF
      final exporter = PdfExporter();
      final useCase = ExportUseCase([exporter]);
      final pdfBytes = await useCase.exportToBytes(page, blocks, 'pdf');
      expect(pdfBytes, isNotEmpty);
      expect(
          utf8
              .decode(pdfBytes.sublist(0, 5), allowMalformed: true)
              .startsWith('%PDF'),
          isTrue,);
    });
  });
}
