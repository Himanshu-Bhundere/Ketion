import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/domain/models/drop_intent.dart';
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';

void main() {
  final now = DateTime.now();

  Block createBlock({
    required String id,
    String? parentId,
    required double position,
  }) {
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
        'parent',
        const DropIntent.child('child'),
        blocks,
      );
      expect(updated, isEmpty);
    });

    test('moveBlock prevents nesting beyond maxDepth (20 by default)', () {
      final List<Block> blocks = [];
      String? parentId;
      for (int i = 0; i < 20; i++) {
        final id = 'block_$i';
        blocks.add(createBlock(id: id, parentId: parentId, position: 0));
        parentId = id;
      }
      final extraBlock = createBlock(id: 'extra', position: 10);
      blocks.add(extraBlock);

      final updated = BlockTreeService.moveBlock(
        'extra',
        const DropIntent.child('block_19'),
        blocks,
      );
      expect(updated, isEmpty);
    });

    test('moveBlock preserves subtree implicitly', () {
      final blocks = [
        createBlock(id: 'a', position: 0),
        createBlock(id: 'a_child', parentId: 'a', position: 0),
        createBlock(id: 'b', position: 10),
      ];

      // Move 'a' after 'b'
      final updated = BlockTreeService.moveBlock('a', const DropIntent.after('b'), blocks);
      expect(updated.length, 1);
      expect(updated[0].id, 'a');
      // 'a_child' is not in the updated list because its parentId doesn't change,
      // which implies the subtree is preserved implicitly.
    });

    test('moveBlock rejects cross-page moves / unknown source block', () {
      final blocks = [
        createBlock(id: 'a', position: 0),
      ];

      // Try to move a block that is not in the current page
      final updated = BlockTreeService.moveBlock('unknown_block', const DropIntent.after('a'), blocks);
      expect(updated, isEmpty);
    });
  });
}
