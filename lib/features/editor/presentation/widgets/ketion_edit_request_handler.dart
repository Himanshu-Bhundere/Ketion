import 'package:flutter/foundation.dart';
import 'package:super_editor/super_editor.dart';
import 'package:uuid/uuid.dart';

import '../../domain/services/block_data_serializer.dart';

import '../../services/editor_persistence_coordinator.dart';
import '../../services/editor_persistence_mutations.dart' as persistence_mutations;
import '../../services/editor_persistence_snapshot.dart';
import '../../services/structural_mutation_builder.dart';
import 'editor_identity_registry.dart';
import 'semantic_mutation.dart';
import 'super_editor_adapter.dart';
import 'ketion_edit_requests.dart';

/// Creates the Ketion semantic EditRequestHandler.
///
/// This handler is placed **first** in the Editor's requestHandlers list.
/// For structural EditRequests (split, merge, delete, insert), it:
/// 1. Translates the request into a SemanticMutation (determines intent + IDs)
/// 2. If identity cannot be determined: returns a FizzleCommand (does not execute)
/// 3. Returns a KetionDelegatingCommand that:
///    a. Delegates to the original Super Editor command
///    b. After successful document mutation, builds and queues the persistence mutation synchronously
///    c. Applies the mutation to the local persistence snapshot if enqueued successfully
EditRequestHandler createKetionRequestHandler({
  required EditorIdentityRegistry registry,
  required String pageId,
  required MutableDocument document,
  required MutableDocumentComposer composer,
  required EditorPersistenceCoordinator coordinator,
  required EditorPersistenceSnapshot snapshot,
  required KetionSuperEditorAdapter adapter,
}) {
  return (Editor editor, EditRequest request) {
    final mutation = _translateRequest(request, registry);
    if (mutation == null) {
      // Non-structural request → let default handler chain process it
      return null;
    }

    // Verify identity can be determined before executing
    final identityError = _validateIdentity(mutation, registry);
    if (identityError != null) {
      debugPrint('KETION: Cannot execute structural request: $identityError');
      return _FizzleCommand(reason: identityError);
    }

    // Return a delegating command that executes the SE command
    // and then persists the result to Ketion
    return _KetionDelegatingCommand(
      mutation: mutation,
      originalRequest: request,
      registry: registry,
      pageId: pageId,
      document: document,
      composer: composer,
      coordinator: coordinator,
      snapshot: snapshot,
      adapter: adapter,
    );
  };
}

/// Translates a Super Editor EditRequest into a SemanticMutation.
SemanticMutation? _translateRequest(EditRequest request, EditorIdentityRegistry registry) {
  if (request is ConvertSlashCommandRequest) {
    return _translateRequest(request.innerRequest, registry);
  }

  // --- Split requests ---
  if (request is SplitParagraphRequest) {
    return SplitBlockMutation(
      originalNodeId: request.nodeId,
      newNodeId: request.newNodeId,
    );
  }
  if (request is SplitListItemRequest) {
    return SplitBlockMutation(
      originalNodeId: request.nodeId,
      newNodeId: request.newNodeId,
    );
  }
  if (request is SplitExistingTaskRequest) {
    final newNodeId = request.newNodeId ?? Editor.createNodeId();
    return SplitBlockMutation(
      originalNodeId: request.existingNodeId,
      newNodeId: newNodeId,
    );
  }

  // --- Merge requests ---
  if (request is CombineParagraphsRequest) {
    return MergeBlocksMutation(
      survivorNodeId: request.firstNodeId,
      victimNodeId: request.secondNodeId,
    );
  }

  // --- Delete requests ---
  if (request is DeleteNodeRequest) {
    return DeleteBlockMutation(nodeId: request.nodeId);
  }

  // --- Insert requests ---
  if (request is InsertNodeAtIndexRequest) {
    return InsertBlockMutation(newNodeId: request.newNode.id);
  }
  if (request is InsertNodeBeforeNodeRequest) {
    return InsertBlockMutation(
      newNodeId: request.newNode.id,
      insertBeforeNodeId: request.existingNodeId,
    );
  }
  if (request is InsertNodeAfterNodeRequest) {
    return InsertBlockMutation(
      newNodeId: request.newNode.id,
      insertAfterNodeId: request.existingNodeId,
    );
  }
  if (request is InsertNodeAtCaretRequest) {
    return InsertBlockMutation(newNodeId: request.node.id);
  }

  // --- Move requests ---
  if (request is MoveNodeRequest) {
    return MoveBlockMutation(nodeId: request.nodeId);
  }

  // --- Block type change requests ---
  if (request is ConvertParagraphToListItemRequest) {
    return ChangeBlockTypeMutation(nodeId: request.nodeId);
  }
  if (request is ConvertParagraphToTaskRequest) {
    return ChangeBlockTypeMutation(nodeId: request.nodeId);
  }
  if (request is ChangeParagraphBlockTypeRequest) {
    return ChangeBlockTypeMutation(nodeId: request.nodeId);
  }
  if (request is ConvertListItemToParagraphRequest) {
    return ChangeBlockTypeMutation(nodeId: request.nodeId);
  }
  if (request is ConvertTaskToParagraphRequest) {
    return ChangeBlockTypeMutation(nodeId: request.nodeId);
  }
  if (request is ChangeListItemTypeRequest) {
    return ChangeBlockTypeMutation(nodeId: request.nodeId);
  }

  return null;
}

