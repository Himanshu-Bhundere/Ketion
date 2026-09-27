import '../domain/services/sibling_position_manager.dart';
import 'editor_persistence_mutations.dart';
import 'editor_persistence_snapshot.dart';

/// Builds persistence mutations synchronously from the current editor snapshot.
/// Ensures mutations capture `expectedVersion` and positions accurately without async gaps.
class StructuralMutationBuilder {
  static SplitBlockMutation? buildSplitMutation({
    required String pageId,
    required String originalBlockId,
    required String originalData,
    required String newBlockId,
    required String newData,
    required String newType,
    required EditorPersistenceSnapshot snapshot,
    String? providedParentBlockId,
  }) {
    final originalBlock = snapshot.getBlock(originalBlockId);
    if (originalBlock == null || originalBlock.deleted) return null;

    final parentBlockId = providedParentBlockId ?? originalBlock.parentBlockId;

    final targetSiblings = snapshot.activeBlocks
        .where((b) => b.parentBlockId == parentBlockId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    BlockSnapshot? blockAfterTarget;
    double? positionAfter;

    if (providedParentBlockId == originalBlockId) {
      if (targetSiblings.isNotEmpty) {
        blockAfterTarget = targetSiblings.first;
      }
      positionAfter = null;
    } else {
      final targetIndex =
          targetSiblings.indexWhere((b) => b.blockId == originalBlockId);
      if (targetIndex >= 0 && targetIndex < targetSiblings.length - 1) {
        blockAfterTarget = targetSiblings[targetIndex + 1];
      }
      positionAfter = originalBlock.position;
    }

    final newPosition = SiblingPositionManager.calculatePositionBetween(
      positionAfter,
      blockAfterTarget?.position,
    );

    return SplitBlockMutation(
      pageId: pageId,
      originalBlockId: originalBlockId,
      originalData: originalData,
      expectedVersion: originalBlock.version,
      originalParentBlockId: originalBlock.parentBlockId,
      originalPosition: originalBlock.position,
      newBlockId: newBlockId,
      newData: newData,
      newType: newType,
      newParentBlockId: parentBlockId,
      newPosition: newPosition,
      originalBlockCreatedAt: originalBlock.createdAt,
      createdAt: DateTime.now().toUtc(),
    );
  }

  static MergeBlocksMutation? buildMergeMutation({
    required String pageId,
    required String survivorBlockId,
    required String survivorData,
    required String victimBlockId,
    required EditorPersistenceSnapshot snapshot,
  }) {
    final survivorBlock = snapshot.getBlock(survivorBlockId);
    final victimBlock = snapshot.getBlock(victimBlockId);

    if (survivorBlock == null ||
        victimBlock == null ||
        survivorBlock.deleted ||
        victimBlock.deleted) {
      return null;
    }

    return MergeBlocksMutation(
      pageId: pageId,
      survivorBlockId: survivorBlockId,
      survivorData: survivorData,
      survivorExpectedVersion: survivorBlock.version,
      victimBlockId: victimBlockId,
      victimExpectedVersion: victimBlock.version,
      survivorBlockCreatedAt: survivorBlock.createdAt,
      createdAt: DateTime.now().toUtc(),
    );
  }

  static DeleteBlockMutation? buildDeleteMutation({
    required String pageId,
    required String blockId,
    required EditorPersistenceSnapshot snapshot,
  }) {
    final block = snapshot.getBlock(blockId);
    if (block == null || block.deleted) return null;

    return DeleteBlockMutation(
      pageId: pageId,
      blockId: blockId,
      expectedVersion: block.version,
      createdAt: DateTime.now().toUtc(),
    );
  }

  static InsertBlockMutation? buildInsertMutation({
    required String pageId,
    required String blockId,
    required String data,
    required String type,
    required String? previousBlockId,
    required String? nextBlockId,
    required EditorPersistenceSnapshot snapshot,
    String? providedParentBlockId,
  }) {
    BlockSnapshot? previousBlock;
    BlockSnapshot? nextBlock;
    String? parentBlockId = providedParentBlockId;

    if (previousBlockId != null) {
      previousBlock = snapshot.getBlock(previousBlockId);
      if (previousBlock != null && !previousBlock.deleted) {
        parentBlockId ??= previousBlock.parentBlockId;
      } else {
        previousBlock = null;
      }
    }

    if (nextBlockId != null) {
      nextBlock = snapshot.getBlock(nextBlockId);
      if (nextBlock != null && !nextBlock.deleted) {
        if (parentBlockId == null) {
          parentBlockId = nextBlock.parentBlockId;
        } else if (parentBlockId != nextBlock.parentBlockId) {
          nextBlock = null;
        }
      } else {
        nextBlock = null;
      }
    }

    final newPosition = SiblingPositionManager.calculatePositionBetween(
      previousBlock?.position,
      nextBlock?.position,
    );

    return InsertBlockMutation(
      pageId: pageId,
      blockId: blockId,
      expectedVersion: 1,
      data: data,
      type: type,
      parentBlockId: parentBlockId,
      previousBlockId: previousBlockId,
      nextBlockId: nextBlockId,
      position: newPosition,
      createdAt: DateTime.now().toUtc(),
    );
  }

  static MoveBlockMutation? buildMoveMutation({
    required String pageId,
    required String blockId,
    required String? previousBlockId,
    required String? nextBlockId,
    required EditorPersistenceSnapshot snapshot,
  }) {
    final block = snapshot.getBlock(blockId);
    if (block == null || block.deleted) return null;

    BlockSnapshot? previousBlock;
    BlockSnapshot? nextBlock;
    String? parentBlockId;

    if (previousBlockId != null) {
      previousBlock = snapshot.getBlock(previousBlockId);
      if (previousBlock != null && !previousBlock.deleted) {
        if (previousBlock.type == 'toggle') {
          parentBlockId = previousBlock.blockId;
        } else {
          parentBlockId = previousBlock.parentBlockId;
        }
      } else {
        previousBlock = null;
      }
    }

    if (nextBlockId != null) {
      nextBlock = snapshot.getBlock(nextBlockId);
      if (nextBlock != null && !nextBlock.deleted) {
        if (parentBlockId == null) {
          parentBlockId = nextBlock.parentBlockId;
        } else if (parentBlockId != nextBlock.parentBlockId) {
          nextBlock = null;
        }
      } else {
        nextBlock = null;
      }
    }

    final newPosition = SiblingPositionManager.calculatePositionBetween(
      previousBlock?.position,
      nextBlock?.position,
    );

    return MoveBlockMutation(
      pageId: pageId,
      blockId: blockId,
      blockCreatedAt: DateTime.now().toUtc(),
      parentBlockId: parentBlockId,
      position: newPosition,
      expectedVersion: block.version,
      createdAt: DateTime.now().toUtc(),
    );
  }

  static ChangeBlockTypeMutation? buildChangeBlockTypeMutation({
    required String pageId,
    required String blockId,
    required String newType,
    required String newData,
    required EditorPersistenceSnapshot snapshot,
  }) {
    final block = snapshot.getBlock(blockId);
    if (block == null || block.deleted) return null;

    return ChangeBlockTypeMutation(
      pageId: pageId,
      blockId: blockId,
      newType: newType,
      newData: newData,
      expectedVersion: block.version,
      blockCreatedAt: block.createdAt,
      createdAt: DateTime.now().toUtc(),
    );
  }

  static MoveBlockMutation? buildIndentMutation({
    required String pageId,
    required String blockId,
    required EditorPersistenceSnapshot snapshot,
  }) {
    final block = snapshot.getBlock(blockId);
    if (block == null || block.deleted) return null;

    final targetSiblings = snapshot.activeBlocks
        .where((b) => b.parentBlockId == block.parentBlockId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final targetIndex = targetSiblings.indexWhere((b) => b.blockId == blockId);
    if (targetIndex <= 0) {
      return null;
    }

    final newParent = targetSiblings[targetIndex - 1];

    final newSiblings = snapshot.activeBlocks
        .where((b) => b.parentBlockId == newParent.blockId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final previousBlockPosition =
        newSiblings.isNotEmpty ? newSiblings.last.position : null;

    final newPosition = SiblingPositionManager.calculatePositionBetween(
      previousBlockPosition,
      null,
    );

    return MoveBlockMutation(
      pageId: pageId,
      blockId: blockId,
      blockCreatedAt: block.createdAt,
      parentBlockId: newParent.blockId,
      position: newPosition,
      expectedVersion: block.version,
      createdAt: DateTime.now().toUtc(),
    );
  }

  static MoveBlockMutation? buildUnindentMutation({
    required String pageId,
    required String blockId,
    required EditorPersistenceSnapshot snapshot,
  }) {
    final block = snapshot.getBlock(blockId);
    if (block == null || block.deleted) return null;

    final parentId = block.parentBlockId;
    if (parentId == null) {
      return null;
    }

    final parentBlock = snapshot.getBlock(parentId);
    if (parentBlock == null || parentBlock.deleted) return null;

    final newParentId = parentBlock.parentBlockId;

    final targetSiblings = snapshot.activeBlocks
        .where((b) => b.parentBlockId == newParentId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final parentIndex = targetSiblings.indexWhere((b) => b.blockId == parentId);

    BlockSnapshot? blockAfterParent;
    if (parentIndex >= 0 && parentIndex < targetSiblings.length - 1) {
      blockAfterParent = targetSiblings[parentIndex + 1];
    }

    final newPosition = SiblingPositionManager.calculatePositionBetween(
      parentBlock.position,
      blockAfterParent?.position,
    );

    return MoveBlockMutation(
      pageId: pageId,
      blockId: blockId,
      blockCreatedAt: block.createdAt,
      parentBlockId: newParentId,
      position: newPosition,
      expectedVersion: block.version,
      createdAt: DateTime.now().toUtc(),
    );
  }
}
