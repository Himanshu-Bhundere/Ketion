import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/domain/services/sibling_position_manager.dart';

void main() {
  final now = DateTime.now();

  Block createBlock(double position) {
    return Block(
      id: 'id',
      pageId: 'page_1',
      type: 'text',
      position: position,
      data: '{}',
      createdAt: now,
      updatedAt: now,
    );
  }

  group('SiblingPositionManager', () {
    test('calculatePositionBetweenBlocks with nulls returns 0.0', () {
      expect(SiblingPositionManager.calculatePositionBetweenBlocks(null, null),
          0.0);
    });

    test('calculatePositionBetweenBlocks with both blocks returns midpoint',
        () {
      final prev = createBlock(10.0);
      final next = createBlock(20.0);
      expect(SiblingPositionManager.calculatePositionBetweenBlocks(prev, next),
          15.0);
    });

    test('calculatePositionBetweenBlocks with only prev returns prev + gap',
        () {
      final prev = createBlock(10.0);
      expect(SiblingPositionManager.calculatePositionBetweenBlocks(prev, null),
          10.0 + 1000.0);
    });

    test('calculatePositionBetweenBlocks with only next returns next - gap',
        () {
      final next = createBlock(10.0);
      expect(SiblingPositionManager.calculatePositionBetweenBlocks(null, next),
          10.0 - 1000.0);
    });
  });
}
