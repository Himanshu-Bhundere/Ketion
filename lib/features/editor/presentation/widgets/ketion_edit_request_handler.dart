import 'package:flutter/foundation.dart';
import 'package:ketion/features/editor/presentation/widgets/convert_paragraph_to_callout.dart';
import 'package:super_editor/super_editor.dart';
import 'package:uuid/uuid.dart';
import 'ketion_callout_node.dart';

import '../../domain/services/block_data_serializer.dart';

import '../../services/editor_persistence_coordinator.dart';
import '../../services/editor_persistence_mutations.dart'
    as persistence_mutations;
import '../../services/editor_persistence_snapshot.dart';
import '../../services/structural_mutation_builder.dart';
import 'editor_identity_registry.dart';
import 'semantic_mutation.dart';
import 'super_editor_adapter.dart';
import '../../domain/commands/change_paragraph_metadata.dart';
import '../../domain/models/media_nodes.dart';
import '../../domain/commands/insert_reminder_request.dart';
import 'ketion_edit_requests.dart';
import 'ketion_toggle_component.dart';
import 'ketion_toggle_keyboard_actions.dart';
import 'depth_wrapping_component_builder.dart';
import '../table/ketion_table_node.dart';

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
  void Function(String, KetionReminderNode)? onReminderInserted,
}) {
  return (Editor editor, EditRequest request) {
    // Android IMEs submit Enter as InsertNewlineAtCaretRequest, without a
    // hardware KeyEvent. The keyboard action in ketion_toggle_keyboard_actions
    // therefore cannot see that path. Intercept it here, before SuperEditor
    // falls back to splitting the toggle into an ordinary sibling paragraph.
    final toggleChildCommand =
        _buildToggleChildInsertionCommand(editor, request, registry);
    if (toggleChildCommand != null) {
      return toggleChildCommand;
    }

    // Let all requests pass through to semantic translation

    final mutation = _translateRequest(request, registry);
    if (mutation == null) {
      // Non-structural request → let default handler chain process it
      return null;
    }

    adapter.flushPendingChanges();

    // Verify identity can be determined before executing
    final identityError = _validateIdentity(mutation, registry, snapshot);
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
      onReminderInserted: onReminderInserted,
    );
  };
}

/// Handles the IME newline path for a toggle header.
///
/// Both hardware Enter and IME Enter share the unified toggle helpers in
/// `ketion_toggle_keyboard_actions.dart`.
EditCommand? _buildToggleChildInsertionCommand(
  Editor editor,
  EditRequest request,
  EditorIdentityRegistry registry,
) {
  if (request is! InsertNewlineAtCaretRequest) return null;

  final selection = editor.composer.selection;
  if (selection == null || !selection.isCollapsed) return null;

  final position = selection.extent.nodePosition;
  if (position is! TextNodePosition) return null;

  final node = editor.document.getNodeById(selection.extent.nodeId);
  if (node is! TextNode) return null;

  if (KetionToggleComponentBuilder.isToggleNode(node)) {
    if (position.offset == node.text.length) {
      return _InsertToggleChildCommand(
        editor: editor,
        toggleNode: node,
        registry: registry,
        newNodeId: request.newNodeId,
      );
    } else {
      return _SplitToggleMiddleOfHeaderCommand(
        editor: editor,
        toggleNode: node,
        splitOffset: position.offset,
        registry: registry,
        newNodeId: request.newNodeId,
      );
    }
  }

  if (isInsideToggleBody(node, editor.document, registry)) {
    return _ToggleBodyEnterCommand(
      editor: editor,
      node: node,
      caretOffset: position.offset,
      registry: registry,
      newNodeId: request.newNodeId,
    );
  }

  return null;
}

class _ToggleBodyEnterCommand extends EditCommand {
  _ToggleBodyEnterCommand({
    required this.editor,
    required this.node,
    required this.caretOffset,
    required this.registry,
    required this.newNodeId,
  });

  final Editor editor;
  final TextNode node;
  final int caretOffset;
  final EditorIdentityRegistry registry;
  final String newNodeId;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    executeToggleBodyEnter(
      editor: editor,
      document: context.document,
      node: node,
      caretOffset: caretOffset,
      registry: registry,
      newNodeId: newNodeId,
    );
  }
}

class _InsertToggleChildCommand extends EditCommand {
  _InsertToggleChildCommand({
    required this.editor,
    required this.toggleNode,
    required this.registry,
    required this.newNodeId,
  });

  final Editor editor;
  final TextNode toggleNode;
  final EditorIdentityRegistry registry;
  final String newNodeId;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    insertToggleChild(
      editor: editor,
      document: context.document,
      toggleNode: toggleNode,
      registry: registry,
      newNodeId: newNodeId,
    );
  }
}

class _SplitToggleMiddleOfHeaderCommand extends EditCommand {
  _SplitToggleMiddleOfHeaderCommand({
    required this.editor,
    required this.toggleNode,
    required this.splitOffset,
    required this.registry,
    required this.newNodeId,
  });

  final Editor editor;
  final TextNode toggleNode;
  final int splitOffset;
  final EditorIdentityRegistry registry;
  final String newNodeId;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    splitToggleMiddleOfHeader(
      editor: editor,
      document: context.document,
      toggleNode: toggleNode,
      splitOffset: splitOffset,
      registry: registry,
      newNodeId: newNodeId,
    );
  }
}

class _KetionIndentNodeCommand extends EditCommand {
  _KetionIndentNodeCommand({required this.nodeId});

