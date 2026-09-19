import '../../../blocks/domain/entities/block.dart';
import '../models/visible_block.dart';
import '../models/drop_intent.dart';
import 'sibling_position_manager.dart';

class BlockTreeService {
  /// Builds a flattened visible tree representing the hierarchical block structure.
  /// Enforces a safe visual [maxDepth].
  static List<VisibleBlock> buildVisibleTree(List<Block> blocks, {int maxDepth = 20}) {
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
        visibleBlocks.add(VisibleBlock(
          block: child,
          depth: actualDepth > maxDepth ? maxDepth : actualDepth,
          hasChildren: childrenMap.containsKey(child.id) && childrenMap[child.id]!.isNotEmpty,
        ),);
        traverse(child.id, actualDepth + 1);
      }
    }

    traverse(null, 0);
    return visibleBlocks;
  }

  /// Indents a block by making it a child of its immediately preceding sibling.
  static List<Block> indentBlock(String blockId, List<Block> allBlocks) {
    final block = allBlocks.firstWhere((b) => b.id == blockId);
    
    // Find preceding sibling
    final siblings = allBlocks.where((b) => b.parentBlockId == block.parentBlockId && !b.deleted).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
      
    final siblingIndex = siblings.indexWhere((b) => b.id == blockId);
    if (siblingIndex <= 0) return []; // Cannot indent first sibling
    
    final previousSibling = siblings[siblingIndex - 1];
    
    // Find new position at end of new parent's children
    final newSiblings = allBlocks.where((b) => b.parentBlockId == previousSibling.id && !b.deleted).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
      
    final newPosition = SiblingPositionManager.calculatePositionBetween(
      newSiblings.isEmpty ? null : newSiblings.last.position,
      null,
    );

    return [
      block.copyWith(
        parentBlockId: previousSibling.id,
        position: newPosition,
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// Outdents a block by making it a sibling of its current parent, placed immediately after the parent.
  static List<Block> outdentBlock(String blockId, List<Block> allBlocks) {
    final block = allBlocks.firstWhere((b) => b.id == blockId);
    if (block.parentBlockId == null) return []; // Cannot outdent top-level block

    final parent = allBlocks.firstWhere((b) => b.id == block.parentBlockId);
    
    // The block should be placed after its current parent.
    // Find the parent's siblings to determine the new position.
    final parentSiblings = allBlocks.where((b) => b.parentBlockId == parent.parentBlockId && !b.deleted).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
      
    final parentIndex = parentSiblings.indexWhere((b) => b.id == parent.id);
    Block? blockAfterParent;
    if (parentIndex >= 0 && parentIndex < parentSiblings.length - 1) {
      blockAfterParent = parentSiblings[parentIndex + 1];
    }

    final newPosition = SiblingPositionManager.calculatePositionBetweenBlocks(parent, blockAfterParent);

    return [
      block.copyWith(
        parentBlockId: parent.parentBlockId,
        position: newPosition,
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// Moves a block according to a DropIntent.
  static List<Block> moveBlock(String sourceBlockId, DropIntent intent, List<Block> allBlocks) {
    final sourceBlock = allBlocks.firstWhere((b) => b.id == sourceBlockId);
    
    return intent.when(
      before: (targetId) {
        if (_isDescendant(sourceBlockId, targetId, allBlocks)) return []; // Prevent cycle
        final targetBlock = allBlocks.firstWhere((b) => b.id == targetId);
        
        final targetSiblings = allBlocks.where((b) => b.parentBlockId == targetBlock.parentBlockId && !b.deleted && b.id != sourceBlockId).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
        
        final targetIndex = targetSiblings.indexWhere((b) => b.id == targetId);
        Block? blockBeforeTarget;
        if (targetIndex > 0) {
          blockBeforeTarget = targetSiblings[targetIndex - 1];
        }

        final newPos = SiblingPositionManager.calculatePositionBetweenBlocks(blockBeforeTarget, targetBlock);
        
        return [
          sourceBlock.copyWith(
            parentBlockId: targetBlock.parentBlockId,
            position: newPos,
            updatedAt: DateTime.now(),
          ),
        ];
      },
      after: (targetId) {
        if (_isDescendant(sourceBlockId, targetId, allBlocks)) return [];
        final targetBlock = allBlocks.firstWhere((b) => b.id == targetId);
        
        final targetSiblings = allBlocks.where((b) => b.parentBlockId == targetBlock.parentBlockId && !b.deleted && b.id != sourceBlockId).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
        
        final targetIndex = targetSiblings.indexWhere((b) => b.id == targetId);
        Block? blockAfterTarget;
        if (targetIndex >= 0 && targetIndex < targetSiblings.length - 1) {
          blockAfterTarget = targetSiblings[targetIndex + 1];
        }

        final newPos = SiblingPositionManager.calculatePositionBetweenBlocks(targetBlock, blockAfterTarget);
        
        return [
          sourceBlock.copyWith(
            parentBlockId: targetBlock.parentBlockId,
            position: newPos,
            updatedAt: DateTime.now(),
          ),
        ];
      },
      child: (targetId) {
        if (_isDescendant(sourceBlockId, targetId, allBlocks)) return [];
        
        final targetChildren = allBlocks.where((b) => b.parentBlockId == targetId && !b.deleted && b.id != sourceBlockId).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
          
        final newPos = SiblingPositionManager.calculatePositionBetweenBlocks(
          targetChildren.isEmpty ? null : targetChildren.last, 
          null,
        );

        return [
          sourceBlock.copyWith(
            parentBlockId: targetId,
            position: newPos,
            updatedAt: DateTime.now(),
          ),
        ];
      },
    );
  }

  /// Checks if [possibleDescendantId] is a descendant of [ancestorId] to prevent cycles.
  static bool _isDescendant(String ancestorId, String possibleDescendantId, List<Block> allBlocks) {
    if (ancestorId == possibleDescendantId) return true;
    
    final Map<String, Block> blockMap = { for (var b in allBlocks) b.id : b };
    
    String? currentId = possibleDescendantId;
    while (currentId != null) {
      if (currentId == ancestorId) return true;
      currentId = blockMap[currentId]?.parentBlockId;
    }
    return false;
  }
}
