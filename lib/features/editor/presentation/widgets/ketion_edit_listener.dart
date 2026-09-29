import 'package:flutter/foundation.dart';

import 'package:super_editor/super_editor.dart';
import 'package:uuid/uuid.dart';

import '../../../blocks/domain/entities/block.dart';
import '../../domain/services/block_data_serializer.dart';
import '../../domain/services/sibling_position_manager.dart';
import '../../services/editor_persistence_coordinator.dart';
import '../../services/editor_persistence_mutations.dart' as persistence_mutations;
import 'editor_identity_registry.dart';

/// EditListener that handles undo/redo reconciliation.
///
/// **Design**:
/// - Undo/redo in Super Editor bypasses `EditRequestHandler`s entirely
///   (it replays `EditCommand`s directly).
/// - We detect undo/redo by observing the Editor's `onEdit` callback.
///   After undo/redo, the document state changes without going through
///   our semantic handler.
/// - We use pre-history snapshots (taken before the undo) to diff
///   against post-undo state, and reconcile only the affected blocks.
///
/// **Identity restoration**:
/// - When undo restores a previously deleted node, we check the tombstone
///   registry to restore the original Ketion block ID.
/// - When undo removes a node that was created during the undone operation,
///   we record a tombstone for it.
///
/// **Content reconciliation**:
/// - Only affected nodes (restored, removed, content-changed) are persisted.
/// - Unrelated blocks are never touched.
class KetionEditListener extends EditListener {
  final EditorIdentityRegistry registry;
  final MutableDocument document;
  final String pageId;
  final EditorPersistenceCoordinator coordinator;

  KetionEditListener({
    required this.registry,
    required this.document,
    required this.pageId,
    required this.coordinator,
  });

  @override
  void onEdit(List<EditEvent> changeList) {
    debugPrint('KETION: EditListener.onEdit called. changeList length: ${changeList.length}');
    for (final change in changeList) {
      debugPrint('KETION: EditListener change event: ${change.runtimeType}');
    }
    // Super Editor calls onEdit after every batch of commands.
    // During undo/redo, the document has already been mutated by the replayed commands.
    //
    // We need to detect when undo/redo happened and reconcile.
    // The approach:
    // 1. Before undo/redo: EditorHistoryController calls registry.takeSnapshot(document)
    // 2. After each onEdit: we check if the document state differs from
    //    our registry's expectations, and reconcile the differences.

    // If there is no snapshot, this is a normal typing/semantic edit handled by request handlers.
    // We skip O(N) diffing to keep typing fast.
    if (!registry.hasSnapshot) {
      return;
    }

    // Check for structural changes that weren't handled by our request handler
    _reconcileAfterEdit(changeList);
  }

  /// Reconciles the registry and Ketion state after an edit.
  /// This handles undo/redo scenarios where structural changes bypass the handler.
  void _reconcileAfterEdit(List<EditEvent> changeList) {
    // Collect current document node IDs, content hashes, and structural info
    final currentDocNodeIds = <String>{};
    debugPrint('KETION: currentDocNodeIds length: ${document.nodeCount}');
    final currentContentHashes = <String, String>{};
    final currentOrderedNodeIds = <String>[];
    final currentParents = <String, String?>{};

    for (final node in document) {
      currentDocNodeIds.add(node.id);
      currentOrderedNodeIds.add(node.id);
      currentParents[node.id] = node.metadata['parentBlockId'] as String?;

      if (node is TextNode) {
        currentContentHashes[node.id] =
            EditorIdentityRegistry.hashContent(BlockDataSerializer.encodeDocumentNode(node));
      }
    }

    final diff = registry.diffAgainstSnapshot(
      currentNodeIds: currentDocNodeIds,
      currentContentHashes: currentContentHashes,
      currentOrderedNodeIds: currentOrderedNodeIds,
      currentParents: currentParents,
    );

    if (diff == null || !diff.hasChanges) {
      return;
    }

    debugPrint('KETION: Undo/redo reconciliation detected. '
        'Restored: ${diff.restoredNodeIds.length}, '
        'Removed: ${diff.removedNodeIds.length}, '
        'Content Changed: ${diff.contentChangedNodeIds.length}, '
        'Structure Changed: ${diff.structureChangedNodeIds.length}');

    // Handle restored nodes (undo brought them back)
    for (final nodeId in diff.restoredNodeIds) {
      _handleRestoredNode(nodeId);
    }

    // Handle orphaned nodes (undo removed them)
    for (final nodeId in diff.removedNodeIds) {
      _handleOrphanedNode(nodeId, diff.snapshotNodeToBlock[nodeId]);
    }

    // Persist content and structure changes for nodes that already existed
    final nodesToUpdate = diff.contentChangedNodeIds.union(diff.structureChangedNodeIds);
    if (nodesToUpdate.isNotEmpty) {
      _reconcileNodeUpdates(nodesToUpdate, currentContentHashes);
    }
  }

