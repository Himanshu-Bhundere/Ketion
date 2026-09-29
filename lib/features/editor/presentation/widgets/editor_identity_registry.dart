import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:super_editor/super_editor.dart';

/// A secure registry that manages the identity mapping between Ketion Blocks 
/// and Super Editor DocumentNodes. 
///
/// It maintains a strict 1:1 relationship and prevents generating duplicate 
/// UUIDs or overlapping mappings.
///
/// Also provides:
/// - **Tombstones**: runtime-only, page/editor-scoped map of deleted nodeId → blockId
///   for undo restoration. Contains identity only — no content.
/// - **Snapshots**: captures the current state (active mappings + content hashes)
///   so that undo/redo reconciliation can determine the minimum affected node set.
class EditorIdentityRegistry {
  final Map<String, String> _nodeToBlock = {};
  final Map<String, String> _blockToNode = {};

  // --- Pending Mappings ---
  // Mappings for blocks whose creation is in-flight (SQLite hasn't confirmed yet).
  final Map<String, String> _pendingNodeToBlock = {};
  final Map<String, String> _pendingBlockToNode = {};

  // --- Tombstones ---
  // Runtime-only. Page/editor scoped. Cleared on dispose.
  // Contains only nodeId → blockId. No content.
  final Map<String, String> _tombstones = {};

  // --- Content hash tracking ---
  final Map<String, String> _contentHashes = {};

  // --- Block version tracking ---
  final Map<String, int> _blockVersions = {};

  // --- Block creation time tracking ---
  final Map<String, DateTime> _blockCreatedAts = {};

  // --- Pre-history snapshot for undo reconciliation ---
  _RegistrySnapshot? _snapshot;

  // --- Active mapping accessors ---

  String? blockIdForNode(String nodeId) => _nodeToBlock[nodeId] ?? _pendingNodeToBlock[nodeId];
  
  String? nodeIdForBlock(String blockId) => _blockToNode[blockId] ?? _pendingBlockToNode[blockId];

  bool containsNode(String nodeId) => _nodeToBlock.containsKey(nodeId) || _pendingNodeToBlock.containsKey(nodeId);
  
  bool containsBlock(String blockId) => _blockToNode.containsKey(blockId) || _pendingBlockToNode.containsKey(blockId);

  Iterable<String> get mappedNodeIds => _nodeToBlock.keys;

  int get activeMappingCount => _nodeToBlock.length;

  void registerMapping({required String nodeId, required String blockId}) {
    // 1:1 Invariant checks
    if (_nodeToBlock.containsKey(nodeId) && _nodeToBlock[nodeId] != blockId) {
      assert(false, 'Invariant violation: Node $nodeId already mapped to ${_nodeToBlock[nodeId]}. Cannot map to $blockId.');
      debugPrint('Error: Mapping conflict. Node $nodeId is already mapped to ${_nodeToBlock[nodeId]}. Ignoring new mapping to $blockId.');
      return;
    }
    
    if (_blockToNode.containsKey(blockId) && _blockToNode[blockId] != nodeId) {
      assert(false, 'Invariant violation: Block $blockId already mapped to ${_blockToNode[blockId]}. Cannot map to $nodeId.');
      debugPrint('Error: Mapping conflict. Block $blockId is already mapped to ${_blockToNode[blockId]}. Ignoring new mapping to $nodeId.');
      return;
    }

    _nodeToBlock[nodeId] = blockId;
    _blockToNode[blockId] = nodeId;
  }

  void registerPendingMapping({required String nodeId, required String blockId}) {
    _pendingNodeToBlock[nodeId] = blockId;
    _pendingBlockToNode[blockId] = nodeId;
  }

  void promotePendingMapping(String blockId) {
    final nodeId = _pendingBlockToNode.remove(blockId);
    if (nodeId != null) {
      _pendingNodeToBlock.remove(nodeId);
      registerMapping(nodeId: nodeId, blockId: blockId);
    }
  }

  void removeMappingForNode(String nodeId) {
    final blockId = _nodeToBlock.remove(nodeId);
    if (blockId != null) {
      _blockToNode.remove(blockId);
    }
    final pendingBlockId = _pendingNodeToBlock.remove(nodeId);
    if (pendingBlockId != null) {
      _pendingBlockToNode.remove(pendingBlockId);
    }
  }

  void removeMappingForBlock(String blockId) {
    final nodeId = _blockToNode.remove(blockId);
    if (nodeId != null) {
      _nodeToBlock.remove(nodeId);
    }
    final pendingNodeId = _pendingBlockToNode.remove(blockId);
    if (pendingNodeId != null) {
      _pendingNodeToBlock.remove(pendingNodeId);
    }
  }