String? _validateIdentity(SemanticMutation mutation, EditorIdentityRegistry registry) {
  switch (mutation) {
    case SplitBlockMutation(:final originalNodeId):
      if (!registry.containsNode(originalNodeId)) return 'Cannot split: no mapping for $originalNodeId';
      return null;
    case MergeBlocksMutation(:final survivorNodeId, :final victimNodeId):
      if (!registry.containsNode(survivorNodeId)) return 'Cannot merge: no mapping for $survivorNodeId';
      if (!registry.containsNode(victimNodeId)) return 'Cannot merge: no mapping for $victimNodeId';
      return null;
    case DeleteBlockMutation(:final nodeId):
      if (!registry.containsNode(nodeId)) return 'Cannot delete: no mapping for $nodeId';
      return null;
    case InsertBlockMutation():
      return null;
    case MoveBlockMutation(:final nodeId):
      if (!registry.containsNode(nodeId)) return 'Cannot move: no mapping for $nodeId';
      return null;
    case ChangeBlockTypeMutation(:final nodeId):
      if (!registry.containsNode(nodeId)) return 'Cannot change type: no mapping for $nodeId';
      return null;
  }
}

class _FizzleCommand extends EditCommand {
  final String reason;

  _FizzleCommand({required this.reason});

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.nonHistorical;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    debugPrint('KETION: Fizzled structural command: $reason');
  }
}

class _KetionDelegatingCommand extends EditCommand {
  final SemanticMutation mutation;
  final EditRequest originalRequest;
  final EditorIdentityRegistry registry;
  final String pageId;
  final MutableDocument document;
  final MutableDocumentComposer composer;
  final EditorPersistenceCoordinator coordinator;
  final EditorPersistenceSnapshot snapshot;
  final KetionSuperEditorAdapter adapter;

  _KetionDelegatingCommand({
    required this.mutation,
    required this.originalRequest,
    required this.registry,
    required this.pageId,
    required this.document,
    required this.composer,
    required this.coordinator,
    required this.snapshot,
    required this.adapter,
  });

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final originalCommand = _createOriginalCommand();
    if (originalCommand == null) {
      debugPrint('KETION: Could not create original command for ${mutation.runtimeType}');
      return;
    }
    
    final request = originalRequest;

    final Set<String> scopeNodeIds = {};
    if (mutation is ChangeBlockTypeMutation) {
      scopeNodeIds.add((mutation as ChangeBlockTypeMutation).nodeId);
    } else if (mutation is SplitBlockMutation) {
      scopeNodeIds.add((mutation as SplitBlockMutation).originalNodeId);
      scopeNodeIds.add((mutation as SplitBlockMutation).newNodeId);
    } else if (mutation is MergeBlocksMutation) {
      scopeNodeIds.add((mutation as MergeBlocksMutation).survivorNodeId);
      scopeNodeIds.add((mutation as MergeBlocksMutation).victimNodeId);
    } else if (mutation is InsertBlockMutation) {
      scopeNodeIds.add((mutation as InsertBlockMutation).newNodeId);
    } else if (mutation is DeleteBlockMutation) {
      scopeNodeIds.add((mutation as DeleteBlockMutation).nodeId);
    } else if (mutation is MoveBlockMutation) {
      scopeNodeIds.add((mutation as MoveBlockMutation).nodeId);
    }

    if (scopeNodeIds.isNotEmpty) {
      adapter.beginSemanticMutation(scopeNodeIds);
    }

