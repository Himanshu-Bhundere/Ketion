import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:ketion/features/editor/presentation/widgets/depth_wrapping_component_builder.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_list_item_component.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_toggle_component.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_toggle_keyboard_actions.dart';
import 'package:ketion/features/editor/services/editor_persistence_coordinator.dart';
import 'package:ketion/features/editor/services/editor_persistence_mutations.dart';
import 'package:ketion/features/editor/services/editor_persistence_snapshot.dart';
import 'package:ketion/features/editor/services/structural_mutation_builder.dart';

class FakeSuperEditorContext implements SuperEditorContext {
  @override
  final Editor editor;
  @override
  final Document document;
  @override
  final DocumentComposer composer;

  FakeSuperEditorContext({
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

  group('Toggle Behavior & Interactions', () {
    test('KetionToggleComponentBuilder recognizes toggle nodes in expanded & collapsed states', () {
      final document = MutableDocument();
      final editor = Editor(editables: {Editor.documentKey: document});
      final builder = KetionToggleComponentBuilder(editor);

      final collapsedNode = ParagraphNode(
        id: 'toggle-collapsed',
        text: AttributedText('Collapsed toggle'),
        metadata: const {
          'blockType': NamedAttribution('toggle'),
          'isExpanded': false,
        },
      );

      final expandedNode = ParagraphNode(
        id: 'toggle-expanded',
        text: AttributedText('Expanded toggle'),
        metadata: const {
          'blockType': 'toggle',
          'isExpanded': true,
        },
      );

      final collapsedVm = builder.createViewModel(document, collapsedNode) as KetionToggleComponentViewModel?;
      final expandedVm = builder.createViewModel(document, expandedNode) as KetionToggleComponentViewModel?;

      expect(collapsedVm, isNotNull);
      expect(collapsedVm!.isExpanded, isFalse);

      expect(expandedVm, isNotNull);
      expect(expandedVm!.isExpanded, isTrue);
    });

    test('Enter at the end of a toggle heading creates child when none exists', () {
      final toggleNode = ParagraphNode(
        id: 'toggle-1',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockType': NamedAttribution('toggle'),
          'isExpanded': true,
          'depth': 0,
        },
      );

      final document = MutableDocument(nodes: [toggleNode]);
      final composer = MutableDocumentComposer(
        initialSelection: const DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: 'toggle-1',
            nodePosition: TextNodePosition(offset: 13), // end of "Toggle Header"
          ),
        ),
      );

      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );

      final editContext = FakeSuperEditorContext(
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
      );

      expect(result, ExecutionInstruction.haltExecution);
      expect(document.nodeCount, 2);

      final childNode = document.getNodeAt(1)!;
      expect(childNode.metadata['parentBlockId'], 'toggle-1');
      expect(childNode.metadata['depth'], 1);
      expect(composer.selection?.extent.nodeId, childNode.id);
      expect((composer.selection?.extent.nodePosition as TextNodePosition).offset, 0);
    });