  // --- Tombstone operations ---

  /// Records a tombstone for a deleted node. Used for undo restoration.
  /// Only stores nodeId → blockId. No content.
  void recordTombstone({required String nodeId, required String blockId}) {
    _tombstones[nodeId] = blockId;
  }

  /// Returns true if a tombstone exists for the given nodeId.
  bool hasTombstone(String nodeId) => _tombstones.containsKey(nodeId);

  /// Returns the blockId from a tombstone, or null if no tombstone exists.
  String? tombstoneBlockId(String nodeId) => _tombstones[nodeId];

  /// Restores a mapping from a tombstone. Moves the entry from tombstones
  /// back to active mappings. Returns the blockId if restoration succeeded.
  String? restoreFromTombstone(String nodeId) {
    final blockId = _tombstones.remove(nodeId);
    if (blockId == null) return null;

    // Re-register the active mapping
    registerMapping(nodeId: nodeId, blockId: blockId);
    return blockId;
  }

  int get tombstoneCount => _tombstones.length;

  // --- Content hash tracking ---

  static String hashContent(String serializedData) {
    final bytes = utf8.encode(serializedData);
    return sha256.convert(bytes).toString();
  }

  void setContentHash(String nodeId, String hash) {
    _contentHashes[nodeId] = hash;
  }

  String? getContentHash(String nodeId) => _contentHashes[nodeId];

  void removeContentHash(String nodeId) {
    _contentHashes.remove(nodeId);
  }

  // --- Block version tracking ---

  void setBlockVersion(String blockId, int version) {
    _blockVersions[blockId] = version;
  }

  int getBlockVersion(String blockId) => _blockVersions[blockId] ?? 1;

  void incrementBlockVersion(String blockId) {
    if (_blockVersions.containsKey(blockId)) {
      _blockVersions[blockId] = _blockVersions[blockId]! + 1;
    }
  }

  void markDeleted(String blockId, int version) {
    final nodeId = _blockToNode.remove(blockId);
    if (nodeId != null) {
      _nodeToBlock.remove(nodeId);
      recordTombstone(nodeId: nodeId, blockId: blockId);
    }
    _blockVersions[blockId] = version;
  }

  // --- Block creation time tracking ---

  void setBlockCreatedAt(String blockId, DateTime createdAt) {
    _blockCreatedAts[blockId] = createdAt;
  }

  DateTime? getBlockCreatedAt(String blockId) => _blockCreatedAts[blockId];

  // --- Pre-history snapshot for undo reconciliation ---

  /// Takes a snapshot of the current active mappings, content hashes, and structure.
  /// Call this before undo/redo so that post-undo reconciliation can
  /// compare against the pre-undo state (not the replayed registry).
  void takeSnapshot(Document document) {
    debugPrint('KETION: takeSnapshot called with ${document.nodeCount} nodes');
    final orderedNodeIds = <String>[];
    final parents = <String, String?>{};

    for (final node in document) {
      orderedNodeIds.add(node.id);
      parents[node.id] = node.metadata['parentBlockId'] as String?;
    }

    _snapshot = _RegistrySnapshot(
      nodeToBlock: Map.of(_nodeToBlock),
      contentHashes: Map.of(_contentHashes),
      orderedNodeIds: orderedNodeIds,
      parents: parents,
    );
  }

