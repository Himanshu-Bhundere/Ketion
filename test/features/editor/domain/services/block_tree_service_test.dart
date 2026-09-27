import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/domain/models/drop_intent.dart';
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';

void main() {
  final now = DateTime.now();

  Block createBlock(
      {required String id, String? parentId, required double position}) {
    return Block(
      id: id,
      pageId: 'page_1',
      parentBlockId: parentId,
      type: 'text',
      position: position,
      data: '{}',
      createdAt: now,
      updatedAt: now,
    );
  }

  group('BlockTreeService', () {
    test('buildVisibleTree flattens tree correctly', () {
      final blocks = [
        createBlock(id: 'root1', position: 0),
        createBlock(id: 'child1_1', parentId: 'root1', position: 0),
        createBlock(id: 'child1_2', parentId: 'root1', position: 1),
        createBlock(id: 'grandchild', parentId: 'child1_1', position: 0),
        createBlock(id: 'root2', position: 1),
      ];

      final tree = BlockTreeService.buildVisibleTree(blocks);

      expect(tree.length, 5);
      expect(tree[0].block.id, 'root1');
      expect(tree[0].depth, 0);

      expect(tree[1].block.id, 'child1_1');
      expect(tree[1].depth, 1);

      expect(tree[2].block.id, 'grandchild');
      expect(tree[2].depth, 2);

      expect(tree[3].block.id, 'child1_2');
      expect(tree[3].depth, 1);

      expect(tree[4].block.id, 'root2');
      expect(tree[4].depth, 0);
    });

    test('indentBlock moves block into previous sibling', () {
      final blocks = [
        createBlock(id: 'root1', position: 0),
        createBlock(id: 'root2', position: 10),
      ];

      final updated = BlockTreeService.indentBlock('root2', blocks);
      expect(updated.length, 1);
      expect(updated[0].parentBlockId, 'root1');
      expect(updated[0].position,
          0.0); // Assuming SiblingPositionManager gives 0.0 for first child
    });

    test('outdentBlock moves block after its parent', () {
      final blocks = [
        createBlock(id: 'root1', position: 0),
        createBlock(id: 'child', parentId: 'root1', position: 0),
        createBlock(id: 'root2', position: 10),
      ];

      final updated = BlockTreeService.outdentBlock('child', blocks);
      expect(updated.length, 1);
      expect(updated[0].parentBlockId, isNull);
      expect(updated[0].position,
          5.0); // SiblingPositionManager should give middle of 0 and 10
    });

    test('moveBlock handles DropIntent.after correctly', () {
      final blocks = [
        createBlock(id: 'a', position: 0),
        createBlock(id: 'b', position: 10),
        createBlock(id: 'c', position: 20),
      ];

      // Move 'c' after 'a'
      final updated =
          BlockTreeService.moveBlock('c', const DropIntent.after('a'), blocks);
      expect(updated.length, 1);
      expect(updated[0].parentBlockId, isNull);
      expect(updated[0].position, 5.0); // middle of 0 and 10
    });

    test('moveBlock prevents cycles', () {
      final blocks = [
        createBlock(id: 'parent', position: 0),
        createBlock(id: 'child', parentId: 'parent', position: 0),
      ];

      // Attempt to move parent into child
      final updated = BlockTreeService.moveBlock(
          'parent', const DropIntent.child('child'), blocks);
      expect(updated, isEmpty);
    });
  });
}
