import 'package:flutter/foundation.dart';

/// Represents the semantic intent of a structural mutation that the adapter
/// has translated from a Super Editor EditRequest, before it is executed.
///
/// These are small data classes — no logic, just intent + IDs.
/// They serve as the bridge between Super Editor's EditRequest types and
/// Ketion's domain operations.
@immutable
sealed class SemanticMutation {
  const SemanticMutation();
}

/// A paragraph/node split.
/// - [originalNodeId]: the node being split (maps to existing Ketion block K1)
/// - [newNodeId]: the ID Super Editor will assign to the new node (will map to new K2)
class SplitBlockMutation extends SemanticMutation {
  final String originalNodeId;
  final String newNodeId;

  const SplitBlockMutation({
    required this.originalNodeId,
    required this.newNodeId,
  });
}

/// Two paragraphs/nodes merged.
/// - [survivorNodeId]: the node that absorbs content (maps to K1, ID survives)
/// - [victimNodeId]: the node being deleted (maps to K2, becomes tombstone)
class MergeBlocksMutation extends SemanticMutation {
  final String survivorNodeId;
  final String victimNodeId;

  const MergeBlocksMutation({
    required this.survivorNodeId,
    required this.victimNodeId,
  });
}

/// A node is being deleted.
/// - [nodeId]: the node being deleted
class DeleteBlockMutation extends SemanticMutation {
  final String nodeId;

  const DeleteBlockMutation({required this.nodeId});
}

/// A new node is being inserted.
/// - [newNodeId]: the ID of the new node
/// - [insertBeforeNodeId]: the node it's inserted before (null = end of doc)
class InsertBlockMutation extends SemanticMutation {
  final String newNodeId;
  final String? insertBeforeNodeId;
  final String? insertAfterNodeId;

  const InsertBlockMutation({
    required this.newNodeId,
    this.insertBeforeNodeId,
    this.insertAfterNodeId,
  });
}

class MoveBlockMutation extends SemanticMutation {
  final String nodeId;

  const MoveBlockMutation({required this.nodeId});
}

/// A node's semantic type is being changed (e.g., slash menu conversion).
/// - [nodeId]: the node being converted
class ChangeBlockTypeMutation extends SemanticMutation {
  final String nodeId;

  const ChangeBlockTypeMutation({required this.nodeId});
}



