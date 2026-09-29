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
    test('collapsing and expanding a toggle should preserve children in cache', () async {
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
          'spans': [{'text': 'Toggle parent'}],
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
          'spans': [{'text': 'Child'}],
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
          createKetionRequestHandler(registry: adapter.registry, pageId: 'page-1', document: document, composer: MutableDocumentComposer(), coordinator: coordinator, snapshot: snapshot, adapter: adapter),
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
      final updateMutation = coordinator.mutations.lastWhere((m) => m is UpdateBlockMutation && m.blockId == 'toggle-1') as UpdateBlockMutation;
      
      final updatedData = jsonDecode(updateMutation.data);
      expect(updatedData['isExpanded'], false, reason: 'Toggle should be saved as collapsed');

      // Wait for the stream event to be processed by the adapter
      await Future<void>.delayed(Duration.zero);

      // Check the projection
      expect(document.nodeCount, 1, reason: 'Child node was removed from SuperEditor when collapsed');

      // 3. Simulate Restart / Reload
      block1 = block1.copyWith(data: updateMutation.data);
      
      final adapter2 = KetionSuperEditorAdapter(
        pageId: 'page-1',
        coordinator: MockPersistenceCoordinator(),
        snapshot: EditorPersistenceSnapshot('page-1', {}),
      );
      
      final document2 = adapter2.createDocument([block1, childBlock]);
      
      // Because isExpanded is false, the child is omitted from createDocument, but kept in hidden node cache
      expect(document2.nodeCount, 1, reason: 'Child node omitted on reload because parent is collapsed');

      // 4. Expand the toggle via ToggleExpandedRequest
      final editor2 = Editor(
        editables: {
          Editor.documentKey: document2,
        },
        requestHandlers: [
          createKetionRequestHandler(registry: adapter2.registry, pageId: 'page-1', document: document2, composer: MutableDocumentComposer(), coordinator: adapter2.coordinator, snapshot: adapter2.snapshot, adapter: adapter2),
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

      expect(document2.nodeCount, 2, reason: 'Child node is restored from cache when toggle is expanded!');
      final restoredChildNode = document2.getNodeAt(1);
      final childBlockId = adapter2.registry.blockIdForNode(restoredChildNode!.id);
      expect(childBlockId, 'child-1');
    });
  });
}