    try {
      if (request is ConvertSlashCommandRequest) {
         final node = document.getNodeById(request.target.nodeId);
         if (node is TextNode) {
            final textLength = node.text.toPlainText().length;
            final safeStart = request.target.slashStartIndex.clamp(0, textLength);
            final safeEnd = request.target.slashEndIndex.clamp(0, textLength);
            
            if (safeEnd > safeStart) {
               final deleteCommand = DeleteContentCommand(
                  documentRange: DocumentRange(
                     start: DocumentPosition(nodeId: request.target.nodeId, nodePosition: TextNodePosition(offset: safeStart)),
                     end: DocumentPosition(nodeId: request.target.nodeId, nodePosition: TextNodePosition(offset: safeEnd)),
                  ),
               );
               executor.executeCommand(deleteCommand);
            }
            
            composer.setSelectionWithReason(DocumentSelection.collapsed(
               position: DocumentPosition(
                  nodeId: request.target.nodeId,
                  nodePosition: TextNodePosition(offset: safeStart),
               ),
            ),);
         }
      }

      executor.executeCommand(originalCommand);
    } finally {
      if (scopeNodeIds.isNotEmpty) {
        Future.microtask(() {
          adapter.endSemanticMutation(scopeNodeIds);
        });
      }
    }

    if (mutation is SplitBlockMutation) {
      final newNodeId = (mutation as SplitBlockMutation).newNodeId;
      registry.registerPendingMapping(nodeId: newNodeId, blockId: const Uuid().v7());
    } else if (mutation is InsertBlockMutation) {
      final newNodeId = (mutation as InsertBlockMutation).newNodeId;
      registry.registerPendingMapping(nodeId: newNodeId, blockId: const Uuid().v7());
    }

