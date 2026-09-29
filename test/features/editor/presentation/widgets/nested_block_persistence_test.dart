import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/editor/services/editor_persistence_mutations.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';
import 'package:ketion/features/editor/services/editor_persistence_coordinator.dart';
import 'package:ketion/features/editor/services/editor_persistence_snapshot.dart';
import 'package:ketion/features/editor/services/structural_mutation_builder.dart';
import 'package:super_editor/super_editor.dart';

class MockPersistenceCoordinator implements EditorPersistenceCoordinator {
  @override
  bool enqueue(EditorPersistenceMutation mutation) => true;

  @override
  Stream<EditorPersistenceMutation> get onMutationSuccess => const Stream.empty();

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
  group('Nested Block Persistence', () {
    late EditorPersistenceSnapshot snapshot;
    late MockPersistenceCoordinator coordinator;
    late KetionSuperEditorAdapter adapter;
    late MutableDocument document;
    late Editor editor;

    setUp(() {
      snapshot = EditorPersistenceSnapshot('page-123', {});
      coordinator = MockPersistenceCoordinator();
      adapter = KetionSuperEditorAdapter(
        pageId: 'page-123',
        coordinator: coordinator,
        snapshot: snapshot,
      );
      document = adapter.createDocument([]);
      editor = Editor(
        editables: {
          Editor.documentKey: document,
        },
        requestHandlers: [
          (Editor editor, EditRequest request) {
            // A simple mock for handling Indent requests so they succeed in Super Editor
            // In a real editor, super_editor's core handlers would process this, but here we just
            // simulate the indentation succeeding for testing the Ketion adapter's interception.
            return null; // Let Ketion request handler process it first.
          },
        ],
      );
      adapter.bind(document, editor);
    });

    tearDown(() {
      adapter.dispose();
    });

    test('indenting a block moves it as a child of the previous sibling', () async {
      // 1. Setup two blocks
      const block1Id = 'block-1';
      const block2Id = 'block-2';
      
      final node1 = ParagraphNode(id: 'node-1', text: AttributedText('Line 1'));
      final node2 = ParagraphNode(id: 'node-2', text: AttributedText('Line 2'));
      document.insertNodeAt(0, node1);
      document.insertNodeAt(1, node2);
      
      adapter.registry.registerPendingMapping(nodeId: 'node-1', blockId: block1Id);
      adapter.registry.promotePendingMapping(block1Id);
      adapter.registry.registerPendingMapping(nodeId: 'node-2', blockId: block2Id);
      adapter.registry.promotePendingMapping(block2Id);
      
      snapshot.applyMutation(
        InsertBlockMutation(
          pageId: 'page-123',
          blockId: block1Id,
          data: '{"spans":[]}',
          type: 'text',
          position: 100,
          expectedVersion: 1,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      
      snapshot.applyMutation(
        InsertBlockMutation(
          pageId: 'page-123',
          blockId: block2Id,
          data: '{"spans":[]}',
          type: 'text',
          position: 200,
          expectedVersion: 1,
          createdAt: DateTime.now().toUtc(),
        ),
      );

      // 2. We don't have the full editor request pipeline here because we didn't inject KetionEditRequestHandler.
      // But we can directly test the StructuralMutationBuilder output.
      
      final indentMutation = StructuralMutationBuilder.buildIndentMutation(
        pageId: 'page-123',
        blockId: block2Id,
        snapshot: snapshot,
      );
      
      expect(indentMutation, isNotNull);
      expect(indentMutation!.parentBlockId, equals(block1Id));
      
      snapshot.applyMutation(indentMutation);
      
      final unindentMutation = StructuralMutationBuilder.buildUnindentMutation(
        pageId: 'page-123',
        blockId: block2Id,
        snapshot: snapshot,
      );
      
      expect(unindentMutation, isNotNull);
      expect(unindentMutation!.parentBlockId, isNull);
    });
  });
}
