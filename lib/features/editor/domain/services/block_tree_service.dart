import '../../../blocks/domain/entities/block.dart';
import '../../services/editor_persistence_mutations.dart' as persistence_mutations;
import '../models/visible_block.dart';
import '../models/drop_intent.dart';
import 'sibling_position_manager.dart';

class BlockTreeService {
  /// Builds a flattened visible tree representing the hierarchical block structure.
  /// Enforces a safe visual [maxDepth].
  static List<VisibleBlock> buildVisibleTree(
    List<Block> blocks, {
    int maxDepth = 20,
  }) {
    final Map<String?, List<Block>> childrenMap = {};
    for (final block in blocks) {
      if (!block.deleted) {
        childrenMap.putIfAbsent(block.parentBlockId, () => []).add(block);
      }
    }

    for (final parentId in childrenMap.keys) {
      childrenMap[parentId]!.sort((a, b) => a.position.compareTo(b.position));
    }

    final List<VisibleBlock> visibleBlocks = [];

    void traverse(String? parentId, int depth) {
      final children = childrenMap[parentId] ?? [];
      for (final child in children) {
        final actualDepth = depth;
        visibleBlocks.add(
          VisibleBlock(
            block: child,
            depth: actualDepth > maxDepth ? maxDepth : actualDepth,
            hasChildren: childrenMap.containsKey(child.id) &&
                childrenMap[child.id]!.isNotEmpty,
          ),
        );
        traverse(child.id, actualDepth + 1);
      }
    }

    traverse(null, 0);
    return visibleBlocks;
  }


  /// Moves a block according to a DropIntent.
  static List<Block> moveBlock(
    String sourceBlockId,
    DropIntent intent,
    List<Block> allBlocks,
  ) {
    final sourceBlock = allBlocks.firstWhere((b) => b.id == sourceBlockId, orElse: () => allBlocks.first);
    if (sourceBlock.id != sourceBlockId || sourceBlock.deleted) return [];

    final targetId = intent.when(
      before: (id) => id,
      after: (id) => id,
      child: (id) => id,
      unnest: (id) => id,
    );

    final targetBlock = allBlocks.firstWhere((b) => b.id == targetId, orElse: () => allBlocks.first);
    if (targetBlock.id != targetId || targetBlock.deleted) return [];

    if (sourceBlock.pageId != targetBlock.pageId) return []; // Cross-page move rejected
    final isUnnest = intent.maybeWhen(
      unnest: (_) => true,
      orElse: () => false,
    );
    if (!isUnnest && _isDescendant(sourceBlockId, targetId, allBlocks)) return []; // Prevent cycle

    return intent.when(
      before: (targetId) {
        final targetSiblings = allBlocks
            .where(
              (b) =>
                  b.parentBlockId == targetBlock.parentBlockId &&
                  !b.deleted &&
                  b.id != sourceBlockId,
            )
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

        final targetIndex = targetSiblings.indexWhere((b) => b.id == targetId);
        Block? blockBeforeTarget;
        if (targetIndex > 0) {
          blockBeforeTarget = targetSiblings[targetIndex - 1];
        }

        final newPos = SiblingPositionManager.calculatePositionBetweenBlocks(
          blockBeforeTarget,
          targetBlock,
        );

        if (sourceBlock.parentBlockId == targetBlock.parentBlockId && sourceBlock.position == newPos) return [];

        return [
          sourceBlock.copyWith(
            parentBlockId: targetBlock.parentBlockId,
            position: newPos,
            updatedAt: DateTime.now().toUtc(),
          ),
        ];
      },
      after: (targetId) {
        final targetSiblings = allBlocks
            .where(
              (b) =>
                  b.parentBlockId == targetBlock.parentBlockId &&
                  !b.deleted &&
                  b.id != sourceBlockId,
            )
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

        final targetIndex = targetSiblings.indexWhere((b) => b.id == targetId);
        Block? blockAfterTarget;
        if (targetIndex >= 0 && targetIndex < targetSiblings.length - 1) {
          blockAfterTarget = targetSiblings[targetIndex + 1];
        }

        final newPos = SiblingPositionManager.calculatePositionBetweenBlocks(
          targetBlock,
          blockAfterTarget,
        );
        
        if (sourceBlock.parentBlockId == targetBlock.parentBlockId && sourceBlock.position == newPos) return [];

        return [
          sourceBlock.copyWith(
            parentBlockId: targetBlock.parentBlockId,
            position: newPos,
            updatedAt: DateTime.now().toUtc(),
          ),
        ];
      },
      child: (targetId) {
        if (!_isDepthValid(sourceBlockId, targetId, allBlocks)) return [];

        final targetChildren = allBlocks
            .where(
              (b) =>
                  b.parentBlockId == targetId &&
                  !b.deleted &&
                  b.id != sourceBlockId,
            )
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

        final newPos = SiblingPositionManager.calculatePositionBetweenBlocks(
          targetChildren.isEmpty ? null : targetChildren.last,
          null,
        );

        if (sourceBlock.parentBlockId == targetId && sourceBlock.position == newPos) return [];

        return [
          sourceBlock.copyWith(
            parentBlockId: targetId,
            position: newPos,
            updatedAt: DateTime.now().toUtc(),
          ),
        ];
      },
      unnest: (targetId) {
        final currentParentId = targetBlock.parentBlockId;
        if (currentParentId == null) return []; // Already at root

        final currentParent = allBlocks.firstWhere((b) => b.id == currentParentId);
        final destinationParentId = currentParent.parentBlockId;

        final targetSiblings = allBlocks
            .where(
              (b) =>
                  b.parentBlockId == destinationParentId &&
                  !b.deleted &&
                  b.id != sourceBlockId,
            )
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

        final parentIndex = targetSiblings.indexWhere((b) => b.id == currentParentId);
        Block? blockAfterParent;
        if (parentIndex >= 0 && parentIndex < targetSiblings.length - 1) {
          blockAfterParent = targetSiblings[parentIndex + 1];
        }

        final newPos = SiblingPositionManager.calculatePositionBetweenBlocks(
          currentParent,
          blockAfterParent,
        );

        if (sourceBlock.parentBlockId == destinationParentId && sourceBlock.position == newPos) return [];

        return [
          sourceBlock.copyWith(
            parentBlockId: destinationParentId,
            position: newPos,
            updatedAt: DateTime.now().toUtc(),
          ),
        ];
      },
    );
  }

