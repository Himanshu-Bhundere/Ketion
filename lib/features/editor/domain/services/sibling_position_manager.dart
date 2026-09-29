import '../../../blocks/domain/entities/block.dart';

class SiblingPositionManager {
  /// Calculates a position value for a new block being inserted between two existing blocks.
  ///
  /// - If [beforePosition] is null, we are inserting at the start.
  /// - If [afterPosition] is null, we are inserting at the end.
  /// - If both are null, it's the first block.
  static double calculatePositionBetween(
    double? beforePosition,
    double? afterPosition,
  ) {
    if (beforePosition == null && afterPosition == null) {
      return 0.0;
    } else if (beforePosition == null) {
      return afterPosition! - 1000.0;
    } else if (afterPosition == null) {
      return beforePosition + 1000.0;
    } else {
      return (beforePosition + afterPosition) / 2;
    }
  }

  /// Calculates a position value for a block being moved or inserted between two sibling blocks.
  static double calculatePositionBetweenBlocks(
    Block? beforeBlock,
    Block? afterBlock,
  ) {
    return calculatePositionBetween(
      beforeBlock?.position,
      afterBlock?.position,
    );
  }
}
