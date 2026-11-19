import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import 'package:ketion/features/editor/presentation/widgets/depth_wrapping_component_builder.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_block_drag_wrapper.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_edit_request_handler.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_edit_requests.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';
import 'package:ketion/features/editor/services/editor_persistence_coordinator.dart';
import 'package:ketion/features/editor/services/editor_persistence_mutations.dart';
import 'package:ketion/features/editor/services/editor_persistence_snapshot.dart';
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';

class _TestMockCoordinator implements EditorPersistenceCoordinator {
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
  group('SuperEditorBlockDragWrapper & Reordering Tests', () {
    late MutableDocument doc;
    late MutableDocumentComposer composer;
    late Editor editor;
    late KetionSuperEditorAdapter adapter;
    late _TestMockCoordinator coordinator;
    late EditorPersistenceSnapshot snapshot;

    setUp(() {
      doc = MutableDocument(
        nodes: [
          ParagraphNode(
            id: 'node-p1',
            text: AttributedText('Paragraph 1'),
            metadata: const {'depth': 0, 'blockId': 'b-p1'},
          ),
          ParagraphNode(
            id: 'node-t1',
            text: AttributedText('Toggle 1'),
            metadata: const {'depth': 0, 'blockId': 'b-t1', 'blockType': 'toggle', 'isExpanded': true},
          ),
          ParagraphNode(
            id: 'node-t1-child',
            text: AttributedText('Toggle Child 1'),
            metadata: const {'depth': 1, 'blockId': 'b-t1-child', 'parentBlockId': 'b-t1'},
          ),
          ParagraphNode(
            id: 'node-p2',
            text: AttributedText('Paragraph 2'),
            metadata: const {'depth': 0, 'blockId': 'b-p2'},
          ),
        ],
      );

      composer = MutableDocumentComposer();
      coordinator = _TestMockCoordinator();
      snapshot = EditorPersistenceSnapshot('test-page', {
        'b-p1': BlockSnapshot(
          blockId: 'b-p1',
          pageId: 'test-page',
          version: 1,
          position: 1000.0,
          type: 'paragraph',
          createdAt: DateTime.now().toUtc(),
          deleted: false,
        ),
        'b-t1': BlockSnapshot(
          blockId: 'b-t1',
          pageId: 'test-page',
          version: 1,
          position: 2000.0,
          type: 'toggle',
          createdAt: DateTime.now().toUtc(),
          deleted: false,
        ),
        'b-t1-child': BlockSnapshot(
          blockId: 'b-t1-child',
          pageId: 'test-page',
          version: 1,
          parentBlockId: 'b-t1',
          position: 1000.0,
          type: 'paragraph',
          createdAt: DateTime.now().toUtc(),
          deleted: false,
        ),
        'b-p2': BlockSnapshot(
          blockId: 'b-p2',
          pageId: 'test-page',
          version: 1,
          position: 3000.0,
          type: 'paragraph',
          createdAt: DateTime.now().toUtc(),
          deleted: false,
        ),
      });

      adapter = KetionSuperEditorAdapter(
        pageId: 'test-page',
        coordinator: coordinator,
        snapshot: snapshot,
      );

      adapter.registry.registerMapping(nodeId: 'node-p1', blockId: 'b-p1');
      adapter.registry.registerMapping(nodeId: 'node-t1', blockId: 'b-t1');
      adapter.registry.registerMapping(nodeId: 'node-t1-child', blockId: 'b-t1-child');
      adapter.registry.registerMapping(nodeId: 'node-p2', blockId: 'b-p2');

      editor = Editor(
        editables: {
          Editor.documentKey: doc,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          createKetionRequestHandler(
            registry: adapter.registry,
            pageId: 'test-page',
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
    });

    testWidgets('Renders Draggable on desktop and LongPressDraggable on mobile', (tester) async {
      // 1. Desktop (Windows)
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: Scaffold(
            body: SuperEditorBlockDragWrapper(
              nodeId: 'node-p1',
              document: doc,
              editor: editor,
              child: const Text('Hello Desktop'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Draggable<BlockDragPayload>), findsOneWidget);
      expect(find.byType(LongPressDraggable<BlockDragPayload>), findsNothing);
      expect(find.text('Hello Desktop'), findsOneWidget);

      // 2. Mobile (Android)
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: SuperEditorBlockDragWrapper(
              nodeId: 'node-p1',
              document: doc,
              editor: editor,
              child: const Text('Hello Mobile'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LongPressDraggable<BlockDragPayload>), findsOneWidget);
      expect(find.byType(Draggable<BlockDragPayload>), findsNothing);
      expect(find.text('Hello Mobile'), findsOneWidget);
    });

    test('MoveNodeRequest moves standalone block forward correctly', () {
      // Initial: ['node-p1', 'node-t1', 'node-t1-child', 'node-p2']
      // Move node-p1 after node-p2
      // targetIndex of node-p2 is 3.
      editor.execute([
        const MoveNodeRequest(nodeId: 'node-p1', newIndex: 3),
      ]);

      final nodeIds = [for (int i = 0; i < doc.nodeCount; i++) doc.getNodeAt(i)!.id];
      expect(nodeIds, ['node-t1', 'node-t1-child', 'node-p2', 'node-p1']);
    });

    test('MoveNodeRequest moves standalone block backward correctly', () {
      // Initial: ['node-p1', 'node-t1', 'node-t1-child', 'node-p2']
      // Move node-p2 before node-p1 (index 0)
      editor.execute([
        const MoveNodeRequest(nodeId: 'node-p2', newIndex: 0),
      ]);

      final nodeIds = [for (int i = 0; i < doc.nodeCount; i++) doc.getNodeAt(i)!.id];
      expect(nodeIds, ['node-p2', 'node-p1', 'node-t1', 'node-t1-child']);
    });

    test('MoveNodeRequest moves toggle block with all nested children together', () {
      // Initial: ['node-p1', 'node-t1', 'node-t1-child', 'node-p2']
      // Move node-t1 after node-p2
      // node-t1 and its child node-t1-child must both move after node-p2!
      editor.execute([
        const MoveNodeRequest(nodeId: 'node-t1', newIndex: 3),
      ]);

      final nodeIds = [for (int i = 0; i < doc.nodeCount; i++) doc.getNodeAt(i)!.id];
      expect(nodeIds, ['node-p1', 'node-p2', 'node-t1', 'node-t1-child']);
    });

    test('BlockTreeService accurately finds last descendant of subtree', () {
      final t1 = doc.getNodeById('node-t1')!;
      final lastDescendant = BlockTreeService.findLastDescendant(
        doc,
        t1,
        getNodeDepth,
      );
      expect(lastDescendant.id, 'node-t1-child');

      final p1 = doc.getNodeById('node-p1')!;
      final p1Last = BlockTreeService.findLastDescendant(
        doc,
        p1,
        getNodeDepth,
      );
      expect(p1Last.id, 'node-p1');
    });

    test('MoveBlockRequest moves block into expanded toggle as first child and updates persistence accurately', () {
      // Initial: ['node-p1', 'node-t1', 'node-t1-child', 'node-p2']
      // Drop node-p2 on bottom half of node-t1 (isBefore: false)
      editor.execute([
        const MoveBlockRequest(
          sourceNodeId: 'node-p2',
          targetNodeId: 'node-t1',
          isBefore: false,
        ),
      ]);

      final nodeIds = [for (int i = 0; i < doc.nodeCount; i++) doc.getNodeAt(i)!.id];
      expect(nodeIds, ['node-p1', 'node-t1', 'node-p2', 'node-t1-child']);

      final p2 = doc.getNodeById('node-p2')!;
      expect(p2.metadata['parentBlockId'], 'b-t1');
      expect(p2.metadata['depth'], 1);

      // Verify persistence mutation
      final moveMutations = coordinator.mutations.whereType<MoveBlockMutation>().toList();
      expect(moveMutations.isNotEmpty, true);
      final lastMove = moveMutations.last;
      expect(lastMove.blockId, 'b-p2');
      expect(lastMove.parentBlockId, 'b-t1');
      expect(lastMove.position < 1000.0, true);

      // Verify snapshot updated
      final p2Snapshot = snapshot.getBlock('b-p2')!;
      expect(p2Snapshot.parentBlockId, 'b-t1');
      expect(p2Snapshot.position, lastMove.position);
    });

    test('MoveBlockRequest moves block inside toggle before another child', () {
      // Initial: ['node-p1', 'node-t1', 'node-t1-child', 'node-p2']
      // Drop node-p2 before node-t1-child (isBefore: true)
      editor.execute([
        const MoveBlockRequest(
          sourceNodeId: 'node-p2',
          targetNodeId: 'node-t1-child',
          isBefore: true,
        ),
      ]);

      final nodeIds = [for (int i = 0; i < doc.nodeCount; i++) doc.getNodeAt(i)!.id];
      expect(nodeIds, ['node-p1', 'node-t1', 'node-p2', 'node-t1-child']);

      final p2 = doc.getNodeById('node-p2')!;
      expect(p2.metadata['parentBlockId'], 'b-t1');
      expect(p2.metadata['depth'], 1);

      final moveMutations = coordinator.mutations.whereType<MoveBlockMutation>().toList();
      expect(moveMutations.isNotEmpty, true);
      final lastMove = moveMutations.last;
      expect(lastMove.blockId, 'b-p2');
      expect(lastMove.parentBlockId, 'b-t1');
    });

    test('MoveBlockRequest moves child out of toggle to root level', () {
      // Initial: ['node-p1', 'node-t1', 'node-t1-child', 'node-p2']
      // Drop node-t1-child before node-p1 (isBefore: true)
      editor.execute([
        const MoveBlockRequest(
          sourceNodeId: 'node-t1-child',
          targetNodeId: 'node-p1',
          isBefore: true,
        ),
      ]);

      final nodeIds = [for (int i = 0; i < doc.nodeCount; i++) doc.getNodeAt(i)!.id];
      expect(nodeIds, ['node-t1-child', 'node-p1', 'node-t1', 'node-p2']);

      final child = doc.getNodeById('node-t1-child')!;
      expect(child.metadata['parentBlockId'], null);
      expect(child.metadata['depth'], 0);

      final moveMutations = coordinator.mutations.whereType<MoveBlockMutation>().toList();
      expect(moveMutations.isNotEmpty, true);
      final lastMove = moveMutations.last;
      expect(lastMove.blockId, 'b-t1-child');
      expect(lastMove.parentBlockId, null);
      expect(lastMove.position < 1000.0, true);
    });

    testWidgets('Hover reveals drag handle on desktop platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: Scaffold(
            body: SuperEditorBlockDragWrapper(
              nodeId: 'node-p1',
              document: doc,
              editor: editor,
              child: const SizedBox(height: 50, width: 200, child: Text('Block p1')),
            ),
          ),
        ),
      );

      final animatedOpacityFinder = find.byType(AnimatedOpacity);
      expect(animatedOpacityFinder, findsOneWidget);

      AnimatedOpacity opacityWidget = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
      expect(opacityWidget.opacity, 0.0);

      // Simulate mouse enter
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Block p1')));
      await tester.pumpAndSettle();

      opacityWidget = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
      expect(opacityWidget.opacity, 1.0);
    });
  });
}