  final String nodeId;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId);
    if (node == null) return;

    if (node is ListItemNode) {
      final newIndent = node.indent + 1;
      final newMetadata = <String, dynamic>{
        ...node.metadata,
        'depth': newIndent,
      };
      final replacement = node.type == ListItemType.ordered
          ? ListItemNode.ordered(
              id: node.id,
              text: node.text,
              indent: newIndent,
              metadata: newMetadata,
            )
          : ListItemNode.unordered(
              id: node.id,
              text: node.text,
              indent: newIndent,
              metadata: newMetadata,
            );
      context.document.replaceNodeById(node.id, replacement);
      executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
    } else if (node is TaskNode) {
      final newIndent = node.indent + 1;
      final newMetadata = <String, dynamic>{
        ...node.metadata,
        'depth': newIndent,
      };
      final replacement = TaskNode(
        id: node.id,
        text: node.text,
        isComplete: node.isComplete,
        indent: newIndent,
        metadata: newMetadata,
      );
      context.document.replaceNodeById(node.id, replacement);
      executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
    } else if (node is ParagraphNode) {
      final currentDepth = node.metadata['depth'] as int? ?? 0;
      final newDepth = currentDepth + 1;
      final newMetadata = <String, dynamic>{
        ...node.metadata,
        'depth': newDepth,
      };
      context.document.replaceNodeById(
        node.id,
        node.copyAndReplaceMetadata(newMetadata),
      );
      executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
    }
  }
}

class _KetionUnindentNodeCommand extends EditCommand {
  _KetionUnindentNodeCommand({required this.nodeId});

  final String nodeId;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId);
    if (node == null) return;

    if (node is ListItemNode) {
      final newIndent = (node.indent - 1).clamp(0, 99);
      final newMetadata = <String, dynamic>{
        ...node.metadata,
        'depth': newIndent,
      };
      final replacement = node.type == ListItemType.ordered
          ? ListItemNode.ordered(
              id: node.id,
              text: node.text,
              indent: newIndent,
              metadata: newMetadata,
            )
          : ListItemNode.unordered(
              id: node.id,
              text: node.text,
              indent: newIndent,
              metadata: newMetadata,
            );
      context.document.replaceNodeById(node.id, replacement);
      executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
    } else if (node is TaskNode) {
      final newIndent = (node.indent - 1).clamp(0, 99);
      final newMetadata = <String, dynamic>{
        ...node.metadata,
        'depth': newIndent,
      };
      final replacement = TaskNode(
        id: node.id,
        text: node.text,
        isComplete: node.isComplete,
        indent: newIndent,
        metadata: newMetadata,
      );
      context.document.replaceNodeById(node.id, replacement);
      executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
    } else if (node is ParagraphNode) {
      final currentDepth = node.metadata['depth'] as int? ?? 0;
      final newDepth = (currentDepth - 1).clamp(0, 99);
      final newMetadata = <String, dynamic>{
        ...node.metadata,
        'depth': newDepth,
      };
      context.document.replaceNodeById(
        node.id,
        node.copyAndReplaceMetadata(newMetadata),
      );
      executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
    }
  }
}

class _MoveSubtreeCommand extends EditCommand {
  _MoveSubtreeCommand({
    required this.nodeId,
    required this.newIndex,
  });

  final String nodeId;
  final int newIndex;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final oldIndex = document.getNodeIndexById(nodeId);
    if (oldIndex == -1) return;

    final parentNode = document.getNodeAt(oldIndex);
    if (parentNode == null) return;
    final parentDepth = getNodeDepth(parentNode);

    // Collect all contiguous descendants in document order
    final subtreeNodes = <DocumentNode>[parentNode];
    for (int i = oldIndex + 1; i < document.nodeCount; i++) {
      final candidate = document.getNodeAt(i);
      if (candidate == null) break;
      final depth = getNodeDepth(candidate);
      if (depth <= parentDepth) break;
      subtreeNodes.add(candidate);
    }

    // Remove subtree nodes from document
    for (final node in subtreeNodes) {
      document.deleteNode(node.id);
    }

    // Calculate insertion index
    int insertIndex = newIndex;
    if (newIndex > oldIndex) {
      insertIndex = newIndex - subtreeNodes.length + 1;
    }
    insertIndex = insertIndex.clamp(0, document.nodeCount);

    // Insert all subtree nodes at target index
    for (int i = 0; i < subtreeNodes.length; i++) {
      document.insertNodeAt(insertIndex + i, subtreeNodes[i]);
      executor.logChanges([
        DocumentEdit(
          NodeMovedEvent(
            nodeId: subtreeNodes[i].id,
            from: oldIndex + i,
            to: insertIndex + i,
          ),
        ),
      ]);
    }
  }
}

EditCommand? executeCommandRequestHandler(Editor editor, EditRequest request) {
  if (request is ExecuteCommandRequest) {
    return request.command;
  }
  return null;
}

class UpdateReminderCommand extends EditCommand {
  final String nodeId;
  final String title;
  final String dueAt;
  final bool completed;

  UpdateReminderCommand({
    required this.nodeId,
    required this.title,
    required this.dueAt,
    required this.completed,
  });

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(nodeId);
    if (node is! KetionReminderNode) return;

    document.replaceNodeById(
      node.id,
      KetionReminderNode(
        id: node.id,
        title: title,
        dueAt: dueAt,
        completed: completed,
      ),
    );
  }
}