  /// Handles a node that was restored by undo (exists in document but not in registry).
  void _handleRestoredNode(String nodeId) {
    // Try tombstone restoration first — this preserves the original Ketion block ID
    final restoredBlockId = registry.restoreFromTombstone(nodeId);
    if (restoredBlockId != null) {
      debugPrint('KETION: Restored node $nodeId from tombstone → block $restoredBlockId');
      // The block should still exist in SQLite (it was "deleted" but may still be there
      // depending on delete implementation). Re-create it if needed.
      _ensureBlockExists(nodeId, restoredBlockId);
      return;
    }

    // No tombstone — this is a genuinely new node from undo.
    // This shouldn't normally happen, but handle it gracefully.
    debugPrint('KETION: Node $nodeId restored by undo but has no tombstone. '
        'Creating new block mapping.');
    final newBlockId = const Uuid().v7();
    registry.registerMapping(nodeId: nodeId, blockId: newBlockId);
    _createBlock(nodeId, newBlockId);
  }

  /// Handles a node that was removed by undo (exists in registry but not in document).
  void _handleOrphanedNode(String nodeId, String? snapshotBlockId) {
    final blockId = registry.blockIdForNode(nodeId) ?? snapshotBlockId;
    if (blockId == null) return;

    // Record tombstone for potential redo restoration
    registry.recordTombstone(nodeId: nodeId, blockId: blockId);
    registry.removeMappingForNode(nodeId);
    registry.removeContentHash(nodeId);

    debugPrint('KETION: Node $nodeId removed by undo. Tombstoned block $blockId.');

    // Delete the block from Ketion
    _deleteBlock(blockId);
  }

  /// Reconciles content and structural changes for nodes that exist in both registry and document
  /// but have different content hashes or positions/parents.
  void _reconcileNodeUpdates(
    Set<String> nodesToUpdate,
    Map<String, String> currentContentHashes,
  ) {
    for (final nodeId in nodesToUpdate) {
      if (!registry.containsNode(nodeId)) continue;

      final blockId = registry.blockIdForNode(nodeId)!;
      final node = document.getNodeById(nodeId);
      if (node != null) {
        final newHash = currentContentHashes[nodeId];
        if (newHash != null) {
          registry.setContentHash(nodeId, newHash);
        }
        _updateBlock(blockId, node);
      }
    }
  }

  // --- Persistence helpers (fire-and-forget async) ---

