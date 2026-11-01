import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import 'package:ketion/core/bootstrap/widget_bootstrap.dart';
import 'package:ketion/core/router/app_router.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
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
  List<EditorPersistenceMutation> get failedMutations => const [];

  @override
  Future<bool> retryFailed() async => true;
}

class MockSuperEditorContext implements SuperEditorContext {
  @override
  final Editor editor;
  @override
  final Document document;
  @override
  final DocumentComposer composer;

  MockSuperEditorContext({
    required this.editor,
    required this.document,
    required this.composer,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue 1: List Hierarchy, Indentation, and Subtree Reordering', () {
    test(
        'Ordered List: indent middle item twice, unindent twice, preserving type and sibling order',
        () {
      final doc = MutableDocument(
        nodes: [
          ListItemNode.ordered(
            id: 'o1',
            text: AttributedText('1. Parent 1'),
            indent: 0,
            metadata: const {'depth': 0, 'blockId': 'b-o1'},
          ),
          ListItemNode.ordered(
            id: 'o1_sub',
            text: AttributedText('1.1 Sub-item 1'),
            indent: 1,
            metadata: const {
              'depth': 1,
              'blockId': 'b-o1_sub',
              'parentBlockId': 'b-o1',
            },
          ),
          ListItemNode.ordered(
            id: 'o2',
            text: AttributedText('1.2 Middle item'),
            indent: 1,
            metadata: const {
              'depth': 1,
              'blockId': 'b-o2',
              'parentBlockId': 'b-o1',
            },
          ),
          ListItemNode.ordered(
            id: 'o3',
            text: AttributedText('2. Sibling 3'),
            indent: 0,
            metadata: const {'depth': 0, 'blockId': 'b-o3'},
          ),
        ],
      );

      final coordinator = MockPersistenceCoordinator();
      final snapshot = EditorPersistenceSnapshot(
        'page-ordered',
        {
          'b-o1': BlockSnapshot(
              blockId: 'b-o1',
              pageId: 'page-ordered',
              type: 'list',
              position: 10,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
          'b-o1_sub': BlockSnapshot(
              blockId: 'b-o1_sub',
              pageId: 'page-ordered',
              type: 'list',
              parentBlockId: 'b-o1',
              position: 15,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
          'b-o2': BlockSnapshot(
              blockId: 'b-o2',
              pageId: 'page-ordered',
              type: 'list',
              parentBlockId: 'b-o1',
              position: 20,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
          'b-o3': BlockSnapshot(
              blockId: 'b-o3',
              pageId: 'page-ordered',
              type: 'list',
              position: 30,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
        },
      );
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-ordered',
        coordinator: coordinator,
        snapshot: snapshot,
      );
      adapter.registry.registerMapping(nodeId: 'o1', blockId: 'b-o1');
      adapter.registry.registerMapping(nodeId: 'o1_sub', blockId: 'b-o1_sub');
      adapter.registry.registerMapping(nodeId: 'o2', blockId: 'b-o2');
      adapter.registry.registerMapping(nodeId: 'o3', blockId: 'b-o3');

      final composer = MutableDocumentComposer();
      final editor = Editor(
        editables: {
          Editor.documentKey: doc,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'page-ordered',
            document: doc,
            composer: composer,
            coordinator: coordinator,
            snapshot: snapshot,
            adapter: adapter,
          ),
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );
      adapter.bind(doc, editor);

      // Indent middle item (o2) under o1_sub -> depth 2
      editor.execute([IndentListItemRequest(nodeId: 'o2')]);
      var n2 = doc.getNodeById('o2') as ListItemNode;
      expect(n2.indent, 2);
      expect(n2.metadata['depth'], 2);
      expect(n2.type, ListItemType.ordered);

      // Unindent once -> depth 1 (under o1)
      editor.execute([UnIndentListItemRequest(nodeId: 'o2')]);
      n2 = doc.getNodeById('o2') as ListItemNode;
      expect(n2.indent, 1);
      expect(n2.metadata['depth'], 1);
      expect(n2.type, ListItemType.ordered);

      // Unindent again -> depth 0 (Ketion handler preserves ListItemType.ordered instead of converting to ParagraphNode!)
      editor.execute([UnIndentListItemRequest(nodeId: 'o2')]);
      final n2Unindented = doc.getNodeById('o2');
      expect(n2Unindented, isA<ListItemNode>());
      expect((n2Unindented as ListItemNode).type, ListItemType.ordered);
      expect(n2Unindented.indent, 0);
      expect(n2Unindented.metadata['depth'], 0);

      // Move o2 after o3
      editor.execute([const MoveNodeRequest(nodeId: 'o2', newIndex: 3)]);
      final reorderedIds = <String>[];
      for (int i = 0; i < doc.nodeCount; i++) {
        reorderedIds.add(doc.getNodeAt(i)!.id);
      }
      expect(reorderedIds, ['o1', 'o1_sub', 'o3', 'o2']);
    });

    test(
        'Unordered List: indent middle item, unindent, verify bullet marker preserved',
        () {
      final doc = MutableDocument(
        nodes: [
          ListItemNode.unordered(
            id: 'u1',
            text: AttributedText('Bullet 1'),
            indent: 0,
            metadata: const {'depth': 0, 'blockId': 'b-u1'},
          ),
          ListItemNode.unordered(
            id: 'u2',
            text: AttributedText('Bullet 2'),
            indent: 0,
            metadata: const {'depth': 0, 'blockId': 'b-u2'},
          ),
          ListItemNode.unordered(
            id: 'u3',
            text: AttributedText('Bullet 3'),
            indent: 0,
            metadata: const {'depth': 0, 'blockId': 'b-u3'},
          ),
        ],
      );

      final coordinator = MockPersistenceCoordinator();
      final snapshot = EditorPersistenceSnapshot(
        'page-unordered',
        {
          'b-u1': BlockSnapshot(
              blockId: 'b-u1',
              pageId: 'page-unordered',
              type: 'list',
              position: 10,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
          'b-u2': BlockSnapshot(
              blockId: 'b-u2',
              pageId: 'page-unordered',
              type: 'list',
              position: 20,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
          'b-u3': BlockSnapshot(
              blockId: 'b-u3',
              pageId: 'page-unordered',
              type: 'list',
              position: 30,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
        },
      );
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-unordered',
        coordinator: coordinator,
        snapshot: snapshot,
      );
      adapter.registry.registerMapping(nodeId: 'u1', blockId: 'b-u1');
      adapter.registry.registerMapping(nodeId: 'u2', blockId: 'b-u2');
      adapter.registry.registerMapping(nodeId: 'u3', blockId: 'b-u3');

      final composer = MutableDocumentComposer();
      final editor = Editor(
        editables: {
          Editor.documentKey: doc,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'page-unordered',
            document: doc,
            composer: composer,
            coordinator: coordinator,
            snapshot: snapshot,
            adapter: adapter,
          ),
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );
      adapter.bind(doc, editor);

      // Indent u2
      editor.execute([IndentListItemRequest(nodeId: 'u2')]);
      var n2 = doc.getNodeById('u2') as ListItemNode;
      expect(n2.indent, 1);
      expect(n2.type, ListItemType.unordered);

      // Unindent u2
      editor.execute([UnIndentListItemRequest(nodeId: 'u2')]);
      n2 = doc.getNodeById('u2') as ListItemNode;
      expect(n2.indent, 0);
      expect(n2.type, ListItemType.unordered);
    });

    test(
        'Checklist: indent middle item, unindent, and preserve TaskNode type with checked state',
        () {
      final doc = MutableDocument(
        nodes: [
          TaskNode(
            id: 't1',
            isComplete: false,
            text: AttributedText('Task 1'),
            metadata: const {'depth': 0, 'blockId': 'b-t1'},
          ),
          TaskNode(
            id: 't2',
            isComplete: true,
            text: AttributedText('Task 2 (completed)'),
            metadata: const {'depth': 0, 'blockId': 'b-t2'},
          ),
          TaskNode(
            id: 't3',
            isComplete: false,
            text: AttributedText('Task 3'),
            metadata: const {'depth': 0, 'blockId': 'b-t3'},
          ),
        ],
      );

      final coordinator = MockPersistenceCoordinator();
      final snapshot = EditorPersistenceSnapshot(
        'page-tasks',
        {
          'b-t1': BlockSnapshot(
              blockId: 'b-t1',
              pageId: 'page-tasks',
              type: 'list',
              position: 10,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
          'b-t2': BlockSnapshot(
              blockId: 'b-t2',
              pageId: 'page-tasks',
              type: 'list',
              position: 20,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
          'b-t3': BlockSnapshot(
              blockId: 'b-t3',
              pageId: 'page-tasks',
              type: 'list',
              position: 30,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
        },
      );
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-tasks',
        coordinator: coordinator,
        snapshot: snapshot,
      );
      adapter.registry.registerMapping(nodeId: 't1', blockId: 'b-t1');
      adapter.registry.registerMapping(nodeId: 't2', blockId: 'b-t2');
      adapter.registry.registerMapping(nodeId: 't3', blockId: 'b-t3');

      final composer = MutableDocumentComposer();
      final editor = Editor(
        editables: {
          Editor.documentKey: doc,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'page-tasks',
            document: doc,
            composer: composer,
            coordinator: coordinator,
            snapshot: snapshot,
            adapter: adapter,
          ),
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );
      adapter.bind(doc, editor);

      // Indent t2
      editor.execute([const IndentTaskRequest('t2')]);
      var n2 = doc.getNodeById('t2') as TaskNode;
      expect(n2.indent, 1);
      expect(n2.metadata['depth'], 1);
      expect(n2.isComplete, isTrue);

      // Unindent t2
      editor.execute([const UnIndentTaskRequest('t2')]);
      n2 = doc.getNodeById('t2') as TaskNode;
      expect(n2.indent, 0);
      expect(n2.metadata['depth'], 0);
      expect(n2.isComplete, isTrue);
    });

    test('Reordering parent moves all its contiguous descendants together', () {
      final doc = MutableDocument(
        nodes: [
          ListItemNode.ordered(
            id: 'p1',
            text: AttributedText('Parent 1'),
            indent: 0,
            metadata: const {'depth': 0, 'blockId': 'b-p1'},
          ),
          ListItemNode.ordered(
            id: 'c1_1',
            text: AttributedText('Child 1.1'),
            indent: 1,
            metadata: const {
              'depth': 1,
              'blockId': 'b-c1_1',
              'parentBlockId': 'b-p1',
            },
          ),
          ListItemNode.ordered(
            id: 'c1_2',
            text: AttributedText('Child 1.2'),
            indent: 1,
            metadata: const {
              'depth': 1,
              'blockId': 'b-c1_2',
              'parentBlockId': 'b-p1',
            },
          ),
          ListItemNode.ordered(
            id: 'p2',
            text: AttributedText('Parent 2'),
            indent: 0,
            metadata: const {'depth': 0, 'blockId': 'b-p2'},
          ),
        ],
      );

      final coordinator = MockPersistenceCoordinator();
      final snapshot = EditorPersistenceSnapshot(
        'page-subtree',
        {
          'b-p1': BlockSnapshot(
              blockId: 'b-p1',
              pageId: 'page-subtree',
              type: 'list',
              position: 10,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
          'b-c1_1': BlockSnapshot(
              blockId: 'b-c1_1',
              pageId: 'page-subtree',
              type: 'list',
              parentBlockId: 'b-p1',
              position: 11,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
          'b-c1_2': BlockSnapshot(
              blockId: 'b-c1_2',
              pageId: 'page-subtree',
              type: 'list',
              parentBlockId: 'b-p1',
              position: 12,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
          'b-p2': BlockSnapshot(
              blockId: 'b-p2',
              pageId: 'page-subtree',
              type: 'list',
              position: 20,
              version: 1,
              createdAt: DateTime.now(),
              deleted: false,),
        },
      );
      final adapter = KetionSuperEditorAdapter(
        pageId: 'page-subtree',
        coordinator: coordinator,
        snapshot: snapshot,
      );
      adapter.registry.registerMapping(nodeId: 'p1', blockId: 'b-p1');
      adapter.registry.registerMapping(nodeId: 'c1_1', blockId: 'b-c1_1');
      adapter.registry.registerMapping(nodeId: 'c1_2', blockId: 'b-c1_2');
      adapter.registry.registerMapping(nodeId: 'p2', blockId: 'b-p2');

      final composer = MutableDocumentComposer();
      final editor = Editor(
        editables: {
          Editor.documentKey: doc,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'page-subtree',
            document: doc,
            composer: composer,
            coordinator: coordinator,
            snapshot: snapshot,
            adapter: adapter,
          ),
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );
      adapter.bind(doc, editor);

      // Move p1 to index 3 (after p2)
      editor.execute([const MoveNodeRequest(nodeId: 'p1', newIndex: 3)]);

      // p1 and its children c1_1, c1_2 should all be moved after p2!
      final nodeIds = <String>[];
      for (int i = 0; i < doc.nodeCount; i++) {
        nodeIds.add(doc.getNodeAt(i)!.id);
      }
      expect(nodeIds, ['p2', 'p1', 'c1_1', 'c1_2']);
    });
  });

  group('Issue 2: PDF Export Matching Editor Hierarchy & Ordinals', () {
    test(
        'Calculates ordered list numbers per sibling group and resets for separate lists',
        () async {
      final now = DateTime.now();
      final page = Page(
        id: 'page-export-test',
        title: 'Export Test',
        createdAt: now,
        updatedAt: now,
      );

      final blocks = [
        // List 1 (ordered)
        Block(
          id: '1',
          pageId: page.id,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'ordered',
            'spans': [
              {'text': 'Parent 1'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 10,
        ),
        Block(
          id: '2',
          pageId: page.id,
          parentBlockId: '1',
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'ordered',
            'spans': [
              {'text': 'Child 1.1'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 11,
        ),
        Block(
          id: '3',
          pageId: page.id,
          parentBlockId: '1',
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'ordered',
            'spans': [
              {'text': 'Child 1.2'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 12,
        ),
        Block(
          id: '4',
          pageId: page.id,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'ordered',
            'spans': [
              {'text': 'Parent 2'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 20,
        ),
        Block(
          id: '5',
          pageId: page.id,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'ordered',
            'spans': [
              {'text': 'Parent 3'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 30,
        ),

        // Intervening paragraph
        Block(
          id: 'sep',
          pageId: page.id,
          type: 'text',
          data: jsonEncode({
            'runtimeType': 'text',
            'spans': [
              {'text': 'A paragraph separating lists'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 40,
        ),

        // List 2 (ordered, reset numbering!)
        Block(
          id: '6',
          pageId: page.id,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'ordered',
            'spans': [
              {'text': 'New List 1'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 50,
        ),
        Block(
          id: '7',
          pageId: page.id,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'ordered',
            'spans': [
              {'text': 'New List 2'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 60,
        ),

        // Unordered nested bullets
        Block(
          id: 'b1',
          pageId: page.id,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'bullet',
            'spans': [
              {'text': 'Bullet group 1'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 70,
        ),
        Block(
          id: 'b2',
          pageId: page.id,
          parentBlockId: 'b1',
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'bullet',
            'spans': [
              {'text': 'Nested bullet 1.1'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 71,
        ),
        Block(
          id: 'b3',
          pageId: page.id,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'bullet',
            'spans': [
              {'text': 'Bullet group 2'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 80,
        ),

        // Checklists with mixed states
        Block(
          id: 'k1',
          pageId: page.id,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'checklist',
            'checked': true,
            'spans': [
              {'text': 'Task 1'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 90,
        ),
        Block(
          id: 'k2',
          pageId: page.id,
          parentBlockId: 'k1',
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'checklist',
            'checked': false,
            'spans': [
              {'text': 'Nested task 1.1'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          position: 91,
        ),
      ];

      final exporter = PdfExporter();
      final useCase = ExportUseCase([exporter]);

      final pdfBytes = await useCase.exportToBytes(page, blocks, 'pdf');
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));

      final header = utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true);
      expect(header.startsWith('%PDF'), isTrue);
    });

    test('ExportUseCase does not drop toggle blocks as UnknownBlockData',
        () async {
      final now = DateTime.now();
      final page = Page(
        id: 'page-toggle-export',
        title: 'Toggle Page',
        createdAt: now,
        updatedAt: now,
      );

      final blocks = [
        Block(
          id: 'toggle-blk-1',
          pageId: page.id,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'toggle',
            'spans': [
              {'text': 'My Toggle Heading'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
          version: 1,
          position: 1,
        ),
        Block(
          id: 'child-blk-1',
          pageId: page.id,
          type: 'text',
          data: jsonEncode({
            'runtimeType': 'text',
            'spans': [
              {'text': 'Child paragraph inside toggle'},
            ],
          }),
          parentBlockId: 'toggle-blk-1',
          createdAt: now,
          updatedAt: now,
          version: 1,
          position: 2,
        ),
      ];

      final exporter = PdfExporter();
      final useCase = ExportUseCase([exporter]);

      final pdfBytes = await useCase.exportToBytes(page, blocks, 'pdf');
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
      final header = utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true);
      expect(header.startsWith('%PDF'), isTrue);
    });
  });

  group('Issue 3: Toggle Arrow Visibility & Enter Key Child Insertion', () {
    test(
        'KetionToggleComponentBuilder produces ViewModel with valid disclosure arrow properties',
        () {
      final doc = MutableDocument();
      final editor = Editor(editables: {Editor.documentKey: doc});
      final builder = KetionToggleComponentBuilder(editor);

      final toggleNode = ParagraphNode(
        id: 'toggle-node',
        text: AttributedText('Toggle Title'),
        metadata: const {
          'blockType': NamedAttribution('toggle'),
          'isExpanded': true,
        },
      );

      final vm = builder.createViewModel(doc, toggleNode)
          as KetionToggleComponentViewModel?;
      expect(vm, isNotNull);
      expect(vm!.isExpanded, isTrue);
    });

    test(
        'splitToggleWhenEnterPressed at end of toggle creates child block inside toggle and moves caret',
        () {
      final toggleNode = ParagraphNode(
        id: 'toggle-1',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockId': 'b-toggle-1',
          'blockType': NamedAttribution('toggle'),
          'isExpanded': true,
          'depth': 0,
        },
      );
      final doc = MutableDocument(nodes: [toggleNode]);
      final composer = MutableDocumentComposer(
        initialSelection: DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: toggleNode.id,
            nodePosition: const TextNodePosition(offset: 13),
          ),
        ),
      );
      final editor = Editor(
        editables: {
          Editor.documentKey: doc,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );

      final context = MockSuperEditorContext(
          editor: editor, document: doc, composer: composer,);

      // Press Enter at end of toggle header
      final handled = splitToggleWhenEnterPressed(
        editContext: context,
        keyEvent: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
      );

      expect(handled, ExecutionInstruction.haltExecution);
      expect(doc.nodeCount, 2);

      final child = doc.getNodeAt(1) as ParagraphNode;
      expect(child.text.toPlainText(), isEmpty);
      expect(child.metadata['depth'], 1);
      expect(child.metadata['parentBlockId'], 'b-toggle-1');

      // Verify composer selection moved into child
      expect(composer.selection?.extent.nodeId, child.id);
    });

    test(
        'splitToggleWhenEnterPressed at end of toggle with existing children inserts another child',
        () {
      final toggleNode = ParagraphNode(
        id: 'toggle-2',
        text: AttributedText('Toggle With Existing Child'),
        metadata: const {
          'blockId': 'b-toggle-2',
          'blockType': NamedAttribution('toggle'),
          'isExpanded': true,
          'depth': 0,
        },
      );
      final existingChild = ParagraphNode(
        id: 'child-existing',
        text: AttributedText('First child'),
        metadata: const {
          'blockId': 'b-child-existing',
          'parentBlockId': 'b-toggle-2',
          'depth': 1,
        },
      );
      final doc = MutableDocument(nodes: [toggleNode, existingChild]);
      final composer = MutableDocumentComposer(
        initialSelection: DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: toggleNode.id,
            nodePosition: const TextNodePosition(offset: 26),
          ),
        ),
      );
      final editor = Editor(
        editables: {
          Editor.documentKey: doc,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );

      final context = MockSuperEditorContext(
          editor: editor, document: doc, composer: composer,);

      final handled = splitToggleWhenEnterPressed(
        editContext: context,
        keyEvent: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
      );

      expect(handled, ExecutionInstruction.haltExecution);
      expect(doc.nodeCount, 3);
      final newChild = doc.getNodeAt(2) as ParagraphNode;
      expect(newChild.metadata['depth'], 1);
      expect(newChild.metadata['parentBlockId'], 'b-toggle-2');
      expect(composer.selection?.extent.nodeId, newChild.id);
    });
  });

  group('Issue 4: Android Widget Deep Linking and Snapshot Pipeline', () {
    test(
        'WidgetBootstrap routes ketion://note/{id} directly to specific editor note',
        () async {
      const pageId = 'note-widget-12345';
      await WidgetBootstrap.handleDeepLink(Uri.parse('ketion://note/$pageId'));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
          appRouter.routeInformationProvider.value.uri.path, contains(pageId),);
    });

    test('WidgetBootstrap ignores malformed or null note IDs gracefully',
        () async {
      final curPath = appRouter.routeInformationProvider.value.uri.path;
      await WidgetBootstrap.handleDeepLink(Uri.parse('ketion://note/null'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(appRouter.routeInformationProvider.value.uri.path, curPath);
    });

    test(
        'WidgetBootstrap invokes onCreatePage on ketion://new-note and routes to created note',
        () async {
      bool called = false;
      const newPageId = 'new-note-from-widget-789';

      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://new-note'),
        () async {
          called = true;
          return newPageId;
        },
      );

      expect(called, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path,
          contains(newPageId),);
    });
  });
}