  /// Checks if [possibleDescendantId] is a descendant of [ancestorId] to prevent cycles.
  static bool _isDescendant(
    String ancestorId,
    String possibleDescendantId,
    List<Block> allBlocks,
  ) {
    if (ancestorId == possibleDescendantId) return true;

    final Map<String, Block> blockMap = {for (var b in allBlocks) b.id: b};

    String? currentId = possibleDescendantId;
    while (currentId != null) {
      if (currentId == ancestorId) return true;
      currentId = blockMap[currentId]?.parentBlockId;
    }
    return false;
  }

  static bool _isDepthValid(String sourceBlockId, String newParentId, List<Block> allBlocks, {int maxDepth = 20}) {
    final Map<String, Block> blockMap = {for (var b in allBlocks) b.id: b};
    
    // Calculate new parent depth
    int parentDepth = 0;
    String? currentId = newParentId;
    while (currentId != null) {
      parentDepth++;
      currentId = blockMap[currentId]?.parentBlockId;
    }

    // Calculate source subtree depth
    int maxSubtreeDepth = 0;
    void traverse(String blockId, int currentDepth) {
      if (currentDepth > maxSubtreeDepth) maxSubtreeDepth = currentDepth;
      final children = allBlocks.where((b) => b.parentBlockId == blockId && !b.deleted);
      for (final child in children) {
        traverse(child.id, currentDepth + 1);
      }
    }
    
    traverse(sourceBlockId, 1);
    
    return (parentDepth + maxSubtreeDepth) <= maxDepth;
  }

  // --- Mutation Builders for EditorPersistenceCoordinator ---

