import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/editor/domain/services/list_numbering_service.dart';

void main() {
  group('ListNumberingService', () {
    test('Flat ordered list produces 1-based sequential ordinals', () {
      final entries = [
        const ListNumberingEntry(key: 'item-1', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'item-2', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'item-3', listType: 'numbered', depth: 0),
      ];

      final ordinals = ListNumberingService.computeOrdinals(entries);

      expect(ordinals['item-1'], 1);
      expect(ordinals['item-2'], 2);
      expect(ordinals['item-3'], 3);
    });

    test('Indentation: item indented to child sequence restarts at 1, next child becomes 2', () {
      // 1. Item 1
      //    1. Child 1 (indented item 2)
      //    2. Child 2 (indented item 3)
      // 2. Item 4
      final entries = [
        const ListNumberingEntry(key: 'item-1', listType: 'numbered', depth: 0),
        const ListNumberingEntry(
          key: 'item-2',
          listType: 'numbered',
          depth: 1,
          parentKey: 'item-1',
        ),
        const ListNumberingEntry(
          key: 'item-3',
          listType: 'numbered',
          depth: 1,
          parentKey: 'item-1',
        ),
        const ListNumberingEntry(key: 'item-4', listType: 'numbered', depth: 0),
      ];

      final ordinals = ListNumberingService.computeOrdinals(entries);

      expect(ordinals['item-1'], 1);
      expect(ordinals['item-2'], 1); // Indented item 2 becomes 1 in child sequence
      expect(ordinals['item-3'], 2); // Indented item 3 becomes 2 in child sequence
      expect(ordinals['item-4'], 2); // Outer sequence continues after child items
    });

    test('Separate parent branches: children under different parents each restart at 1', () {
      // 1. Parent A
      //    1. Child A1
      //    2. Child A2
      // 2. Parent B
      //    1. Child B1 (restarts at 1!)
      //    2. Child B2
      final entries = [
        const ListNumberingEntry(key: 'p-a', listType: 'numbered', depth: 0),
        const ListNumberingEntry(
          key: 'c-a1',
          listType: 'numbered',
          depth: 1,
          parentKey: 'p-a',
        ),
        const ListNumberingEntry(
          key: 'c-a2',
          listType: 'numbered',
          depth: 1,
          parentKey: 'p-a',
        ),
        const ListNumberingEntry(key: 'p-b', listType: 'numbered', depth: 0),
        const ListNumberingEntry(
          key: 'c-b1',
          listType: 'numbered',
          depth: 1,
          parentKey: 'p-b',
        ),
        const ListNumberingEntry(
          key: 'c-b2',
          listType: 'numbered',
          depth: 1,
          parentKey: 'p-b',
        ),
      ];

      final ordinals = ListNumberingService.computeOrdinals(entries);

      expect(ordinals['p-a'], 1);
      expect(ordinals['c-a1'], 1);
      expect(ordinals['c-a2'], 2);

      expect(ordinals['p-b'], 2);
      expect(ordinals['c-b1'], 1); // Restarts under parent B
      expect(ordinals['c-b2'], 2);
    });

    test('Same depth with different parentKey terminates backward scan and restarts at 1', () {
      // Two sibling groups at depth 1 that happen to be adjacent without an intervening depth 0
      final entries = [
        const ListNumberingEntry(
          key: 'branch1-item1',
          listType: 'numbered',
          depth: 1,
          parentKey: 'parent-1',
        ),
        const ListNumberingEntry(
          key: 'branch1-item2',
          listType: 'numbered',
          depth: 1,
          parentKey: 'parent-1',
        ),
        const ListNumberingEntry(
          key: 'branch2-item1',
          listType: 'numbered',
          depth: 1,
          parentKey: 'parent-2',
        ),
      ];

      final ordinals = ListNumberingService.computeOrdinals(entries);

      expect(ordinals['branch1-item1'], 1);
      expect(ordinals['branch1-item2'], 2);
      expect(ordinals['branch2-item1'], 1); // Must not count branch 1
    });

    test('Interrupted list: non-numbered item at same depth resets sequence', () {
      final entries = [
        const ListNumberingEntry(key: 'item-1', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'item-2', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'para-break', listType: null, depth: 0),
        const ListNumberingEntry(key: 'item-3', listType: 'numbered', depth: 0),
      ];

      final ordinals = ListNumberingService.computeOrdinals(entries);

      expect(ordinals['item-1'], 1);
      expect(ordinals['item-2'], 2);
      expect(ordinals['para-break'], isNull);
      expect(ordinals['item-3'], 1); // Reset to 1 after paragraph break
    });

    test('Bullet list item at same depth and parent interrupts numbered list sequence', () {
      final entries = [
        const ListNumberingEntry(key: 'item-1', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'bullet-1', listType: 'bullet', depth: 0),
        const ListNumberingEntry(key: 'item-2', listType: 'numbered', depth: 0),
      ];

      final ordinals = ListNumberingService.computeOrdinals(entries);

      expect(ordinals['item-1'], 1);
      expect(ordinals['bullet-1'], isNull);
      expect(ordinals['item-2'], 1);
    });

    test('Outdentation: moving an item out renumbers both source and destination sequences', () {
      // Before outdent:
      // 1. Parent 1
      //    1. Child 1
      //    2. Child 2
      // 2. Parent 2
      final beforeEntries = [
        const ListNumberingEntry(key: 'p1', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'c1', listType: 'numbered', depth: 1, parentKey: 'p1'),
        const ListNumberingEntry(key: 'c2', listType: 'numbered', depth: 1, parentKey: 'p1'),
        const ListNumberingEntry(key: 'p2', listType: 'numbered', depth: 0),
      ];
      final beforeOrdinals = ListNumberingService.computeOrdinals(beforeEntries);
      expect(beforeOrdinals['p1'], 1);
      expect(beforeOrdinals['c1'], 1);
      expect(beforeOrdinals['c2'], 2);
      expect(beforeOrdinals['p2'], 2);

      // After outdent of c2 (c2 becomes sibling of p1 and p2):
      // 1. Parent 1
      //    1. Child 1
      // 2. Child 2 (outdented to depth 0)
      // 3. Parent 2
      final afterEntries = [
        const ListNumberingEntry(key: 'p1', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'c1', listType: 'numbered', depth: 1, parentKey: 'p1'),
        const ListNumberingEntry(key: 'c2', listType: 'numbered', depth: 0, parentKey: null),
        const ListNumberingEntry(key: 'p2', listType: 'numbered', depth: 0),
      ];
      final afterOrdinals = ListNumberingService.computeOrdinals(afterEntries);
      expect(afterOrdinals['p1'], 1);
      expect(afterOrdinals['c1'], 1);
      expect(afterOrdinals['c2'], 2); // Now item 2 at depth 0
      expect(afterOrdinals['p2'], 3); // Shifted to item 3 at depth 0
    });

    test('Multi-level nesting: depth 0 -> depth 1 -> depth 2 preserves correct hierarchy', () {
      // 1. Level 0
      //    1. Level 1
      //       1. Level 2
      //       2. Level 2
      //    2. Level 1
      // 2. Level 0
      final entries = [
        const ListNumberingEntry(key: 'l0-1', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'l1-1', listType: 'numbered', depth: 1, parentKey: 'l0-1'),
        const ListNumberingEntry(key: 'l2-1', listType: 'numbered', depth: 2, parentKey: 'l1-1'),
        const ListNumberingEntry(key: 'l2-2', listType: 'numbered', depth: 2, parentKey: 'l1-1'),
        const ListNumberingEntry(key: 'l1-2', listType: 'numbered', depth: 1, parentKey: 'l0-1'),
        const ListNumberingEntry(key: 'l0-2', listType: 'numbered', depth: 0),
      ];

      final ordinals = ListNumberingService.computeOrdinals(entries);

      expect(ordinals['l0-1'], 1);
      expect(ordinals['l1-1'], 1);
      expect(ordinals['l2-1'], 1);
      expect(ordinals['l2-2'], 2);
      expect(ordinals['l1-2'], 2); // Skips nested level 2 descendants and counts l1-1
      expect(ordinals['l0-2'], 2); // Skips all descendants and counts l0-1
    });

    test('Insertion and deletion dynamically update all subsequent siblings', () {
      // Initial: [Item 1, Item 2, Item 3]
      var entries = [
        const ListNumberingEntry(key: 'i1', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'i2', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'i3', listType: 'numbered', depth: 0),
      ];
      var ordinals = ListNumberingService.computeOrdinals(entries);
      expect(ordinals['i1'], 1);
      expect(ordinals['i2'], 2);
      expect(ordinals['i3'], 3);

      // Insert between i1 and i2: [Item 1, Item New, Item 2, Item 3]
      entries = [
        const ListNumberingEntry(key: 'i1', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'i_new', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'i2', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'i3', listType: 'numbered', depth: 0),
      ];
      ordinals = ListNumberingService.computeOrdinals(entries);
      expect(ordinals['i1'], 1);
      expect(ordinals['i_new'], 2);
      expect(ordinals['i2'], 3);
      expect(ordinals['i3'], 4);

      // Delete i1: [Item New, Item 2, Item 3]
      entries = [
        const ListNumberingEntry(key: 'i_new', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'i2', listType: 'numbered', depth: 0),
        const ListNumberingEntry(key: 'i3', listType: 'numbered', depth: 0),
      ];
      ordinals = ListNumberingService.computeOrdinals(entries);
      expect(ordinals['i_new'], 1);
      expect(ordinals['i2'], 2);
      expect(ordinals['i3'], 3);
    });
  });
}
