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
  }) {
    final originalBlock = snapshot.getBlock(originalBlockId);
    if (originalBlock == null || originalBlock.deleted) return null;

    final targetSiblings = snapshot.activeBlocks
        .where((b) => b.parentBlockId == originalBlock.parentBlockId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final targetIndex = targetSiblings.indexWhere((b) => b.blockId == originalBlockId);
    BlockSnapshot? blockAfterTarget;
    if (targetIndex >= 0 && targetIndex < targetSiblings.length - 1) {
      blockAfterTarget = targetSiblings[targetIndex + 1];
    }

    final newPosition = SiblingPositionManager.calculatePositionBetween(
      originalBlock.position,
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
      newParentBlockId: originalBlock.parentBlockId,
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

    if (survivorBlock == null || victimBlock == null || survivorBlock.deleted || victimBlock.deleted) return null;

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
  }) {
    BlockSnapshot? previousBlock;
    BlockSnapshot? nextBlock;
    String? parentBlockId;

    if (previousBlockId != null) {
      previousBlock = snapshot.getBlock(previousBlockId);
      if (previousBlock != null && !previousBlock.deleted) {
        parentBlockId = previousBlock.parentBlockId;
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
        parentBlockId = previousBlock.parentBlockId;
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
}