  double _calculatePositionForNode(String nodeId, String? parentBlockId) {
    Block? previousSibling;
    final previousNode = document.getNodeBeforeById(nodeId);
    if (previousNode != null && previousNode.metadata['parentBlockId'] == parentBlockId) {
      final prevBlockId = registry.blockIdForNode(previousNode.id);
      if (prevBlockId != null) {
        previousSibling = Block(
          id: prevBlockId,
          pageId: pageId,
          type: BlockDataSerializer.blockTypeFor(previousNode),
          position: (previousNode.metadata['position'] as num?)?.toDouble() ?? 0,
          data: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }

    Block? nextSibling;
    final nextNode = document.getNodeAfterById(nodeId);
    if (nextNode != null && nextNode.metadata['parentBlockId'] == parentBlockId) {
      final nextBlockId = registry.blockIdForNode(nextNode.id);
      if (nextBlockId != null) {
        nextSibling = Block(
          id: nextBlockId,
          pageId: pageId,
          type: BlockDataSerializer.blockTypeFor(nextNode),
          position: (nextNode.metadata['position'] as num?)?.toDouble() ?? 0,
          data: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }

    return SiblingPositionManager.calculatePositionBetweenBlocks(
      previousSibling, nextSibling,
    );
  }

  void _ensureBlockExists(String nodeId, String blockId) {
    try {
      final node = document.getNodeById(nodeId);
      if (node == null) return;

      final parentBlockId = node.metadata['parentBlockId'] as String?;
      final position = _calculatePositionForNode(nodeId, parentBlockId);
      
      final block = _buildBlockFromNode(node, blockId, pageId, parentBlockId, position);

      coordinator.enqueue(
        persistence_mutations.RestoreBlockMutation(
          pageId: pageId,
          blockId: blockId,
          type: block.type,
          blockCreatedAt: DateTime.now().toUtc(),
          data: block.data,
          parentBlockId: parentBlockId,
          position: position,
          expectedVersion: registry.getBlockVersion(blockId),
          createdAt: DateTime.now().toUtc(),
        ),
      );

      if (node is TextNode) {
        registry.setContentHash(
          nodeId,
          EditorIdentityRegistry.hashContent(BlockDataSerializer.encodeDocumentNode(node)),
        );
      }
    } catch (e) {
      debugPrint('KETION: Failed to ensure block exists for node $nodeId: $e');
    }
  }

  void _createBlock(String nodeId, String blockId) {
    try {
      final node = document.getNodeById(nodeId);
      if (node == null) return;

      final parentBlockId = node.metadata['parentBlockId'] as String?;
      final position = _calculatePositionForNode(nodeId, parentBlockId);
      
      final block = _buildBlockFromNode(node, blockId, pageId, parentBlockId, position);

      coordinator.enqueue(
        persistence_mutations.InsertBlockMutation(
          pageId: pageId,
          blockId: blockId,
          data: block.data,
          parentBlockId: parentBlockId,
          position: position,
          type: block.type,
          createdAt: DateTime.now().toUtc(),
          expectedVersion: 1,
        ),
      );

      if (node is TextNode) {
        registry.setContentHash(
          nodeId,
          EditorIdentityRegistry.hashContent(BlockDataSerializer.encodeDocumentNode(node)),
        );
      }
    } catch (e) {
      debugPrint('KETION: Failed to create block for node $nodeId: $e');
    }
  }

  void _deleteBlock(String blockId) {
    try {
      coordinator.enqueue(
        persistence_mutations.DeleteBlockMutation(
          pageId: pageId,
          blockId: blockId,
          expectedVersion: registry.getBlockVersion(blockId),
          createdAt: DateTime.now().toUtc(),
        ),
      );
    } catch (e) {
      debugPrint('KETION: Failed to delete block $blockId: $e');
    }
  }

  void _updateBlock(String blockId, DocumentNode node) {
    try {
      final parentBlockId = node.metadata['parentBlockId'] as String?;
      final position = _calculatePositionForNode(node.id, parentBlockId);
      
      final block = _buildBlockFromNode(node, blockId, pageId, parentBlockId, position);

      coordinator.enqueue(
        persistence_mutations.UpdateBlockMutation(
          pageId: pageId,
          blockId: blockId,
          type: block.type,
          blockCreatedAt: DateTime.now().toUtc(),
          data: block.data,
          parentBlockId: parentBlockId,
          position: position,
          expectedVersion: registry.getBlockVersion(blockId),
          createdAt: DateTime.now().toUtc(),
        ),
      );
    } catch (e) {
      debugPrint('KETION: Failed to update block $blockId: $e');
    }
  }
}

/// Builds a Ketion Block from a Super Editor DocumentNode.
Block _buildBlockFromNode(
  DocumentNode node, String blockId, String pageId,
  String? parentBlockId, double position,
) {
  return Block(
    id: blockId,
    pageId: pageId,
    parentBlockId: parentBlockId,
    type: BlockDataSerializer.blockTypeFor(node),
    position: position,
    data: BlockDataSerializer.encodeDocumentNode(node),
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
    version: 1,
  );
}