  static persistence_mutations.SplitBlockMutation? buildSplitMutation({
    required String pageId,
    required String originalBlockId,
    required String originalData,
    required String newBlockId,
    required String newData,
    required String newType,
    required List<Block> currentBlocks,
  }) {
    final originalBlock = currentBlocks.firstWhere((b) => b.id == originalBlockId, orElse: () => currentBlocks.first);
    if (originalBlock.id != originalBlockId) return null;

    final targetSiblings = currentBlocks
        .where((b) => b.parentBlockId == originalBlock.parentBlockId && !b.deleted)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final targetIndex = targetSiblings.indexWhere((b) => b.id == originalBlockId);
    Block? blockAfterTarget;
    if (targetIndex >= 0 && targetIndex < targetSiblings.length - 1) {
      blockAfterTarget = targetSiblings[targetIndex + 1];
    }

    final newPosition = SiblingPositionManager.calculatePositionBetweenBlocks(
      originalBlock,
      blockAfterTarget,
    );

    return persistence_mutations.SplitBlockMutation(
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

  static persistence_mutations.MergeBlocksMutation? buildMergeMutation({
    required String pageId,
    required String survivorBlockId,
    required String survivorData,
    required String victimBlockId,
    required List<Block> currentBlocks,
  }) {
    final survivorBlock = currentBlocks.firstWhere((b) => b.id == survivorBlockId, orElse: () => currentBlocks.first);
    final victimBlock = currentBlocks.firstWhere((b) => b.id == victimBlockId, orElse: () => currentBlocks.first);

    if (survivorBlock.id != survivorBlockId || victimBlock.id != victimBlockId) return null;

    return persistence_mutations.MergeBlocksMutation(
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

  static persistence_mutations.DeleteBlockMutation? buildDeleteMutation({
    required String pageId,
    required String blockId,
    required List<Block> currentBlocks,
  }) {
    final block = currentBlocks.firstWhere((b) => b.id == blockId, orElse: () => currentBlocks.first);
    if (block.id != blockId) return null;

    return persistence_mutations.DeleteBlockMutation(
      pageId: pageId,
      blockId: blockId,
      expectedVersion: block.version,
      createdAt: DateTime.now().toUtc(),
    );
  }

  static persistence_mutations.InsertBlockMutation? buildInsertMutation({
    required String pageId,
    required String blockId,
    required String data,
    required String type,
    required String? previousBlockId,
    required String? nextBlockId,
    required List<Block> currentBlocks,
  }) {
    Block? previousBlock;
    Block? nextBlock;
    String? parentBlockId;

    if (previousBlockId != null) {
      previousBlock = currentBlocks.firstWhere((b) => b.id == previousBlockId, orElse: () => currentBlocks.first);
      if (previousBlock.id == previousBlockId) {
        parentBlockId = previousBlock.parentBlockId;
      } else {
        previousBlock = null;
      }
    }

    if (nextBlockId != null) {
      nextBlock = currentBlocks.firstWhere((b) => b.id == nextBlockId, orElse: () => currentBlocks.first);
      if (nextBlock.id == nextBlockId) {
        if (parentBlockId == null) {
          parentBlockId = nextBlock.parentBlockId;
        } else if (parentBlockId != nextBlock.parentBlockId) {
          // If they don't share a parent, default to the previous block's parent.
          nextBlock = null; 
        }
      } else {
        nextBlock = null;
      }
    }

    final newPosition = SiblingPositionManager.calculatePositionBetweenBlocks(previousBlock, nextBlock);

    return persistence_mutations.InsertBlockMutation(
      pageId: pageId,
      blockId: blockId,
      data: data,
      type: type,
      parentBlockId: parentBlockId,
      position: newPosition,
      expectedVersion: 1,
      createdAt: DateTime.now().toUtc(),
    );
  }

  static persistence_mutations.MoveBlockMutation? buildMoveMutation({
    required String pageId,
    required String blockId,
    required String? previousBlockId,
    required String? nextBlockId,
    required List<Block> currentBlocks,
  }) {
    final block = currentBlocks.firstWhere((b) => b.id == blockId, orElse: () => currentBlocks.first);
    if (block.id != blockId) return null;

    Block? previousBlock;
    Block? nextBlock;
    String? parentBlockId;

    if (previousBlockId != null) {
      previousBlock = currentBlocks.firstWhere((b) => b.id == previousBlockId, orElse: () => currentBlocks.first);
      if (previousBlock.id == previousBlockId) {
        parentBlockId = previousBlock.parentBlockId;
      } else {
        previousBlock = null;
      }
    }

    if (nextBlockId != null) {
      nextBlock = currentBlocks.firstWhere((b) => b.id == nextBlockId, orElse: () => currentBlocks.first);
      if (nextBlock.id == nextBlockId) {
        if (parentBlockId == null) {
          parentBlockId = nextBlock.parentBlockId;
        } else if (parentBlockId != nextBlock.parentBlockId) {
          nextBlock = null; 
        }
      } else {
        nextBlock = null;
      }
    }

    final newPosition = SiblingPositionManager.calculatePositionBetweenBlocks(previousBlock, nextBlock);

    return persistence_mutations.MoveBlockMutation(
      pageId: pageId,
      blockId: blockId,
      parentBlockId: parentBlockId,
      position: newPosition,
      expectedVersion: block.version,
      createdAt: DateTime.now().toUtc(),
      blockCreatedAt: block.createdAt,
    );
  }
}