    test('Enter at the end of a toggle heading creates child node under toggle', () {
      final toggleNode = ParagraphNode(
        id: 'toggle-1',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockType': NamedAttribution('toggle'),
          'isExpanded': true,
          'depth': 0,
        },
      );
      final existingChild = ParagraphNode(
        id: 'child-1',
        text: AttributedText('Existing child content'),
        metadata: const {
          'parentBlockId': 'toggle-1',
          'depth': 1,
        },
      );

      final document = MutableDocument(nodes: [toggleNode, existingChild]);
      final composer = MutableDocumentComposer(
        initialSelection: const DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: 'toggle-1',
            nodePosition: TextNodePosition(offset: 13),
          ),
        ),
      );

      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );

      final editContext = FakeSuperEditorContext(
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
      );

      expect(result, ExecutionInstruction.haltExecution);
      expect(document.nodeCount, 3);
      final newChild = document.getNodeAt(1)!;
      expect(newChild.metadata['depth'], 1);
      expect(newChild.metadata['parentBlockId'], 'toggle-1');
      expect(composer.selection?.extent.nodeId, newChild.id);
      expect((composer.selection?.extent.nodePosition as TextNodePosition).offset, 0);
    });

    test('Double-click / exitToggle inside nested item moves caret outside the toggle', () {
      final toggleNode = ParagraphNode(
        id: 'toggle-1',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockType': NamedAttribution('toggle'),
          'isExpanded': true,
          'depth': 0,
        },
      );
      final child1 = ParagraphNode(
        id: 'child-1',
        text: AttributedText('Child 1'),
        metadata: const {'parentBlockId': 'toggle-1', 'depth': 1},
      );
      final child2 = ParagraphNode(
        id: 'child-2',
        text: AttributedText('Child 2'),
        metadata: const {'parentBlockId': 'toggle-1', 'depth': 1},
      );
      final outsideNode = ParagraphNode(
        id: 'outside-1',
        text: AttributedText('Outside paragraph'),
        metadata: const {'depth': 0},
      );

      final document = MutableDocument(nodes: [toggleNode, child1, child2, outsideNode]);
      final composer = MutableDocumentComposer(
        initialSelection: const DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: 'child-1',
            nodePosition: TextNodePosition(offset: 2),
          ),
        ),
      );

      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );

      expect(isNodeInsideToggle(child1, document), isTrue);
      expect(isNodeInsideToggle(child2, document), isTrue);
      expect(isNodeInsideToggle(outsideNode, document), isFalse);

      exitToggle(
        editor: editor,
        document: document,
        nodeId: 'child-1',
      );

      expect(composer.selection?.extent.nodeId, 'outside-1');
      expect((composer.selection?.extent.nodePosition as TextNodePosition).offset, 0);
    });

    test('exitToggle at end of document inserts new paragraph outside toggle and places caret', () {
      final toggleNode = ParagraphNode(
        id: 'toggle-end',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockType': NamedAttribution('toggle'),
          'isExpanded': true,
          'depth': 0,
        },
      );
      final child = ParagraphNode(
        id: 'child-end',
        text: AttributedText('Last Child'),
        metadata: const {'parentBlockId': 'toggle-end', 'depth': 1},
      );

      final document = MutableDocument(nodes: [toggleNode, child]);
      final composer = MutableDocumentComposer(
        initialSelection: const DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: 'child-end',
            nodePosition: TextNodePosition(offset: 0),
          ),
        ),
      );

      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );

      exitToggle(
        editor: editor,
        document: document,
        nodeId: 'child-end',
      );

      expect(document.nodeCount, 3);
      final newOutsideNode = document.getNodeAt(2)!;
      expect(newOutsideNode.metadata['depth'], 0);
      expect(newOutsideNode.metadata['parentBlockId'], isNull);
      expect(composer.selection?.extent.nodeId, newOutsideNode.id);
    });
  });

  group('Numbered Lists Hierarchy & Ordinal Calculation', () {
    test('computeKetionListItemOrdinalValue maintains numbering across nested child blocks', () {
      // 1. Item 1
      //    1. Child 1
      //    2. Child 2
      // 2. Item 2
      final item1 = ListItemNode.ordered(
        id: 'item-1',
        text: AttributedText('Item 1'),
        indent: 0,
        metadata: const {'depth': 0},
      );
      final child1 = ListItemNode.ordered(
        id: 'child-1',
        text: AttributedText('Child 1'),
        indent: 1,
        metadata: const {'depth': 1, 'parentBlockId': 'item-1'},
      );
      final child2 = ListItemNode.ordered(
        id: 'child-2',
        text: AttributedText('Child 2'),
        indent: 1,
        metadata: const {'depth': 1, 'parentBlockId': 'item-1'},
      );
      final item2 = ListItemNode.ordered(
        id: 'item-2',
        text: AttributedText('Item 2'),
        indent: 0,
        metadata: const {'depth': 0},
      );

      final document = MutableDocument(nodes: [item1, child1, child2, item2]);

      expect(computeKetionListItemOrdinalValue(item1, document), 1);
      expect(computeKetionListItemOrdinalValue(child1, document), 1);
      expect(computeKetionListItemOrdinalValue(child2, document), 2);
      expect(computeKetionListItemOrdinalValue(item2, document), 2);
    });

    test('computeKetionListItemOrdinalValue resets when separated by non-ordered sibling', () {
      final item1 = ListItemNode.ordered(
        id: 'item-1',
        text: AttributedText('Item 1'),
        indent: 0,
        metadata: const {'depth': 0},
      );
      final para = ParagraphNode(
        id: 'para-1',
        text: AttributedText('Break paragraph'),
        metadata: const {'depth': 0},
      );
      final item2 = ListItemNode.ordered(
        id: 'item-2',
        text: AttributedText('Item 2 after paragraph'),
        indent: 0,
        metadata: const {'depth': 0},
      );

      final document = MutableDocument(nodes: [item1, para, item2]);

      expect(computeKetionListItemOrdinalValue(item1, document), 1);
      expect(computeKetionListItemOrdinalValue(item2, document), 1);
    });

    test('StructuralMutationBuilder buildIndentMutation and buildUnindentMutation update parent-child relationships', () {
      final snapshot = EditorPersistenceSnapshot('page-1', {
        'item-1': BlockSnapshot(
          blockId: 'item-1',
          pageId: 'page-1',
          type: 'list',
          parentBlockId: null,
          position: 10.0,
          version: 1,
          createdAt: DateTime.now(),
          deleted: false,
        ),
        'item-2': BlockSnapshot(
          blockId: 'item-2',
          pageId: 'page-1',
          type: 'list',
          parentBlockId: null,
          position: 20.0,
          version: 1,
          createdAt: DateTime.now(),
          deleted: false,
        ),
      });

      // Indent item-2 -> becomes child of item-1
      final indentMutation = StructuralMutationBuilder.buildIndentMutation(
        pageId: 'page-1',
        blockId: 'item-2',
        snapshot: snapshot,
      );

      expect(indentMutation, isNotNull);
      expect(indentMutation!.parentBlockId, 'item-1');

      // Now simulate snapshot with item-2 as child of item-1
      snapshot.applyMutation(indentMutation);

      // Unindent item-2 -> returns to parent's sibling level (null)
      final unindentMutation = StructuralMutationBuilder.buildUnindentMutation(
        pageId: 'page-1',
        blockId: 'item-2',
        snapshot: snapshot,
      );

      expect(unindentMutation, isNotNull);
      expect(unindentMutation!.parentBlockId, isNull);
      expect(unindentMutation.position > 10.0, isTrue);
    });
  });
}