  /// Returns the set of node IDs that were affected by undo/redo by diffing
  /// the snapshot (pre-undo state) against a set of currently-present node IDs
  /// and their content hashes.
  ///
  /// Returns null if no snapshot was taken.
  RegistryDiff? diffAgainstSnapshot({
    required Set<String> currentNodeIds,
    required Map<String, String> currentContentHashes,
    required List<String> currentOrderedNodeIds,
    required Map<String, String?> currentParents,
  }) {
    final snapshot = _snapshot;
    if (snapshot == null) return null;

    final snapshotNodeIds = snapshot.nodeToBlock.keys.toSet();

    // Nodes present now but not in snapshot → restored (by undo)
    final restoredNodeIds = currentNodeIds.difference(snapshotNodeIds);

    // Nodes present in snapshot but not now → removed (by undo)
    final removedNodeIds = snapshotNodeIds.difference(currentNodeIds);

    // Nodes present in both but with different content hash or structure
    final contentChangedNodeIds = <String>{};
    final structureChangedNodeIds = <String>{};

    for (final nodeId in currentNodeIds.intersection(snapshotNodeIds)) {
      // Check content
      final oldHash = snapshot.contentHashes[nodeId];
      final newHash = currentContentHashes[nodeId];
      if (oldHash != newHash) {
        contentChangedNodeIds.add(nodeId);
      }

      // Check structure (parent)
      final oldParent = snapshot.parents[nodeId];
      final newParent = currentParents[nodeId];
      if (oldParent != newParent) {
        structureChangedNodeIds.add(nodeId);
      }
    }

    // Check structure (order/position). We can find nodes whose relative order changed.
    // For simplicity, if the ordered lists differ, we might need to flag them.
    // However, Ketion recalculates position on save. If parent is same and relative sibling
    // order is same, position is fine. If a node moved, its index among siblings changed.
    // A simple heuristic: if its index in the flat list changed significantly compared to its 
    // neighbors, or we can just flag structural changes and let the listener recalculate position.
    
    // For now, any node whose previous node changed is considered structure changed.
    for (int i = 0; i < currentOrderedNodeIds.length; i++) {
      final nodeId = currentOrderedNodeIds[i];
      if (!snapshotNodeIds.contains(nodeId)) continue; // restored node, already handled

      final prevNodeId = i > 0 ? currentOrderedNodeIds[i - 1] : null;
      
      final oldIdx = snapshot.orderedNodeIds.indexOf(nodeId);
      final oldPrevNodeId = oldIdx > 0 ? snapshot.orderedNodeIds[oldIdx - 1] : null;

      if (prevNodeId != oldPrevNodeId) {
        structureChangedNodeIds.add(nodeId);
      }
    }

    _snapshot = null; // Consume the snapshot

    return RegistryDiff(
      restoredNodeIds: restoredNodeIds,
      removedNodeIds: removedNodeIds,
      contentChangedNodeIds: contentChangedNodeIds,
      structureChangedNodeIds: structureChangedNodeIds,
      snapshotNodeToBlock: snapshot.nodeToBlock,
    );
  }

  bool get hasSnapshot => _snapshot != null;

  // --- Lifecycle ---

  void clear() {
    _nodeToBlock.clear();
    _blockToNode.clear();
    _pendingNodeToBlock.clear();
    _pendingBlockToNode.clear();
    _tombstones.clear();
    _contentHashes.clear();
    _blockVersions.clear();
    _blockCreatedAts.clear();
    _snapshot = null;
  }

  void assertConsistent() {
    assert(() {
      for (final entry in _nodeToBlock.entries) {
        if (_blockToNode[entry.value] != entry.key) {
          throw StateError('Inconsistent mapping for node ${entry.key}');
        }
      }
      for (final entry in _blockToNode.entries) {
        if (_nodeToBlock[entry.value] != entry.key) {
          throw StateError('Inconsistent mapping for block ${entry.key}');
        }
      }
      return true;
    }());
  }
}

/// Internal snapshot of registry state, used for undo/redo diffing.
class _RegistrySnapshot {
  final Map<String, String> nodeToBlock;
  final Map<String, String> contentHashes;
  final List<String> orderedNodeIds;
  final Map<String, String?> parents;

  const _RegistrySnapshot({
    required this.nodeToBlock,
    required this.contentHashes,
    required this.orderedNodeIds,
    required this.parents,
  });
}

/// Result of diffing a snapshot against the current document state.
/// Contains only the affected node IDs — not the entire document.
class RegistryDiff {
  /// Nodes present now but absent in the snapshot (restored by undo).
  final Set<String> restoredNodeIds;

  /// Nodes present in the snapshot but absent now (removed by undo).
  final Set<String> removedNodeIds;

  /// Nodes present in both but with changed content.
  final Set<String> contentChangedNodeIds;

  /// Nodes present in both but with changed structural position/parent.
  final Set<String> structureChangedNodeIds;

  /// The snapshot's nodeToBlock mapping, for looking up blockIds
  /// of nodes that were in the pre-undo state.
  final Map<String, String> snapshotNodeToBlock;

  const RegistryDiff({
    required this.restoredNodeIds,
    required this.removedNodeIds,
    required this.contentChangedNodeIds,
    required this.structureChangedNodeIds,
    required this.snapshotNodeToBlock,
  });

  bool get hasChanges =>
      restoredNodeIds.isNotEmpty ||
      removedNodeIds.isNotEmpty ||
      contentChangedNodeIds.isNotEmpty ||
      structureChangedNodeIds.isNotEmpty;
}