    if (request is SplitParagraphRequest) {
      composer.setSelectionWithReason(DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: request.newNodeId,
          nodePosition: const TextNodePosition(offset: 0),
        ),
      ),);
    } else if (request is SplitListItemRequest) {
      composer.setSelectionWithReason(DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: request.newNodeId,
          nodePosition: const TextNodePosition(offset: 0),
        ),
      ),);
    } else if (request is SplitExistingTaskRequest) {
      final newNodeId = (mutation as SplitBlockMutation).newNodeId;
      composer.setSelectionWithReason(DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: newNodeId,
          nodePosition: const TextNodePosition(offset: 0),
        ),
      ),);
    } else if (request is InsertNodeAtCaretRequest) {
      final newNode = request.node;
      if (newNode is TextNode) {
        composer.setSelectionWithReason(DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: newNode.id,
            nodePosition: TextNodePosition(offset: newNode.text.toPlainText().length),
          ),
        ),);
      } else {
        composer.setSelectionWithReason(DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: newNode.id,
            nodePosition: const UpstreamDownstreamNodePosition.downstream(),
          ),
        ),);
      }
    }

    persistToKetionSynchronously();
  }

  EditCommand? _createOriginalCommand() {
    final reqToCreate = originalRequest is ConvertSlashCommandRequest 
        ? (originalRequest as ConvertSlashCommandRequest).innerRequest 
        : originalRequest;

    switch (mutation) {
      case SplitBlockMutation():
        if (reqToCreate is SplitParagraphRequest) {
          final req = reqToCreate;
          return SplitParagraphCommand(
            nodeId: req.nodeId,
            splitPosition: req.splitPosition,
            newNodeId: req.newNodeId,
            replicateExistingMetadata: req.replicateExistingMetadata,
            attributionsToExtendToNewParagraph: req.attributionsToExtendToNewParagraph,
          );
        }
        if (reqToCreate is SplitListItemRequest) {
          final req = reqToCreate;
          return SplitListItemCommand(
            nodeId: req.nodeId,
            splitPosition: req.splitPosition,
            newNodeId: req.newNodeId,
          );
        }
        if (reqToCreate is SplitExistingTaskRequest) {
          final req = reqToCreate;
          return SplitExistingTaskCommand(
            nodeId: req.existingNodeId,
            splitOffset: req.splitOffset,
            newNodeId: (mutation as SplitBlockMutation).newNodeId,
          );
        }
        return null;

      case MergeBlocksMutation():
        if (reqToCreate is CombineParagraphsRequest) {
          final req = reqToCreate;
          return CombineParagraphsCommand(
            firstNodeId: req.firstNodeId,
            secondNodeId: req.secondNodeId,
          );
        }
        return null;

      case DeleteBlockMutation():
        if (reqToCreate is DeleteNodeRequest) {
          final req = reqToCreate;
          return DeleteNodeCommand(nodeId: req.nodeId);
        }
        return null;

      case InsertBlockMutation():
        if (reqToCreate is InsertNodeAtIndexRequest) {
          final req = reqToCreate;
          return InsertNodeAtIndexCommand(nodeIndex: req.nodeIndex, newNode: req.newNode);
        }
        if (reqToCreate is InsertNodeBeforeNodeRequest) {
          final req = reqToCreate;
          return InsertNodeBeforeNodeCommand(
            existingNodeId: req.existingNodeId,
            newNode: req.newNode,
          );
        }
        if (reqToCreate is InsertNodeAfterNodeRequest) {
          final req = reqToCreate;
          return InsertNodeAfterNodeCommand(
            existingNodeId: req.existingNodeId,
            newNode: req.newNode,
          );
        }
        if (reqToCreate is InsertNodeAtCaretRequest) {
          final req = reqToCreate;
          return InsertNodeAtCaretCommand(newNode: req.node);
        }
        return null;

      case MoveBlockMutation():
        if (reqToCreate is MoveNodeRequest) {
          final req = reqToCreate;
          return MoveNodeCommand(nodeId: req.nodeId, newIndex: req.newIndex);
        }
        return null;

      case ChangeBlockTypeMutation():
        if (reqToCreate is ConvertParagraphToListItemRequest) {
          final req = reqToCreate;
          return ConvertParagraphToListItemCommand(nodeId: req.nodeId, type: req.type);
        }
        if (reqToCreate is ConvertParagraphToTaskRequest) {
          final req = reqToCreate;
          return ConvertParagraphToTaskCommand(nodeId: req.nodeId);
        }
        if (reqToCreate is ChangeParagraphBlockTypeRequest) {
          final req = reqToCreate;
          return ChangeParagraphBlockTypeCommand(nodeId: req.nodeId, blockType: req.blockType);
        }
        if (reqToCreate is ConvertListItemToParagraphRequest) {
          final req = reqToCreate;
          return ConvertListItemToParagraphCommand(
            nodeId: req.nodeId,
            paragraphMetadata: req.paragraphMetadata,
          );
        }
        if (reqToCreate is ConvertTaskToParagraphRequest) {
          final req = reqToCreate;
          return ConvertTaskToParagraphCommand(nodeId: req.nodeId);
        }
        if (reqToCreate is ChangeListItemTypeRequest) {
          final req = reqToCreate;
          return ChangeListItemTypeCommand(nodeId: req.nodeId, newType: req.newType);
        }
        return null;
    }
  }

  void persistToKetionSynchronously() {
    persistence_mutations.EditorPersistenceMutation? persistenceMutation;
    try {
      switch (mutation) {
        case SplitBlockMutation(:final originalNodeId, :final newNodeId):
          persistenceMutation = _buildSplitPayload(originalNodeId, newNodeId);
        case MergeBlocksMutation(:final survivorNodeId, :final victimNodeId):
          persistenceMutation = _buildMergePayload(survivorNodeId, victimNodeId);
        case DeleteBlockMutation(:final nodeId):
          persistenceMutation = _buildDeletePayload(nodeId);
        case InsertBlockMutation(:final newNodeId):
          persistenceMutation = _buildInsertPayload(newNodeId);
        case MoveBlockMutation(:final nodeId):
          persistenceMutation = _buildMovePayload(nodeId);
        case ChangeBlockTypeMutation(:final nodeId):
          persistenceMutation = _buildChangeBlockTypePayload(nodeId);
      }
    } catch (e) {
      debugPrint('KETION: Payload building failed for ${mutation.runtimeType}: $e');
      return;
    }

    if (persistenceMutation == null) return;

    if (coordinator.enqueue(persistenceMutation)) {
      snapshot.applyMutation(persistenceMutation);
    } else {
      debugPrint('KETION: Coordinator rejected mutation ${mutation.runtimeType}');
    }
  }

  persistence_mutations.SplitBlockMutation? _buildSplitPayload(String originalNodeId, String newNodeId) {
    final originalBlockId = registry.blockIdForNode(originalNodeId)!;
    final newBlockId = registry.blockIdForNode(newNodeId)!;

    final originalNode = document.getNodeById(originalNodeId);
    final newNode = document.getNodeById(newNodeId);
    if (originalNode == null || newNode == null) {
      throw StateError('Split produced unexpected document state');
    }

    final originalData = BlockDataSerializer.encodeDocumentNode(originalNode);
    final newData = BlockDataSerializer.encodeDocumentNode(newNode);
    final newType = BlockDataSerializer.blockTypeFor(newNode);

    return StructuralMutationBuilder.buildSplitMutation(
      pageId: pageId,
      originalBlockId: originalBlockId,
      originalData: originalData,
      newBlockId: newBlockId,
      newData: newData,
      newType: newType,
      snapshot: snapshot,
    );
  }

  persistence_mutations.MergeBlocksMutation? _buildMergePayload(String survivorNodeId, String victimNodeId) {
    final survivorBlockId = registry.blockIdForNode(survivorNodeId)!;
    final victimBlockId = registry.blockIdForNode(victimNodeId)!;

    registry.recordTombstone(nodeId: victimNodeId, blockId: victimBlockId);
    registry.removeMappingForNode(victimNodeId);
    registry.removeContentHash(victimNodeId);

    final survivorNode = document.getNodeById(survivorNodeId);
    if (survivorNode == null) {
      throw StateError('Merge produced unexpected document state');
    }

    final survivorData = BlockDataSerializer.encodeDocumentNode(survivorNode);

    return StructuralMutationBuilder.buildMergeMutation(
      pageId: pageId,
      survivorBlockId: survivorBlockId,
      survivorData: survivorData,
      victimBlockId: victimBlockId,
      snapshot: snapshot,
    );
  }

  persistence_mutations.DeleteBlockMutation? _buildDeletePayload(String nodeId) {
    final blockId = registry.blockIdForNode(nodeId)!;

    registry.recordTombstone(nodeId: nodeId, blockId: blockId);
    registry.removeMappingForNode(nodeId);
    registry.removeContentHash(nodeId);

    return StructuralMutationBuilder.buildDeleteMutation(
      pageId: pageId,
      blockId: blockId,
      snapshot: snapshot,
    );
  }

  persistence_mutations.InsertBlockMutation? _buildInsertPayload(String newNodeId) {
    final node = document.getNodeById(newNodeId);
    if (node == null) return null;

    final newBlockId = registry.blockIdForNode(newNodeId)!;
    final data = BlockDataSerializer.encodeDocumentNode(node);
    final type = BlockDataSerializer.blockTypeFor(node);

    final previousNode = document.getNodeBeforeById(newNodeId);
    final nextNode = document.getNodeAfterById(newNodeId);

    final previousBlockId = previousNode != null ? registry.blockIdForNode(previousNode.id) : null;
    final nextBlockId = nextNode != null ? registry.blockIdForNode(nextNode.id) : null;

    return StructuralMutationBuilder.buildInsertMutation(
      pageId: pageId,
      blockId: newBlockId,
      data: data,
      type: type,
      previousBlockId: previousBlockId,
      nextBlockId: nextBlockId,
      snapshot: snapshot,
    );
  }

  persistence_mutations.MoveBlockMutation? _buildMovePayload(String nodeId) {
    final blockId = registry.blockIdForNode(nodeId);
    if (blockId == null) return null;

    final previousNode = document.getNodeBeforeById(nodeId);
    final nextNode = document.getNodeAfterById(nodeId);

    final previousBlockId = previousNode != null ? registry.blockIdForNode(previousNode.id) : null;
    final nextBlockId = nextNode != null ? registry.blockIdForNode(nextNode.id) : null;

    return StructuralMutationBuilder.buildMoveMutation(
      pageId: pageId,
      blockId: blockId,
      previousBlockId: previousBlockId,
      nextBlockId: nextBlockId,
      snapshot: snapshot,
    );
  }

  persistence_mutations.ChangeBlockTypeMutation? _buildChangeBlockTypePayload(String nodeId) {
    final blockId = registry.blockIdForNode(nodeId)!;

    final node = document.getNodeById(nodeId);
    if (node == null) {
      throw StateError('ChangeBlockType produced unexpected document state');
    }

    final data = BlockDataSerializer.encodeDocumentNode(node);
    final type = BlockDataSerializer.blockTypeFor(node);

    return StructuralMutationBuilder.buildChangeBlockTypeMutation(
      pageId: pageId,
      blockId: blockId,
      newData: data,
      newType: type,
      snapshot: snapshot,
    );
  }
}
