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
    String type = 'text',
    String data = '{}',
  }) {
    return Block(
      id: id,
      pageId: 'page_1',
      parentBlockId: parentId,
      type: type,
      position: position,
      data: data,
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

    test('buildVisibleTree hides mixed-content descendants when toggle is collapsed', () {
      final blocks = [
        createBlock(
          id: 'toggle_1',
          position: 0,
          type: 'toggle',
          data: '{"isExpanded":false}',
        ),
        createBlock(id: 'p1', parentId: 'toggle_1', position: 0, type: 'text'),
        createBlock(
          id: 'h1',
          parentId: 'toggle_1',
          position: 1,
          type: 'text',
          data: '{"headingLevel":1}',
        ),
        createBlock(
          id: 'b1',
          parentId: 'toggle_1',
          position: 2,
          type: 'list',
          data: '{"listType":"bullet"}',
        ),
        createBlock(
          id: 'n1',
          parentId: 'toggle_1',
          position: 3,
          type: 'list',
          data: '{"listType":"numbered"}',
        ),
        createBlock(
          id: 'c1',
          parentId: 'toggle_1',
          position: 4,
          type: 'list',
          data: '{"listType":"checklist"}',
        ),
        createBlock(id: 'img1', parentId: 'toggle_1', position: 5, type: 'image'),
        createBlock(id: 'vid1', parentId: 'toggle_1', position: 6, type: 'video'),
        createBlock(id: 'after_toggle', position: 10, type: 'text'),
      ];

      final tree = BlockTreeService.buildVisibleTree(blocks);

      expect(tree.length, 2);
      expect(tree[0].block.id, 'toggle_1');
      expect(tree[0].depth, 0);
      expect(tree[0].hasChildren, isTrue);
      expect(tree[0].isExpanded, isFalse);

      expect(tree[1].block.id, 'after_toggle');
      expect(tree[1].depth, 0);
    });

    test('buildVisibleTree shows all mixed-content descendants in correct order when toggle is expanded', () {
      final blocks = [
        createBlock(
          id: 'toggle_1',
          position: 0,
          type: 'toggle',
          data: '{"isExpanded":true}',
        ),
        createBlock(id: 'p1', parentId: 'toggle_1', position: 0, type: 'text'),
        createBlock(
          id: 'h1',
          parentId: 'toggle_1',
          position: 1,
          type: 'text',
          data: '{"headingLevel":1}',
        ),
        createBlock(
          id: 'b1',
          parentId: 'toggle_1',
          position: 2,
          type: 'list',
          data: '{"listType":"bullet"}',
        ),
        createBlock(
          id: 'n1',
          parentId: 'toggle_1',
          position: 3,
          type: 'list',
          data: '{"listType":"numbered"}',
        ),
        createBlock(
          id: 'c1',
          parentId: 'toggle_1',
          position: 4,
          type: 'list',
          data: '{"listType":"checklist"}',
        ),
        createBlock(id: 'img1', parentId: 'toggle_1', position: 5, type: 'image'),
        createBlock(id: 'vid1', parentId: 'toggle_1', position: 6, type: 'video'),
        createBlock(id: 'after_toggle', position: 10, type: 'text'),
      ];

      final tree = BlockTreeService.buildVisibleTree(blocks);

      expect(tree.length, 9);
      expect(tree.map((v) => v.block.id).toList(), [
        'toggle_1',
        'p1',
        'h1',
        'b1',
        'n1',
        'c1',
        'img1',
        'vid1',
        'after_toggle',
      ]);
      expect(tree[0].isExpanded, isTrue);
      expect(tree[0].hasChildren, isTrue);
      for (int i = 1; i <= 7; i++) {
        expect(tree[i].depth, 1);
      }
      expect(tree[8].depth, 0);
    });

    test('buildVisibleTree handles empty toggle and nested toggles with collapsed inner toggle', () {
      final blocks = [
        createBlock(
          id: 'outer_toggle',
          position: 0,
          type: 'toggle',
          data: '{"isExpanded":true}',
        ),
        createBlock(
          id: 'outer_child_1',
          parentId: 'outer_toggle',
          position: 0,
          type: 'text',
        ),
        createBlock(
          id: 'inner_toggle',
          parentId: 'outer_toggle',
          position: 1,
          type: 'toggle',
          data: '{"isExpanded":false}',
        ),
        createBlock(
          id: 'inner_child_1',
          parentId: 'inner_toggle',
          position: 0,
          type: 'text',
        ),
        createBlock(
          id: 'inner_grandchild',
          parentId: 'inner_child_1',
          position: 0,
          type: 'text',
        ),
        createBlock(
          id: 'outer_child_2',
          parentId: 'outer_toggle',
          position: 2,
          type: 'text',
        ),
        createBlock(
          id: 'empty_toggle',
          position: 1,
          type: 'toggle',
          data: '{"isExpanded":false}',
        ),
      ];

      final tree = BlockTreeService.buildVisibleTree(blocks);

      expect(tree.map((v) => v.block.id).toList(), [
        'outer_toggle',
        'outer_child_1',
        'inner_toggle',
        'outer_child_2',
        'empty_toggle',
      ]);

      expect(tree[0].depth, 0);
      expect(tree[0].isExpanded, isTrue);
      expect(tree[0].hasChildren, isTrue);

      expect(tree[1].depth, 1);

      expect(tree[2].depth, 1);
      expect(tree[2].isExpanded, isFalse);
      expect(tree[2].hasChildren, isTrue);

      expect(tree[3].depth, 1);

      expect(tree[4].depth, 0);
      expect(tree[4].isExpanded, isFalse);
      expect(tree[4].hasChildren, isFalse);
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
      final updated =
          BlockTreeService.moveBlock('a', const DropIntent.after('b'), blocks);
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
      final updated = BlockTreeService.moveBlock(
        'unknown_block',
        const DropIntent.after('a'),
        blocks,
      );
      expect(updated, isEmpty);
    });
  });
}