SemanticMutation? _translateRequest(
  EditRequest request,
  EditorIdentityRegistry registry,
) {
  if (request is ConvertSlashCommandRequest) {
    return _translateRequest(request.innerRequest, registry);
  }

  if (request is ToggleExpandedRequest) {
    return ToggleBlockExpandedMutation(
      nodeId: request.nodeId,
      isExpanded: request.isExpanded,
    );
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
  if (request is SplitCalloutRequest) {
    return SplitBlockMutation(
      originalNodeId: request.nodeId,
      newNodeId: request.newNodeId,
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
  if (request is InsertReminderRequest) {
    return InsertBlockMutation(
      newNodeId: Editor.createNodeId(),
      insertAfterNodeId: request.nodeId,
    );
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
  if (request is ChangeParagraphMetadataRequest) {
    return ChangeBlockTypeMutation(nodeId: request.nodeId);
  }
  if (request is ConvertToCalloutRequest) {
    return ChangeBlockTypeMutation(nodeId: request.nodeId);
  }
  if (request is ConvertCalloutToParagraphRequest) {
    return ChangeBlockTypeMutation(nodeId: request.nodeId);
  }

  // --- Indent / Unindent requests ---
  if (request is IndentListItemRequest) {
    return IndentBlockMutation(nodeId: request.nodeId);
  }
  if (request is UnIndentListItemRequest) {
    return UnindentBlockMutation(nodeId: request.nodeId);
  }
  if (request is IndentTaskRequest) {
    return IndentBlockMutation(nodeId: request.nodeId);
  }
  if (request is UnIndentTaskRequest) {
    return UnindentBlockMutation(nodeId: request.nodeId);
  }
  if (request is IndentParagraphRequest) {
    return IndentBlockMutation(nodeId: request.nodeId);
  }
  if (request is UnIndentParagraphRequest) {
    return UnindentBlockMutation(nodeId: request.nodeId);
  }

  if (request is UpdateReminderRequest) {
    return UpdateReminderMutation(nodeId: request.nodeId);
  }

  if (request is UpdateTableRequest) {
    return UpdateTableMutation(nodeId: request.nodeId);
  }

  return null;
}

String? _validateIdentity(
  SemanticMutation mutation,
  EditorIdentityRegistry registry,
  EditorPersistenceSnapshot snapshot,
) {
  switch (mutation) {
    case SplitBlockMutation(:final originalNodeId):
      if (!registry.containsNode(originalNodeId)) {
        return 'Cannot split: no mapping for $originalNodeId';
      }
      return null;
    case MergeBlocksMutation(:final survivorNodeId, :final victimNodeId):
      if (!registry.containsNode(survivorNodeId)) {
        return 'Cannot merge: no mapping for $survivorNodeId';
      }
      if (!registry.containsNode(victimNodeId)) {
        return 'Cannot merge: no mapping for $victimNodeId';
      }
      return null;
    case DeleteBlockMutation(:final nodeId):
      if (!registry.containsNode(nodeId)) {
        return 'Cannot delete: no mapping for $nodeId';
      }
      return null;
    case InsertBlockMutation():
      return null;
    case MoveBlockMutation(:final nodeId):
      if (!registry.containsNode(nodeId)) {
        return 'Cannot move: no mapping for $nodeId';
      }
      return null;
    case ChangeBlockTypeMutation(:final nodeId):
      if (!registry.containsNode(nodeId)) {
        return 'Cannot change type: no mapping for $nodeId';
      }
      return null;
    case IndentBlockMutation(:final nodeId):
      if (!registry.containsNode(nodeId)) {
        return 'Cannot indent: no mapping for $nodeId';
      }
      final blockId = registry.blockIdForNode(nodeId);
      final block = blockId != null ? snapshot.getBlock(blockId) : null;
      if (block != null) {
        final targetSiblings = snapshot.activeBlocks
            .where((b) => b.parentBlockId == block.parentBlockId)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
        final targetIndex =
            targetSiblings.indexWhere((b) => b.blockId == blockId);
        if (targetIndex <= 0) {
          return 'Cannot indent: no preceding sibling to become parent';
        }
      }
      return null;
    case UnindentBlockMutation(:final nodeId):
      if (!registry.containsNode(nodeId)) {
        return 'Cannot unindent: no mapping for $nodeId';
      }
      final blockId = registry.blockIdForNode(nodeId);
      final block = blockId != null ? snapshot.getBlock(blockId) : null;
      if (block != null && block.parentBlockId == null) {
        return 'Cannot unindent: already at root level';
      }
      return null;
    case ToggleBlockExpandedMutation(:final nodeId):
      if (!registry.containsNode(nodeId)) {
        return 'Cannot toggle: no mapping for $nodeId';
      }
      return null;
    case UpdateReminderMutation(:final nodeId):
      if (!registry.containsNode(nodeId)) {
        return 'Cannot update reminder: no mapping for $nodeId';
      }
      return null;
    case UpdateTableMutation(:final nodeId):
      if (!registry.containsNode(nodeId)) {
        return 'Cannot update table: no mapping for $nodeId';
      }
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
  final void Function(String, KetionReminderNode)? onReminderInserted;

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
    this.onReminderInserted,
  });

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final originalCommand = _createOriginalCommand();
    if (originalCommand == null) {
      debugPrint(
        'KETION: Could not create original command for ${mutation.runtimeType}',
      );
      return;
    }

    final request = originalRequest;
    final isReconciling = registry.hasSnapshot;

    final Set<String> scopeNodeIds = {};
    if (!isReconciling) {
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
      } else if (mutation is IndentBlockMutation) {
        scopeNodeIds.add((mutation as IndentBlockMutation).nodeId);
      } else if (mutation is UnindentBlockMutation) {
        scopeNodeIds.add((mutation as UnindentBlockMutation).nodeId);
      } else if (mutation is ToggleBlockExpandedMutation) {
        scopeNodeIds.add((mutation as ToggleBlockExpandedMutation).nodeId);
      } else if (mutation is UpdateReminderMutation) {
        scopeNodeIds.add((mutation as UpdateReminderMutation).nodeId);
      } else if (mutation is UpdateTableMutation) {
        scopeNodeIds.add((mutation as UpdateTableMutation).nodeId);
      }

      if (scopeNodeIds.isNotEmpty) {
        for (final id in scopeNodeIds) {
          adapter.cancelPendingPersistence(id);
        }
        adapter.beginSemanticMutation(scopeNodeIds);
      }
    }

    try {
      if (request is ConvertSlashCommandRequest) {
        final reqToCreate = request.innerRequest;
        final handlesDeletion = reqToCreate is HandlesSlashDeletion;

        final node = document.getNodeById(request.target.nodeId);
        if (node is TextNode && !handlesDeletion) {
          final textLength = node.text.toPlainText().length;
          final safeStart = request.target.slashStartIndex.clamp(0, textLength);
          final safeEnd = request.target.slashEndIndex.clamp(0, textLength);

          if (safeEnd > safeStart) {
            final deleteCommand = DeleteContentCommand(
              documentRange: DocumentRange(
                start: DocumentPosition(
                  nodeId: request.target.nodeId,
                  nodePosition: TextNodePosition(offset: safeStart),
                ),
                end: DocumentPosition(
                  nodeId: request.target.nodeId,
                  nodePosition: TextNodePosition(offset: safeEnd),
                ),
              ),
            );
            executor.executeCommand(deleteCommand);
          }

          composer.setSelectionWithReason(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: request.target.nodeId,
                nodePosition: TextNodePosition(offset: safeStart),
              ),
            ),
          );
        }
      }

      executor.executeCommand(originalCommand);

      if (isReconciling) {
        return; // Skip persistence and side-effects during history replay
      }

      if (mutation is SplitBlockMutation) {
        final newNodeId = (mutation as SplitBlockMutation).newNodeId;
        if (!registry.containsNode(newNodeId)) {
          registry.registerPendingMapping(
            nodeId: newNodeId,
            blockId: const Uuid().v7(),
          );
        }
      } else if (mutation is InsertBlockMutation) {
        final newNodeId = (mutation as InsertBlockMutation).newNodeId;
        if (!registry.containsNode(newNodeId)) {
          registry.registerPendingMapping(
            nodeId: newNodeId,
            blockId: const Uuid().v7(),
          );
        }
      }

      if (request is SplitParagraphRequest) {
        composer.setSelectionWithReason(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: request.newNodeId,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      } else if (request is SplitCalloutRequest) {
        composer.setSelectionWithReason(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: request.newNodeId,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      } else if (request is SplitListItemRequest) {
        composer.setSelectionWithReason(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: request.newNodeId,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      } else if (request is SplitExistingTaskRequest) {
        final newNodeId = (mutation as SplitBlockMutation).newNodeId;
        composer.setSelectionWithReason(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: newNodeId,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      } else if (request is InsertNodeAtCaretRequest) {
        final newNode = request.node;
        if (newNode is TextNode) {
          composer.setSelectionWithReason(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: newNode.id,
                nodePosition:
                    TextNodePosition(offset: newNode.text.toPlainText().length),
              ),
            ),
          );
        } else {
          composer.setSelectionWithReason(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: newNode.id,
                nodePosition: const UpstreamDownstreamNodePosition.downstream(),
              ),
            ),
          );
        }
      }

      persistToKetionSynchronously(executor);

      if (request is InsertReminderRequest) {
        final newNodeId = (mutation as InsertBlockMutation).newNodeId;
        final node = document.getNodeById(newNodeId);
        if (node is KetionReminderNode) {
          onReminderInserted?.call(pageId, node);
        }
      }
    } finally {
      if (scopeNodeIds.isNotEmpty) {
        Future.microtask(() {
          adapter.endSemanticMutation(scopeNodeIds);
        });
      }
    }
  }

  EditCommand? _createOriginalCommand() {
    final reqToCreate = originalRequest is ConvertSlashCommandRequest
        ? (originalRequest as ConvertSlashCommandRequest).innerRequest
        : originalRequest;

    switch (mutation) {
      case SplitBlockMutation():
        if (reqToCreate is SplitParagraphRequest) {
          final req = reqToCreate;
          final targetNode = document.getNodeById(req.nodeId);
          if (targetNode is KetionCalloutNode) {
            return SplitCalloutCommand(
              SplitCalloutRequest(
                nodeId: req.nodeId,
                newNodeId: req.newNodeId,
                splitOffset: req.splitPosition.offset,
              ),
            );
          }
          return SplitParagraphCommand(
            nodeId: req.nodeId,
            splitPosition: req.splitPosition,
            newNodeId: req.newNodeId,
            replicateExistingMetadata: req.replicateExistingMetadata,
            attributionsToExtendToNewParagraph:
                req.attributionsToExtendToNewParagraph,
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
        if (reqToCreate is SplitCalloutRequest) {
          final req = reqToCreate;
          return SplitCalloutCommand(
            SplitCalloutRequest(
              nodeId: req.nodeId,
              newNodeId: req.newNodeId,
              splitOffset: req.splitOffset,
            ),
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
          return InsertNodeAtIndexCommand(
            nodeIndex: req.nodeIndex,
            newNode: req.newNode,
          );
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
        if (reqToCreate is InsertReminderRequest) {
          final req = reqToCreate;
          final newNodeId = (mutation as InsertBlockMutation).newNodeId;
          final dueAt = DateTime.now().add(const Duration(hours: 1));
          final node = KetionReminderNode(
            id: newNodeId,
            title: 'New Reminder',
            dueAt: dueAt.toIso8601String(),
          );
          return InsertNodeAfterNodeCommand(
            existingNodeId: req.nodeId,
            newNode: node,
          );
        }
        return null;

      case MoveBlockMutation():
        if (reqToCreate is MoveNodeRequest) {
          final req = reqToCreate;
          return _MoveSubtreeCommand(
            nodeId: req.nodeId,
            newIndex: req.newIndex,
          );
        }
        return null;

      case ChangeBlockTypeMutation():
        if (reqToCreate is ConvertParagraphToListItemRequest) {
          final req = reqToCreate;
          return ConvertParagraphToListItemCommand(
            nodeId: req.nodeId,
            type: req.type,
          );
        }
        if (reqToCreate is ConvertParagraphToTaskRequest) {
          final req = reqToCreate;
          return ConvertParagraphToTaskCommand(nodeId: req.nodeId);
        }
        if (reqToCreate is ChangeParagraphBlockTypeRequest) {
          final req = reqToCreate;
          return ChangeParagraphBlockTypeCommand(
            nodeId: req.nodeId,
            blockType: req.blockType,
          );
        }
        if (reqToCreate is ConvertListItemToParagraphRequest) {
          final req = reqToCreate;
          final node = document.getNodeById(req.nodeId);
          final metadata = <String, dynamic>{
            if (node != null) ...node.metadata,
            if (req.paragraphMetadata != null) ...req.paragraphMetadata!,
          };
          return ConvertListItemToParagraphCommand(
            nodeId: req.nodeId,
            paragraphMetadata: metadata,
          );
        }
        if (reqToCreate is ConvertTaskToParagraphRequest) {
          final req = reqToCreate;
          final node = document.getNodeById(req.nodeId);
          return ConvertTaskToParagraphCommand(
            nodeId: req.nodeId,
            paragraphMetadata:
                node != null ? Map<String, dynamic>.from(node.metadata) : null,
          );
        }
        if (reqToCreate is ChangeListItemTypeRequest) {
          final req = reqToCreate;
          return ChangeListItemTypeCommand(
            nodeId: req.nodeId,
            newType: req.newType,
          );
        }
        if (reqToCreate is ConvertToCalloutRequest) {
          final req = reqToCreate;
          int? startIndex;
          int? endIndex;
          if (originalRequest is ConvertSlashCommandRequest) {
            startIndex = (originalRequest as ConvertSlashCommandRequest)
                .target
                .slashStartIndex;
            endIndex = (originalRequest as ConvertSlashCommandRequest)
                .target
                .slashEndIndex;
          }
          return ConvertToCalloutCommand(
            ConvertToCalloutRequest(
              nodeId: req.nodeId,
              icon: req.icon,
              color: req.color,
              slashStartIndex: startIndex,
              slashEndIndex: endIndex,
            ),
          );
        }
        if (reqToCreate is ConvertCalloutToParagraphRequest) {
          final req = reqToCreate;
          return ConvertCalloutToParagraphCommand(
            ConvertCalloutToParagraphRequest(nodeId: req.nodeId),
          );
        }
        if (reqToCreate is ChangeParagraphMetadataRequest) {
          return ChangeParagraphMetadataCommand(reqToCreate);
        }
        return null;

      case IndentBlockMutation():
        final nodeId = (mutation as IndentBlockMutation).nodeId;
        return _KetionIndentNodeCommand(nodeId: nodeId);

      case UnindentBlockMutation():
        final nodeId = (mutation as UnindentBlockMutation).nodeId;
        return _KetionUnindentNodeCommand(nodeId: nodeId);

      case ToggleBlockExpandedMutation():
        if (reqToCreate is ToggleExpandedRequest) {
          final req = reqToCreate;
          final node = document.getNodeById(req.nodeId);
          if (node != null) {
            final blockId = registry.blockIdForNode(req.nodeId);
            if (blockId != null) {
              if (req.isExpanded) {
                adapter.restoreSubtree(blockId);
              } else {
                adapter.hideSubtree(blockId);
              }
            }
            return ChangeParagraphMetadataCommand(
              ChangeParagraphMetadataRequest(
                nodeId: req.nodeId,
                metadata: {
                  ...node.metadata,
                  'isExpanded': req.isExpanded,
                },
              ),
            );
          }
        }
        return null;

      case UpdateReminderMutation():
        if (reqToCreate is UpdateReminderRequest) {
          final req = reqToCreate;
          return UpdateReminderCommand(
            nodeId: req.nodeId,
            title: req.title,
            dueAt: req.dueAt,
            completed: req.completed,
          );
        }
        return null;

      case UpdateTableMutation():
        if (reqToCreate is UpdateTableRequest) {
          return reqToCreate.innerCommand;
        }
        return null;
    }
  }

  void persistToKetionSynchronously(CommandExecutor executor) {
    persistence_mutations.EditorPersistenceMutation? persistenceMutation;
    try {
      switch (mutation) {
        case SplitBlockMutation(:final originalNodeId, :final newNodeId):
          persistenceMutation = _buildSplitPayload(originalNodeId, newNodeId);
        case MergeBlocksMutation(:final survivorNodeId, :final victimNodeId):
          persistenceMutation =
              _buildMergePayload(survivorNodeId, victimNodeId);
        case DeleteBlockMutation(:final nodeId):
          persistenceMutation = _buildDeletePayload(nodeId);
        case InsertBlockMutation m:
          persistenceMutation = _buildInsertPayload(m);
        case MoveBlockMutation(:final nodeId):
          persistenceMutation = _buildMovePayload(nodeId);
        case ChangeBlockTypeMutation(:final nodeId):
          persistenceMutation = _buildChangeBlockTypePayload(nodeId);
        case IndentBlockMutation(:final nodeId):
          persistenceMutation = _buildIndentPayload(nodeId);
        case UnindentBlockMutation(:final nodeId):
          persistenceMutation = _buildUnindentPayload(nodeId);
        case ToggleBlockExpandedMutation(:final nodeId, :final isExpanded):
          persistenceMutation = _buildToggleExpandedPayload(nodeId, isExpanded);
        case UpdateReminderMutation(:final nodeId):
          persistenceMutation = _buildUpdateReminderPayload(nodeId);
        case UpdateTableMutation(:final nodeId):
          persistenceMutation = _buildUpdateTablePayload(nodeId);
      }
    } catch (e) {
      debugPrint(
        'KETION: Payload building failed for ${mutation.runtimeType}: $e',
      );
      return;
    }

    debugPrint(
      'KETION: In persistToKetionSynchronously for ${mutation.runtimeType}, payload=$persistenceMutation',
    );
    if (persistenceMutation == null) return;

    if (coordinator.enqueue(persistenceMutation)) {
      snapshot.applyMutation(persistenceMutation);

      if (mutation is IndentBlockMutation ||
          mutation is UnindentBlockMutation) {
        final nodeId = mutation is IndentBlockMutation
            ? (mutation as IndentBlockMutation).nodeId
            : (mutation as UnindentBlockMutation).nodeId;
        final node = document.getNodeById(nodeId);
        final blockId = registry.blockIdForNode(nodeId);
        if (node != null && blockId != null) {
          final block = snapshot.getBlock(blockId);
          final newDepth = _calculateDepth(block?.parentBlockId, snapshot);
          _updateDocumentNodeMetadata(node, newDepth, block);

          _updateDescendantDepths(blockId, newDepth, executor);

          executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);

          if (block?.parentBlockId != null) {
            final parentBlock = snapshot.getBlock(block!.parentBlockId!);
            if (parentBlock != null) {
              final parentNodeId = registry.nodeIdForBlock(parentBlock.blockId);
              final parentNode = parentNodeId != null
                  ? document.getNodeById(parentNodeId)
                  : null;
              final isToggle = parentBlock.type == 'toggle' ||
                  (parentNode != null &&
                      KetionToggleComponentBuilder.isToggleNode(parentNode));
              if (isToggle) {
                if (parentNode != null &&
                    parentNode.metadata['isExpanded'] == false) {
                  adapter.restoreSubtree(parentBlock.blockId);
                  parentNode.metadata['isExpanded'] = true;
                  executor.logChanges([
                    DocumentEdit(NodeChangeEvent(parentNode.id)),
                  ]);
                }
              }
            }
          }
        }
      } else if (mutation is SplitBlockMutation) {
        final newNodeId = (mutation as SplitBlockMutation).newNodeId;
        final node = document.getNodeById(newNodeId);
        final blockId = registry.blockIdForNode(newNodeId);
        if (node != null && blockId != null) {
          final block = snapshot.getBlock(blockId);
          final newDepth = _calculateDepth(block?.parentBlockId, snapshot);
          _updateDocumentNodeMetadata(node, newDepth, block);
          executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
        }
      } else if (mutation is InsertBlockMutation) {
        final newNodeId = (mutation as InsertBlockMutation).newNodeId;
        final node = document.getNodeById(newNodeId);
        final blockId = registry.blockIdForNode(newNodeId);
        if (node != null && blockId != null) {
          final block = snapshot.getBlock(blockId);
          final newDepth = _calculateDepth(block?.parentBlockId, snapshot);
          _updateDocumentNodeMetadata(node, newDepth, block);
          executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
        }
      } else if (mutation is MoveBlockMutation) {
        final nodeId = (mutation as MoveBlockMutation).nodeId;
        final node = document.getNodeById(nodeId);
        final blockId = registry.blockIdForNode(nodeId);
        if (node != null && blockId != null) {
          final block = snapshot.getBlock(blockId);
          final newDepth = _calculateDepth(block?.parentBlockId, snapshot);
          _updateDocumentNodeMetadata(node, newDepth, block);
          _updateDescendantDepths(blockId, newDepth, executor);
          executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
        }
      }
    } else {
      debugPrint(
        'KETION: Coordinator rejected mutation ${mutation.runtimeType}',
      );
    }
  }

  void _updateDocumentNodeMetadata(
    DocumentNode node,
    int newDepth,
    BlockSnapshot? block,
  ) {
    final newMetadata = <String, dynamic>{
      ...node.metadata,
      'depth': newDepth,
      if (block != null) 'blockId': block.blockId,
      if (block?.parentBlockId != null) 'parentBlockId': block!.parentBlockId,
      if (block != null) 'position': block.position,
    };
    if (block?.parentBlockId == null) {
      newMetadata.remove('parentBlockId');
    }

    if (node is ParagraphNode) {
      document.replaceNodeById(
        node.id,
        node.copyAndReplaceMetadata(newMetadata),
      );
    } else if (node is ListItemNode) {
      final replacement = node.type == ListItemType.ordered
          ? ListItemNode.ordered(
              id: node.id,
              text: node.text,
              indent: newDepth,
              metadata: newMetadata,
            )
          : ListItemNode.unordered(
              id: node.id,
              text: node.text,
              indent: newDepth,
              metadata: newMetadata,
            );
      document.replaceNodeById(node.id, replacement);
    } else if (node is TaskNode) {
      final replacement = TaskNode(
        id: node.id,
        text: node.text,
        isComplete: node.isComplete,
        indent: newDepth,
        metadata: newMetadata,
      );
      document.replaceNodeById(node.id, replacement);
    } else if (node is KetionTableNode) {
      document.replaceNodeById(
        node.id,
        node.copyAndReplaceMetadata(newMetadata),
      );
    } else {
      try {
        node.metadata['depth'] = newDepth;
        if (block?.parentBlockId != null) {
          node.metadata['parentBlockId'] = block!.parentBlockId;
        } else {
          node.metadata.remove('parentBlockId');
        }
      } catch (_) {}
    }
  }

  int _calculateDepth(
    String? parentBlockId,
    EditorPersistenceSnapshot snapshot,
  ) {
    int depth = 0;
    String? currentParentId = parentBlockId;
    final visited = <String>{};
    while (currentParentId != null && !visited.contains(currentParentId)) {
      visited.add(currentParentId);
      depth++;
      final parent = snapshot.getBlock(currentParentId);
      currentParentId = parent?.parentBlockId;
    }
    return depth;
  }

  void _updateDescendantDepths(
    String parentBlockId,
    int parentDepth,
    CommandExecutor executor, [
    Set<String>? visited,
  ]) {
    final seen = visited ?? <String>{};
    if (seen.contains(parentBlockId)) return;
    seen.add(parentBlockId);

    final children = snapshot.activeBlocks
        .where((b) => b.parentBlockId == parentBlockId)
        .toList();
    for (final child in children) {
      if (seen.contains(child.blockId)) continue;
      final childNodeId = registry.nodeIdForBlock(child.blockId);
      if (childNodeId != null) {
        final childNode = document.getNodeById(childNodeId);
        if (childNode != null) {
          final childDepth = parentDepth + 1;
          _updateDocumentNodeMetadata(childNode, childDepth, child);
          executor.logChanges([DocumentEdit(NodeChangeEvent(childNode.id))]);
          _updateDescendantDepths(child.blockId, childDepth, executor, seen);
        }
      }
    }
  }

  persistence_mutations.SplitBlockMutation? _buildSplitPayload(
    String originalNodeId,
    String newNodeId,
  ) {
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

    final rawParent = newNode.metadata['parentBlockId'] as String?;
    final origParent = originalNode.metadata['parentBlockId'] as String?;
    final rawFallback = origParent != null
        ? (registry.blockIdForNode(origParent) ?? origParent)
        : null;
    final providedParentBlockId = rawParent != null
        ? (registry.blockIdForNode(rawParent) ?? rawParent)
        : rawFallback;

    return StructuralMutationBuilder.buildSplitMutation(
      pageId: pageId,
      originalBlockId: originalBlockId,
      originalData: originalData,
      newBlockId: newBlockId,
      newData: newData,
      newType: newType,
      snapshot: snapshot,
      providedParentBlockId: providedParentBlockId,
    );
  }

  persistence_mutations.MergeBlocksMutation? _buildMergePayload(
    String survivorNodeId,
    String victimNodeId,
  ) {
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

  persistence_mutations.DeleteBlockMutation? _buildDeletePayload(
    String nodeId,
  ) {
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

  persistence_mutations.InsertBlockMutation? _buildInsertPayload(
    InsertBlockMutation mutation,
  ) {
    final newNodeId = mutation.newNodeId;
    final node = document.getNodeById(newNodeId);
    if (node == null) return null;

    final newBlockId = registry.blockIdForNode(newNodeId)!;
    final data = BlockDataSerializer.encodeDocumentNode(node);
    final type = BlockDataSerializer.blockTypeFor(node);

    final previousNodeId = document.getNodeBeforeById(newNodeId)?.id;
    final nextNodeId = document.getNodeAfterById(newNodeId)?.id;

    final previousBlockId =
        previousNodeId != null ? registry.blockIdForNode(previousNodeId) : null;
    final nextBlockId =
        nextNodeId != null ? registry.blockIdForNode(nextNodeId) : null;

    final rawParent = node.metadata['parentBlockId'] as String?;
    final providedParentBlockId = rawParent != null
        ? (registry.blockIdForNode(rawParent) ?? rawParent)
        : null;

    final previousNode =
        previousNodeId != null ? document.getNodeById(previousNodeId) : null;

    final previousMetadata =
        previousNode?.metadata ?? const <String, dynamic>{};

    final previousBlockIsToggle = previousMetadata['listType'] == 'toggle' ||
        previousMetadata['type'] == 'toggle' ||
        (previousMetadata['blockType'] is NamedAttribution &&
            (previousMetadata['blockType'] as NamedAttribution).name ==
                'toggle');

    return StructuralMutationBuilder.buildInsertMutation(
      pageId: pageId,
      blockId: newBlockId,
      data: data,
      type: type,
      previousBlockId: previousBlockId,
      nextBlockId: nextBlockId,
      providedParentBlockId: providedParentBlockId,
      snapshot: snapshot,
      previousBlockIsToggle: previousBlockIsToggle,
    );
  }

  persistence_mutations.MoveBlockMutation? _buildMovePayload(String nodeId) {
    final blockId = registry.blockIdForNode(nodeId);
    if (blockId == null) return null;

    final previousNode = document.getNodeBeforeById(nodeId);
    final nextNode = document.getNodeAfterById(nodeId);

    final previousBlockId =
        previousNode != null ? registry.blockIdForNode(previousNode.id) : null;
    final nextBlockId =
        nextNode != null ? registry.blockIdForNode(nextNode.id) : null;

    return StructuralMutationBuilder.buildMoveMutation(
      pageId: pageId,
      blockId: blockId,
      previousBlockId: previousBlockId,
      nextBlockId: nextBlockId,
      snapshot: snapshot,
    );
  }

  persistence_mutations.ChangeBlockTypeMutation? _buildChangeBlockTypePayload(
    String nodeId,
  ) {
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

  persistence_mutations.MoveBlockMutation? _buildIndentPayload(String nodeId) {
    final blockId = registry.blockIdForNode(nodeId);
    if (blockId == null) return null;

    final node = document.getNodeById(nodeId);
    if (node == null) return null;

    return StructuralMutationBuilder.buildIndentMutation(
      pageId: pageId,
      blockId: blockId,
      snapshot: snapshot,
    );
  }

  persistence_mutations.MoveBlockMutation? _buildUnindentPayload(
    String nodeId,
  ) {
    final blockId = registry.blockIdForNode(nodeId);
    if (blockId == null) return null;

    final node = document.getNodeById(nodeId);
    if (node == null) return null;

    final documentBlockOrder = document
        .map((n) => registry.blockIdForNode(n.id))
        .whereType<String>()
        .toList();

    return StructuralMutationBuilder.buildUnindentMutation(
      pageId: pageId,
      blockId: blockId,
      snapshot: snapshot,
      documentBlockOrder: documentBlockOrder,
    );
  }

  persistence_mutations.UpdateToggleMutation? _buildToggleExpandedPayload(
    String nodeId,
    bool isExpanded,
  ) {
    final blockId = registry.blockIdForNode(nodeId)!;

    final node = document.getNodeById(nodeId);
    if (node == null) {
      throw StateError('ToggleExpanded produced unexpected document state');
    }

    final data = BlockDataSerializer.encodeDocumentNode(node);
    final type = BlockDataSerializer.blockTypeFor(node);

    return persistence_mutations.UpdateToggleMutation(
      pageId: pageId,
      blockId: blockId,
      data: data,
      type: type,
      parentBlockId: node.metadata['parentBlockId'] as String? ??
          snapshot.getBlock(blockId)?.parentBlockId,
      position: (node.metadata['position'] as num?)?.toDouble() ??
          snapshot.getBlock(blockId)?.position ??
          0.0,
      expectedVersion: registry.getBlockVersion(blockId),
      blockCreatedAt:
          registry.getBlockCreatedAt(blockId) ?? DateTime.now().toUtc(),
      createdAt: DateTime.now().toUtc(),
      isExpanded: isExpanded,
      contentHash: EditorIdentityRegistry.hashContent(data),
    );
  }

  persistence_mutations.UpdateBlockMutation? _buildUpdateReminderPayload(
    String nodeId,
  ) {
    final blockId = registry.blockIdForNode(nodeId)!;

    final node = document.getNodeById(nodeId);
    if (node == null) {
      throw StateError('UpdateReminder produced unexpected document state');
    }

    final data = BlockDataSerializer.encodeDocumentNode(node);
    final type = BlockDataSerializer.blockTypeFor(node);

    return persistence_mutations.UpdateBlockMutation(
      pageId: pageId,
      blockId: blockId,
      data: data,
      type: type,
      parentBlockId: node.metadata['parentBlockId'] as String? ??
          snapshot.getBlock(blockId)?.parentBlockId,
      position: (node.metadata['position'] as num?)?.toDouble() ??
          snapshot.getBlock(blockId)?.position ??
          0.0,
      expectedVersion: registry.getBlockVersion(blockId),
      blockCreatedAt:
          registry.getBlockCreatedAt(blockId) ?? DateTime.now().toUtc(),
      createdAt: DateTime.now().toUtc(),
      contentHash: EditorIdentityRegistry.hashContent(data),
    );
  }

  persistence_mutations.UpdateBlockMutation? _buildUpdateTablePayload(
    String nodeId,
  ) {
    final blockId = registry.blockIdForNode(nodeId)!;

    final node = document.getNodeById(nodeId);
    if (node == null) {
      throw StateError('UpdateTable produced unexpected document state');
    }

    // Validation to prevent persistence of malformed tables
    final tableNode = node as KetionTableNode;
    final columnCount = tableNode.columnCount;
    final rowsList = tableNode.rows;
    if (columnCount < 1) {
      throw StateError('Table has invalid columnCount: $columnCount');
    }
    if (rowsList.isEmpty) {
      throw StateError('Table has no rows');
    }
    for (int i = 0; i < rowsList.length; i++) {
      final row = rowsList[i];
      final cells = row.cells;
      if (cells.length != columnCount) {
        throw StateError(
          'Table row $i has ${cells.length} cells, expected $columnCount',
        );
      }
      for (int j = 0; j < cells.length; j++) {
        final cell = cells[j];
        if (cell.id.isEmpty) {
          throw StateError('Table cell at $i,$j has no ID');
        }
      }
    }

    final data = BlockDataSerializer.encodeDocumentNode(node);
    final type = BlockDataSerializer.blockTypeFor(node);

    return persistence_mutations.UpdateBlockMutation(
      pageId: pageId,
      blockId: blockId,
      data: data,
      type: type,
      parentBlockId: node.metadata['parentBlockId'] as String? ??
          snapshot.getBlock(blockId)?.parentBlockId,
      position: (node.metadata['position'] as num?)?.toDouble() ??
          snapshot.getBlock(blockId)?.position ??
          0.0,
      expectedVersion: registry.getBlockVersion(blockId),
      blockCreatedAt:
          registry.getBlockCreatedAt(blockId) ?? DateTime.now().toUtc(),
      createdAt: DateTime.now().toUtc(),
      contentHash: EditorIdentityRegistry.hashContent(data),
    );
  }
}
