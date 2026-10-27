import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_list_item_component.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  final now = DateTime(2026, 10, 24);

  Block createBlock({
    required String id,
    String? parentId,
    required double position,
    String type = 'text',
    String data = '{}',
    bool deleted = false,
  }) {
    return Block(
      id: id,
      pageId: 'page_test',
      parentBlockId: parentId,
      type: type,
      position: position,
      data: data,
      createdAt: now,
      updatedAt: now,
      version: 1,
      deleted: deleted,
    );
  }

  group('BlockTreeService Ordering and Tie-Breaker Tests', () {
    test('siblings sort by position ascending', () {
      final blocks = [
        createBlock(id: 'b2', position: 20.0),
        createBlock(id: 'b1', position: 10.0),
        createBlock(id: 'b3', position: 30.0),
      ];

      final visible = BlockTreeService.buildVisibleTree(blocks);
      expect(visible.map((v) => v.block.id).toList(), ['b1', 'b2', 'b3']);
      expect(visible.map((v) => v.depth).toList(), [0, 0, 0]);
    });

    test('deterministic tie-breaker using block ID when positions are identical', () {
      final blocks = [
        createBlock(id: 'zebra', position: 10.0),
        createBlock(id: 'alpha', position: 10.0),
        createBlock(id: 'beta', position: 10.0),
      ];

      final visible = BlockTreeService.buildVisibleTree(blocks);
      expect(visible.map((v) => v.block.id).toList(), ['alpha', 'beta', 'zebra']);
    });
  });

  group('BlockTreeService Orphan Recovery Tests', () {
    test('recovers blocks with missing parent as root-level entries', () {
      final blocks = [
        createBlock(id: 'root1', position: 0.0),
        // parent 'ghost_parent' does not exist in the block list
        createBlock(id: 'orphan1', parentId: 'ghost_parent', position: 5.0),
        createBlock(id: 'root2', position: 10.0),
      ];

      final visible = BlockTreeService.buildVisibleTree(blocks);
      expect(visible.length, 3);
      expect(visible.map((v) => v.block.id).toList(), ['root1', 'orphan1', 'root2']);
      expect(visible[1].depth, 0);
    });

    test('recovers blocks whose parent is soft-deleted as root-level entries', () {
      final blocks = [
        createBlock(id: 'deleted_parent', position: 0.0, deleted: true),
        createBlock(id: 'child_of_deleted', parentId: 'deleted_parent', position: 2.0),
        createBlock(id: 'normal_root', position: 1.0),
      ];

      final visible = BlockTreeService.buildVisibleTree(blocks);
      expect(visible.length, 2);
      expect(visible.map((v) => v.block.id).toList(), ['normal_root', 'child_of_deleted']);
      expect(visible.firstWhere((v) => v.block.id == 'child_of_deleted').depth, 0);
    });

    test('preserves subtrees under recovered orphaned blocks', () {
      final blocks = [
        createBlock(id: 'orphan_parent', parentId: 'missing_id', position: 1.0),
        createBlock(id: 'orphan_child', parentId: 'orphan_parent', position: 0.0),
      ];

      final visible = BlockTreeService.buildVisibleTree(blocks);
      expect(visible.length, 2);
      expect(visible[0].block.id, 'orphan_parent');
      expect(visible[0].depth, 0);
      expect(visible[1].block.id, 'orphan_child');
      expect(visible[1].depth, 1);
    });
  });

  group('BlockTreeService Cycle and Duplicate Guard Tests', () {
    test('guards against direct parent cycles (A -> B -> A)', () {
      final blocks = [
        createBlock(id: 'cycle_a', parentId: 'cycle_b', position: 1.0),
        createBlock(id: 'cycle_b', parentId: 'cycle_a', position: 2.0),
      ];

      // Must terminate without infinite loop and visit both blocks once
      final visible = BlockTreeService.buildVisibleTree(blocks);
      expect(visible.length, 2);
      final visitedIds = visible.map((v) => v.block.id).toSet();
      expect(visitedIds, containsAll(['cycle_a', 'cycle_b']));
    });

    test('guards against self-referencing block (A -> A)', () {
      final blocks = [
        createBlock(id: 'self_loop', parentId: 'self_loop', position: 0.0),
      ];

      final visible = BlockTreeService.buildVisibleTree(blocks);
      expect(visible.length, 1);
      expect(visible[0].block.id, 'self_loop');
    });

    test('guards against indirect 3-node cycle (A -> B -> C -> A)', () {
      final blocks = [
        createBlock(id: 'node_a', parentId: 'node_c', position: 1.0),
        createBlock(id: 'node_b', parentId: 'node_a', position: 2.0),
        createBlock(id: 'node_c', parentId: 'node_b', position: 3.0),
      ];

      final visible = BlockTreeService.buildVisibleTree(blocks);
      expect(visible.length, 3);
      expect(visible.map((v) => v.block.id).toSet().length, 3);
    });
  });

  group('BlockTreeService Nested Hierarchy and Visibility Tests', () {
    test('nested toggles retain hierarchy and correct hiddenByAncestorId projection', () {
      final outerToggle = createBlock(
        id: 'toggle_outer',
        position: 0.0,
        type: 'list',
        data: jsonEncode({
          'listType': 'toggle',
          'isExpanded': true,
        }),
      );

      final outerChildPara = createBlock(
        id: 'outer_para',
        parentId: 'toggle_outer',
        position: 0.0,
        type: 'paragraph',
      );

      final innerToggle = createBlock(
        id: 'toggle_inner',
        parentId: 'toggle_outer',
        position: 1.0,
        type: 'list',
        data: jsonEncode({
          'listType': 'toggle',
          'isExpanded': false,
        }),
      );

      final innerChildList = createBlock(
        id: 'inner_list',
        parentId: 'toggle_inner',
        position: 0.0,
        type: 'list',
        data: jsonEncode({'listType': 'numbered'}),
      );

      final blocks = [outerToggle, outerChildPara, innerToggle, innerChildList];

      final projected = BlockTreeService.buildFullTreeWithVisibility(blocks);
      expect(projected.length, 4);

      // outerToggle is root and expanded
      expect(projected[0].block.id, 'toggle_outer');
      expect(projected[0].depth, 0);
      expect(projected[0].hiddenByAncestorId, isNull);

      // outerChildPara is child of outerToggle
      expect(projected[1].block.id, 'outer_para');
      expect(projected[1].depth, 1);
      expect(projected[1].hiddenByAncestorId, isNull);

      // innerToggle is child of outerToggle, visible because outer is expanded
      expect(projected[2].block.id, 'toggle_inner');
      expect(projected[2].depth, 1);
      expect(projected[2].hiddenByAncestorId, isNull);

      // innerChildList is child of innerToggle, hidden because innerToggle is collapsed
      expect(projected[3].block.id, 'inner_list');
      expect(projected[3].depth, 2);
      expect(projected[3].hiddenByAncestorId, 'toggle_inner');
    });

    test('collapsing outer toggle hides all nested descendants', () {
      final outerToggle = createBlock(
        id: 'toggle_outer',
        position: 0.0,
        type: 'list',
        data: jsonEncode({
          'listType': 'toggle',
          'isExpanded': false,
        }),
      );

      final innerToggle = createBlock(
        id: 'toggle_inner',
        parentId: 'toggle_outer',
        position: 0.0,
        type: 'list',
        data: jsonEncode({
          'listType': 'toggle',
          'isExpanded': true,
        }),
      );

      final innerChild = createBlock(
        id: 'inner_child',
        parentId: 'toggle_inner',
        position: 0.0,
      );

      final projected = BlockTreeService.buildFullTreeWithVisibility([
        outerToggle,
        innerToggle,
        innerChild,
      ]);

      expect(projected[0].hiddenByAncestorId, isNull);
      expect(projected[1].hiddenByAncestorId, 'toggle_outer');
      expect(projected[2].hiddenByAncestorId, 'toggle_outer');
    });
  });

  group('Numbered List Ordinal Strict Parent Isolation', () {
    test('computes ordinals scoped to parentBlockId and depth', () {
      final item1 = ListItemNode(
        id: 'item1',
        itemType: ListItemType.ordered,
        text: AttributedText('Root 1'),
        metadata: const {'depth': 0, 'parentBlockId': null},
      );
      final item2 = ListItemNode(
        id: 'item2',
        itemType: ListItemType.ordered,
        text: AttributedText('Root 2'),
        metadata: const {'depth': 0, 'parentBlockId': null},
      );
      final item3 = ListItemNode(
        id: 'item3',
        itemType: ListItemType.ordered,
        text: AttributedText('Inside Toggle 1'),
        metadata: const {'depth': 0, 'parentBlockId': 'toggle-1'},
      );

      final doc = MutableDocument(nodes: [item1, item2, item3]);

      expect(computeKetionListItemOrdinalValue(item1, doc), 1);
      expect(computeKetionListItemOrdinalValue(item2, doc), 2);
      expect(computeKetionListItemOrdinalValue(item3, doc), 1);
    });

    test('skips deeper nested descendants when counting preceding siblings', () {
      final item1 = ListItemNode(
        id: 'item1',
        itemType: ListItemType.ordered,
        text: AttributedText('Item 1'),
        metadata: const {'depth': 0, 'parentBlockId': null},
      );
      final subItemA = ListItemNode(
        id: 'sub_a',
        itemType: ListItemType.ordered,
        text: AttributedText('Sub A'),
        indent: 1,
        metadata: const {'depth': 1, 'parentBlockId': 'item1'},
      );
      final item2 = ListItemNode(
        id: 'item2',
        itemType: ListItemType.ordered,
        text: AttributedText('Item 2'),
        metadata: const {'depth': 0, 'parentBlockId': null},
      );

      final doc = MutableDocument(nodes: [item1, subItemA, item2]);

      expect(computeKetionListItemOrdinalValue(item1, doc), 1);
      expect(computeKetionListItemOrdinalValue(subItemA, doc), 1);
      expect(computeKetionListItemOrdinalValue(item2, doc), 2);
    });
  });
}
