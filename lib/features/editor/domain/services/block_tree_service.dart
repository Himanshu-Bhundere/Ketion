import 'dart:convert';
import '../../../blocks/domain/entities/block.dart';
import '../../services/editor_persistence_mutations.dart'
    as persistence_mutations;
import '../models/visible_block.dart';
import '../models/drop_intent.dart';
import 'package:super_editor/super_editor.dart';
import 'sibling_position_manager.dart';

class BlockTreeService {
  static bool isToggle(Block block) {
    if (block.type == 'toggle') return true;

    try {
      final data = jsonDecode(block.data) as Map<String, dynamic>;
      return data['listType'] == 'toggle' ||
          data['blockType'] == 'toggle' ||
          data['type'] == 'toggle';
    } catch (_) {
      return false;
    }
  }

  static bool isExpanded(Block block) {
    if (!isToggle(block)) return true;

    try {
      final data = jsonDecode(block.data) as Map<String, dynamic>;
      return data['isExpanded'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Builds a flattened visible tree representing the hierarchical block structure.
  /// Enforces a safe visual [maxDepth].
  static List<VisibleBlock> buildVisibleTree(
    List<Block> blocks, {
    int maxDepth = 20,
  }) {
    final activeBlocks = blocks.where((block) => !block.deleted).toList();
    final activeIds = activeBlocks.map((b) => b.id).toSet();

    int sortBlocks(Block a, Block b) {
      final byPosition = a.position.compareTo(b.position);
      return byPosition != 0 ? byPosition : a.id.compareTo(b.id);
    }

    final Map<String, List<Block>> childrenMap = {};
    for (final block in activeBlocks) {
      if (block.parentBlockId != null &&
          activeIds.contains(block.parentBlockId)) {
        childrenMap.putIfAbsent(block.parentBlockId!, () => []).add(block);
      }
    }

    for (final children in childrenMap.values) {
      children.sort(sortBlocks);
    }

    final roots = activeBlocks
        .where(
          (block) =>
              block.parentBlockId == null ||
              !activeIds.contains(block.parentBlockId),
        )
        .toList()
      ..sort(sortBlocks);

    final List<VisibleBlock> visibleBlocks = [];
    final Set<String> visited = {};

    void markSubtreeHidden(Block current) {
      if (!visited.add(current.id)) return;

      for (final child in childrenMap[current.id] ?? const <Block>[]) {
        markSubtreeHidden(child);
      }
    }

    void traverse(Block current, int depth) {
      if (!visited.add(current.id)) return;

      final children = childrenMap[current.id] ?? [];
      final expanded = isExpanded(current);

      visibleBlocks.add(
        VisibleBlock(
          block: current,
          depth: depth.clamp(0, maxDepth),
          hasChildren: children.isNotEmpty,
          isExpanded: expanded,
        ),
      );

      if (isToggle(current) && !expanded) {
        for (final child in children) {
          markSubtreeHidden(child);
        }
        return;
      }

      for (final child in children) {
        traverse(child, depth + 1);
      }
    }

    for (final root in roots) {
      traverse(root, 0);
    }

    final remaining = activeBlocks
        .where((b) => !visited.contains(b.id))
        .toList()
      ..sort(sortBlocks);
    for (final block in remaining) {
      if (!visited.contains(block.id)) {
        traverse(block, 0);
      }
    }

    return visibleBlocks;
  }

  static List<ProjectedBlock> buildFullTreeWithVisibility(
    List<Block> blocks, {
    int maxDepth = 20,
  }) {
    final activeBlocks = blocks.where((block) => !block.deleted).toList();
    final activeIds = activeBlocks.map((b) => b.id).toSet();

    int sortBlocks(Block a, Block b) {
      final byPosition = a.position.compareTo(b.position);
      return byPosition != 0 ? byPosition : a.id.compareTo(b.id);
    }

    final Map<String, List<Block>> childrenMap = {};
    for (final block in activeBlocks) {
      if (block.parentBlockId != null &&
          activeIds.contains(block.parentBlockId)) {
        childrenMap.putIfAbsent(block.parentBlockId!, () => []).add(block);
      }
    }

    for (final children in childrenMap.values) {
      children.sort(sortBlocks);
    }

    final roots = activeBlocks
        .where(
          (block) =>
              block.parentBlockId == null ||
              !activeIds.contains(block.parentBlockId),
        )
        .toList()
      ..sort(sortBlocks);

    final List<ProjectedBlock> projectedBlocks = [];
    final Set<String> visited = {};

    void traverse(Block current, int depth, String? hiddenByAncestorId) {
      if (visited.contains(current.id)) return;
      visited.add(current.id);

      final actualDepth = depth > maxDepth ? maxDepth : depth;
      final children = childrenMap[current.id] ?? [];

      projectedBlocks.add(
        ProjectedBlock(
          block: current,
          depth: actualDepth,
          hasChildren: children.isNotEmpty,
          hiddenByAncestorId: hiddenByAncestorId,
        ),
      );

      bool isExpanded = true;
      try {
        final data = jsonDecode(current.data) as Map<String, dynamic>;
        final isToggle = current.type == 'toggle' ||
            data['listType'] == 'toggle' ||
            data['blockType'] == 'toggle' ||
            data['type'] == 'toggle';
        if (isToggle) {
          isExpanded = data['isExpanded'] as bool? ?? false;
        }
      } catch (_) {}

      final nextHiddenBy = !isExpanded ? current.id : hiddenByAncestorId;
      for (final child in children) {
        traverse(child, depth + 1, nextHiddenBy);
      }
    }

    for (final root in roots) {
      traverse(root, 0, null);
    }

    final remaining = activeBlocks
        .where((b) => !visited.contains(b.id))
        .toList()
      ..sort(sortBlocks);
    for (final block in remaining) {
      if (!visited.contains(block.id)) {
        traverse(block, 0, null);
      }
    }

    return projectedBlocks;
  }

  /// Moves a block according to a DropIntent.
  static List<Block> moveBlock(
    String sourceBlockId,
    DropIntent intent,
    List<Block> allBlocks,
  ) {
    final sourceBlock = allBlocks.firstWhere(
      (b) => b.id == sourceBlockId,
      orElse: () => allBlocks.first,
    );
    if (sourceBlock.id != sourceBlockId || sourceBlock.deleted) return [];

    final targetId = intent.when(
      before: (id) => id,
      after: (id) => id,
      child: (id) => id,
      unnest: (id) => id,
    );

    final targetBlock = allBlocks.firstWhere(
      (b) => b.id == targetId,
      orElse: () => allBlocks.first,
    );
    if (targetBlock.id != targetId || targetBlock.deleted) return [];

    if (sourceBlock.pageId != targetBlock.pageId) {
      return []; // Cross-page move rejected
    }
    final isUnnest = intent.maybeWhen(
      unnest: (_) => true,
      orElse: () => false,
    );
    if (!isUnnest && _isDescendant(sourceBlockId, targetId, allBlocks)) {
      return []; // Prevent cycle
    }

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

        if (sourceBlock.parentBlockId == targetBlock.parentBlockId &&
            sourceBlock.position == newPos) {
          return [];
        }

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

        if (sourceBlock.parentBlockId == targetBlock.parentBlockId &&
            sourceBlock.position == newPos) {
          return [];
        }

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

        if (sourceBlock.parentBlockId == targetId &&
            sourceBlock.position == newPos) {
          return [];
        }

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

        final currentParent =
            allBlocks.firstWhere((b) => b.id == currentParentId);
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

        final parentIndex =
            targetSiblings.indexWhere((b) => b.id == currentParentId);
        Block? blockAfterParent;
        if (parentIndex >= 0 && parentIndex < targetSiblings.length - 1) {
          blockAfterParent = targetSiblings[parentIndex + 1];
        }

        final newPos = SiblingPositionManager.calculatePositionBetweenBlocks(
          currentParent,
          blockAfterParent,
        );

        if (sourceBlock.parentBlockId == destinationParentId &&
            sourceBlock.position == newPos) {
          return [];
        }

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
    final visited = <String>{};

    while (currentId != null && visited.add(currentId)) {
      if (currentId == ancestorId) return true;
      currentId = blockMap[currentId]?.parentBlockId;
    }
    return false;
  }

  static bool _isDepthValid(
    String sourceBlockId,
    String newParentId,
    List<Block> allBlocks, {
    int maxDepth = 20,
  }) {
    final Map<String, Block> blockMap = {for (var b in allBlocks) b.id: b};

    // Calculate new parent depth with cycle protection
    int parentDepth = 0;
    String? currentId = newParentId;
    final visitedParents = <String>{};

    while (currentId != null && visitedParents.add(currentId)) {
      parentDepth++;
      currentId = blockMap[currentId]?.parentBlockId;
    }

    // Calculate source subtree depth with visited set protection
    int maxSubtreeDepth = 0;
    final visitedSubtree = <String>{};

    void traverse(String blockId, int currentDepth) {
      if (!visitedSubtree.add(blockId)) return;

      if (currentDepth > maxSubtreeDepth) {
        maxSubtreeDepth = currentDepth;
      }

      final children =
          allBlocks.where((b) => b.parentBlockId == blockId && !b.deleted);
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
    final originalBlock = currentBlocks.firstWhere(
      (b) => b.id == originalBlockId,
      orElse: () => currentBlocks.first,
    );
    if (originalBlock.id != originalBlockId) return null;

    final targetSiblings = currentBlocks
        .where(
          (b) => b.parentBlockId == originalBlock.parentBlockId && !b.deleted,
        )
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final targetIndex =
        targetSiblings.indexWhere((b) => b.id == originalBlockId);
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
    final survivorBlock = currentBlocks.firstWhere(
      (b) => b.id == survivorBlockId,
      orElse: () => currentBlocks.first,
    );
    final victimBlock = currentBlocks.firstWhere(
      (b) => b.id == victimBlockId,
      orElse: () => currentBlocks.first,
    );

    if (survivorBlock.id != survivorBlockId ||
        victimBlock.id != victimBlockId) {
      return null;
    }

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
    final block = currentBlocks.firstWhere(
      (b) => b.id == blockId,
      orElse: () => currentBlocks.first,
    );
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
      previousBlock = currentBlocks.firstWhere(
        (b) => b.id == previousBlockId,
        orElse: () => currentBlocks.first,
      );
      if (previousBlock.id == previousBlockId) {
        parentBlockId = previousBlock.parentBlockId;
      } else {
        previousBlock = null;
      }
    }

    if (nextBlockId != null) {
      nextBlock = currentBlocks.firstWhere(
        (b) => b.id == nextBlockId,
        orElse: () => currentBlocks.first,
      );
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

    final newPosition = SiblingPositionManager.calculatePositionBetweenBlocks(
      previousBlock,
      nextBlock,
    );

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
    final block = currentBlocks.firstWhere(
      (b) => b.id == blockId,
      orElse: () => currentBlocks.first,
    );
    if (block.id != blockId) return null;

    Block? previousBlock;
    Block? nextBlock;
    String? parentBlockId;

    if (previousBlockId != null) {
      previousBlock = currentBlocks.firstWhere(
        (b) => b.id == previousBlockId,
        orElse: () => currentBlocks.first,
      );
      if (previousBlock.id == previousBlockId) {
        parentBlockId = previousBlock.parentBlockId;
      } else {
        previousBlock = null;
      }
    }

    if (nextBlockId != null) {
      nextBlock = currentBlocks.firstWhere(
        (b) => b.id == nextBlockId,
        orElse: () => currentBlocks.first,
      );
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

    final newPosition = SiblingPositionManager.calculatePositionBetweenBlocks(
      previousBlock,
      nextBlock,
    );

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

  // --- Hierarchy Query & Traversal Service Methods ---

  /// Returns the effective depth of [blockId] derived from its persisted parent chain.
  static int effectiveDepth(String blockId, List<Block> allBlocks) {
    final blockMap = {for (var b in allBlocks) b.id: b};
    int depth = 0;
    String? currentId = blockMap[blockId]?.parentBlockId;
    final visited = <String>{};
    while (currentId != null && !visited.contains(currentId)) {
      visited.add(currentId);
      depth++;
      currentId = blockMap[currentId]?.parentBlockId;
    }
    return depth;
  }

  /// Returns the parent block of [blockId], or null if at root.
  static Block? parentOf(String blockId, List<Block> allBlocks) {
    final block = allBlocks.firstWhere(
      (b) => b.id == blockId,
      orElse: () => allBlocks.first,
    );
    if (block.id != blockId || block.parentBlockId == null) return null;
    final parentId = block.parentBlockId!;
    return allBlocks.firstWhere(
      (b) => b.id == parentId,
      orElse: () => block,
    );
  }

  /// Returns immediate non-deleted children of [blockId] sorted by position.
  static List<Block> childrenOf(String blockId, List<Block> allBlocks) {
    return allBlocks
        .where((b) => b.parentBlockId == blockId && !b.deleted)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  /// Returns non-deleted siblings of [blockId] (including [blockId]) sorted by position.
  static List<Block> siblingsOf(String blockId, List<Block> allBlocks) {
    final block = allBlocks.firstWhere(
      (b) => b.id == blockId,
      orElse: () => allBlocks.first,
    );
    if (block.id != blockId) return [];
    return allBlocks
        .where((b) => b.parentBlockId == block.parentBlockId && !b.deleted)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  /// Returns the last descendant block in the visible tree under [blockId].
  static Block? lastDescendantOf(String blockId, List<Block> allBlocks) {
    final children = childrenOf(blockId, allBlocks);
    if (children.isEmpty) return null;
    final lastChild = children.last;
    final deeper = lastDescendantOf(lastChild.id, allBlocks);
    return deeper ?? lastChild;
  }

  /// Returns the final node belonging to [root]'s contiguous descendant subtree.
  ///
  /// The caller must ensure that the document's effective depth is derived
  /// consistently from its persisted hierarchy.
  static DocumentNode findLastDescendant(
    Document document,
    DocumentNode root,
    int Function(DocumentNode node) effectiveDepth,
  ) {
    var last = root;
    var candidate = document.getNodeAfterById(root.id);
    final rootDepth = effectiveDepth(root);
    final rootBlockId = root.metadata['blockId'] as String? ?? root.id;

    DocumentNode? findNode(String id) {
      final byId = document.getNodeById(id);
      if (byId != null) return byId;
      for (final n in document) {
        if (n.metadata['blockId'] == id) return n;
      }
      return null;
    }

    while (candidate != null && effectiveDepth(candidate) > rootDepth) {
      final candidateParentId = candidate.metadata['parentBlockId'] as String?;
      if (candidateParentId != null &&
          candidateParentId != rootBlockId &&
          candidateParentId != root.id) {
        bool isDescendant = false;
        String? currentParentId = candidateParentId;
        final visited = <String>{};
        while (currentParentId != null && !visited.contains(currentParentId)) {
          visited.add(currentParentId);
          if (currentParentId == rootBlockId || currentParentId == root.id) {
            isDescendant = true;
            break;
          }
          final parentNode = findNode(currentParentId);
          currentParentId = parentNode?.metadata['parentBlockId'] as String?;
        }
        if (!isDescendant) break;
      }

      last = candidate;
      candidate = document.getNodeAfterById(candidate.id);
    }

    return last;
  }
}
