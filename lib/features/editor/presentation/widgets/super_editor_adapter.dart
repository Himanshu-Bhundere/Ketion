import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:super_editor/super_editor.dart';
import 'package:uuid/uuid.dart';

import '../../../blocks/domain/entities/block.dart';
import '../../domain/models/media_nodes.dart';
import '../table/ketion_table_node.dart';
import 'ketion_callout_node.dart';
import '../../domain/services/attribution_converter.dart';
import '../../domain/services/block_tree_service.dart';
import '../../domain/services/block_data_serializer.dart';
import '../../services/editor_persistence_coordinator.dart';
import '../../services/editor_persistence_mutations.dart'
    as persistence_mutations;
import '../../services/editor_persistence_snapshot.dart';
import '../../services/structural_mutation_builder.dart';
import 'editor_identity_registry.dart';

class KetionSuperEditorAdapter {
  final String pageId;
  late final MutableDocument document;
  late final Editor editor;
  final EditorPersistenceCoordinator coordinator;
  final EditorPersistenceSnapshot snapshot;

  bool _isSyncingFromKetion = false;
  final EditorIdentityRegistry _registry = EditorIdentityRegistry();
  final Set<String> _pendingNodeIds = {};
  final Set<String> _pendingInsertNodeIds = {};
  Future<void>? _activeFlush;

  /// Node IDs currently being transformed by a semantic structural mutation
  /// (e.g., ChangeBlockTypeMutation from slash conversion). While a semantic
  /// mutation scope is active for a node, ALL document events for that node
  /// are suppressed — the semantic handler owns persistence exclusively.
  ///
  /// Scoped: set via [beginSemanticMutation] before the SE command executes,
  /// cleared via [endSemanticMutation] immediately after the command completes.
  final Set<String> _activeSemanticMutationNodeIds = {};

  /// Cache of nodes that are temporarily removed from the document because
  /// their ancestor toggle is collapsed. Map from toggle blockId -> list of nodes.
  final Map<String, List<DocumentNode>> _hiddenNodeCache = {};

  /// Exposes the identity registry for use by [KetionEditRequestHandler]
  /// and [KetionEditListener].
  EditorIdentityRegistry get registry => _registry;

  StreamSubscription<persistence_mutations.EditorPersistenceMutation>?
      _mutationSuccessSubscription;

  KetionSuperEditorAdapter({
    required this.pageId,
    required this.coordinator,
    required this.snapshot,
  }) {
    _mutationSuccessSubscription =
        coordinator.onMutationSuccess.listen(_onMutationSuccess);
  }

  void _onMutationSuccess(
    persistence_mutations.EditorPersistenceMutation mutation,
  ) {
    for (final transition in mutation.versionTransitions) {
      if (transition.operation ==
          persistence_mutations.VersionChangeOperation.increment) {
        final current = _registry.getBlockVersion(transition.blockId);
        _registry.setBlockVersion(transition.blockId, current + 1);
      } else if (transition.operation ==
          persistence_mutations.VersionChangeOperation.create) {
        _registry.promotePendingMapping(transition.blockId);
        _registry.setBlockVersion(transition.blockId, 1);
      } else if (transition.operation ==
          persistence_mutations.VersionChangeOperation.softDelete) {
        final current = _registry.getBlockVersion(transition.blockId);
        _registry.markDeleted(transition.blockId, current + 1);
      }
    }

    if (mutation is persistence_mutations.UpdateToggleMutation) {
      final nodeId = _registry.nodeIdForBlock(mutation.blockId);
      if (nodeId != null) {
        if (mutation.isExpanded) {
          restoreSubtree(mutation.blockId);
        } else {
          hideSubtree(mutation.blockId);
        }
      }
    } else if (mutation is persistence_mutations.UpdateBlockMutation) {
      final nodeId = _registry.nodeIdForBlock(mutation.blockId);
      if (nodeId != null) {
        final node = document.getNodeById(nodeId);
        if (node is TextNode) {
          final currentHash =
              EditorIdentityRegistry.hashContent(_buildDataFromNode(node));
          if (currentHash == mutation.contentHash) {
            _registry.setContentHash(nodeId, currentHash);
            _pendingNodeIds.remove(nodeId);
          }
        }
      }
    }
  }

  MutableDocument createDocument(List<Block> blocks) {
    _isSyncingFromKetion = true;
    try {
      final projectedBlocks =
          BlockTreeService.buildFullTreeWithVisibility(blocks);

      final nodes = <DocumentNode>[];

      for (final pb in projectedBlocks) {
        final block = pb.block;
        final node = _convertKetionBlockToNode(block, pb.depth);
        if (node != null) {
          _registry.registerMapping(nodeId: node.id, blockId: block.id);
          _registry.setBlockVersion(block.id, block.version);
          _registry.setBlockCreatedAt(block.id, block.createdAt);
          if (node is TextNode) {
            _registry.setContentHash(
              node.id,
              EditorIdentityRegistry.hashContent(_buildDataFromNode(node)),
            );
          }

          if (pb.hiddenByAncestorId == null) {
            nodes.add(node);
          } else {
            _hiddenNodeCache
                .putIfAbsent(pb.hiddenByAncestorId!, () => [])
                .add(node);
          }
        }
      }

      if (nodes.isEmpty) {
        final node =
            ParagraphNode(id: Editor.createNodeId(), text: AttributedText());
        nodes.add(node);
      }

      return MutableDocument(nodes: nodes);
    } finally {
      _isSyncingFromKetion = false;
    }
  }

  void bind(MutableDocument doc, Editor ed) {
    document = doc;
    editor = ed;
    document.addListener(_onDocumentChange);
  }

  void dispose() {
    _debounceTimer?.cancel();
    document.removeListener(_onDocumentChange);
    _mutationSuccessSubscription?.cancel();
  }

  MutableDocumentComposer? get _safeComposer {
    try {
      return editor.context.find<MutableDocumentComposer>(Editor.composerKey);
    } catch (_) {
      return null;
    }
  }

  void hideSubtree(String toggleBlockId) {
    String? toggleNodeId = _registry.nodeIdForBlock(toggleBlockId);
    if (toggleNodeId == null) {
      for (final n in document) {
        if (n.metadata['blockId'] == toggleBlockId || n.id == toggleBlockId) {
          toggleNodeId = n.id;
          break;
        }
      }
    }
    if (toggleNodeId == null) return;

    int toggleIndex = document.getNodeIndexById(toggleNodeId);
    if (toggleIndex == -1) return;

    final toggleNode = document.getNodeAt(toggleIndex);
    final toggleDepth = toggleNode?.metadata['depth'] as int? ??
        (toggleNode is ListItemNode
            ? toggleNode.indent
            : (toggleNode is TaskNode ? toggleNode.indent : 0));

    bool isDescendantOfToggle(DocumentNode node) {
      final visitedParentIds = <String>{};
      String? parentId = node.metadata['parentBlockId'] as String?;

      while (parentId != null && parentId.isNotEmpty) {
        if (parentId == toggleBlockId || parentId == toggleNodeId) return true;
        if (!visitedParentIds.add(parentId)) return false;

        final parentNodeId = _registry.nodeIdForBlock(parentId);
        DocumentNode? parentNode =
            parentNodeId != null ? document.getNodeById(parentNodeId) : null;
        if (parentNode == null) {
          for (final n in document) {
            if (n.metadata['blockId'] == parentId || n.id == parentId) {
              parentNode = n;
              break;
            }
          }
        }

        parentId = parentNode?.metadata['parentBlockId'] as String?;
      }

      return false;
    }

    final descendants = <DocumentNode>[];

    for (int i = toggleIndex + 1; i < document.nodeCount; i++) {
      final node = document.getNodeAt(i);
      if (node == null) continue;

      // Prefer persisted hierarchy whenever available.
      final hasParentMetadata = node.metadata['parentBlockId'] is String &&
          (node.metadata['parentBlockId'] as String).isNotEmpty;

      if (hasParentMetadata) {
        if (isDescendantOfToggle(node)) {
          descendants.add(node);
          continue;
        }

        // We reached a node outside this toggle subtree.
        final depth = node.metadata['depth'] as int? ??
            (node is ListItemNode
                ? node.indent
                : (node is TaskNode ? node.indent : 0));

        if (depth <= toggleDepth) break;

        // A node with parent metadata that is not in this subtree must not
        // be hidden just because its depth is larger.
        continue;
      }

      // Legacy fallback: only use depth when no parent metadata exists.
      final depth = node.metadata['depth'] as int? ??
          (node is ListItemNode
              ? node.indent
              : (node is TaskNode ? node.indent : 0));

      if (depth <= toggleDepth) break;
      descendants.add(node);
    }

    if (descendants.isEmpty) return;

    final descendantIds = descendants.map((n) => n.id).toSet();
    final composer = _safeComposer;
    final selectionBefore = composer?.selection;

    debugPrint(
      '[KETION_TOGGLE_DIAG] hideSubtree: toggleBlockId=$toggleBlockId, toggleNodeId=$toggleNodeId, '
      'descendantsBeforeCollapse=$descendantIds, selectionBeforeCollapse=$selectionBefore',
    );

    // Clear or relocate selection before deleting descendants if selection is on a hidden node
    if (selectionBefore != null) {
      final baseInDescendants =
          descendantIds.contains(selectionBefore.base.nodeId);
      final extentInDescendants =
          descendantIds.contains(selectionBefore.extent.nodeId);
      final selectionRemainsOnHidden = baseInDescendants || extentInDescendants;
      debugPrint(
        '[KETION_TOGGLE_DIAG] hideSubtree: whetherSelectionRemainsOnHiddenNode=$selectionRemainsOnHidden',
      );
      if (selectionRemainsOnHidden) {
        debugPrint(
          '[KETION_TOGGLE_DIAG] Relocating selection to toggle header before hiding descendants',
        );
        final newSel = DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: toggleNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        );
        try {
          editor.execute([
            ChangeSelectionRequest(
              newSel,
              SelectionChangeType.placeCaret,
              SelectionReason.userInteraction,
            ),
          ]);
        } catch (_) {
          composer?.setSelectionWithReason(
            newSel,
            SelectionReason.userInteraction,
          );
        }
      }
    }

    _hiddenNodeCache[toggleBlockId] = List.from(descendants);

    beginSemanticMutation(descendantIds);
    for (final node in descendants.reversed) {
      document.deleteNode(node.id);
    }
    endSemanticMutation(descendantIds);

    debugPrint(
      '[KETION_TOGGLE_DIAG] hideSubtree complete: toggleBlockId=$toggleBlockId, selectionAfterCollapse=${_safeComposer?.selection}',
    );
  }

  void restoreSubtree(String toggleBlockId) {
    String? toggleNodeId = _registry.nodeIdForBlock(toggleBlockId);
    if (toggleNodeId == null) {
      for (final n in document) {
        if (n.metadata['blockId'] == toggleBlockId || n.id == toggleBlockId) {
          toggleNodeId = n.id;
          break;
        }
      }
    }
    if (toggleNodeId == null) return;

    int toggleIndex = document.getNodeIndexById(toggleNodeId);
    if (toggleIndex == -1) return;

    final cachedNodes = _hiddenNodeCache.remove(toggleBlockId);
    final composer = _safeComposer;
    final selectionBefore = composer?.selection;

    debugPrint(
      '[KETION_TOGGLE_DIAG] restoreSubtree START: toggleBlockId=$toggleBlockId, toggleNodeId=$toggleNodeId, '
      'cachedNodesCount=${cachedNodes?.length}, selectionBeforeExpansion=$selectionBefore',
    );

    if (cachedNodes != null && cachedNodes.isNotEmpty) {
      final existingNodeIds = document.map((n) => n.id).toSet();
      final duplicatedNodeIds =
          cachedNodes.map((n) => n.id).where(existingNodeIds.contains).toList();
      debugPrint(
        '[KETION_TOGGLE_DIAG] restoreSubtree: whetherRestoredNodesAreDuplicated=${duplicatedNodeIds.isNotEmpty} '
        '(duplicates: $duplicatedNodeIds)',
      );

      final nodeIds = cachedNodes.map((n) => n.id).toSet();
      beginSemanticMutation(nodeIds);

      int insertIndex = toggleIndex + 1;
      final restoredNodeIds = <String>[];
      for (final node in cachedNodes) {
        if (!existingNodeIds.contains(node.id)) {
          document.insertNodeAt(insertIndex, node);
          restoredNodeIds.add(node.id);
          insertIndex++;
        }
      }

      endSemanticMutation(nodeIds);

      final selectionAfter = _safeComposer?.selection;
      debugPrint(
        '[KETION_TOGGLE_DIAG] restoreSubtree complete: toggleBlockId=$toggleBlockId, '
        'descendantIdsAfterRestoration=$restoredNodeIds, selectionAfterExpansion=$selectionAfter',
      );

      // If selection refers to an invalid node, restore a valid selection
      if (selectionAfter != null &&
          document.getNodeById(selectionAfter.extent.nodeId) == null) {
        debugPrint(
          '[KETION_TOGGLE_DIAG] Stale selection detected after expansion. Restoring valid selection to toggle header.',
        );
        final newSel = DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: toggleNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        );
        try {
          editor.execute([
            ChangeSelectionRequest(
              newSel,
              SelectionChangeType.placeCaret,
              SelectionReason.userInteraction,
            ),
          ]);
        } catch (_) {
          _safeComposer?.setSelectionWithReason(
            newSel,
            SelectionReason.userInteraction,
          );
        }
      }
    }
  }

  void invalidateSubtree(String toggleBlockId) {
    _hiddenNodeCache.remove(toggleBlockId);
  }

  void invalidateNode(String nodeId) {
    for (final list in _hiddenNodeCache.values) {
      list.removeWhere((n) => n.id == nodeId);
    }
  }

  DocumentNode? _convertKetionBlockToNode(Block block, int depth) {
    try {
      final data = jsonDecode(block.data) as Map<String, dynamic>;
      final spans = data['spans'] as List<dynamic>? ?? [];

      final attributedText = AttributionConverter.fromKetionSpans(spans);

      final nodeId = Editor.createNodeId();
      final metadata = <String, dynamic>{};
      metadata['blockId'] = block.id;
      if (block.parentBlockId != null) {
        metadata['parentBlockId'] = block.parentBlockId;
      }
      metadata['depth'] = depth;
      metadata['position'] = block.position;

      final isToggle = block.type == 'toggle' ||
          data['listType'] == 'toggle' ||
          data['blockType'] == 'toggle' ||
          data['type'] == 'toggle';
      if (isToggle) {
        metadata['blockType'] = const NamedAttribution('toggle');
        metadata['listType'] = 'toggle';
        metadata['type'] = 'toggle';
        metadata['isExpanded'] = data['isExpanded'] as bool? ?? false;
        debugPrint(
          '[KETION_TOGGLE_DIAG] SQLite reload -> Toggle node reconstructed: blockId=${block.id}, nodeId=$nodeId, parentBlockId=${block.parentBlockId}, depth=$depth, isExpanded=${metadata['isExpanded']}',
        );
        return ParagraphNode(
          id: nodeId,
          text: attributedText,
          metadata: metadata,
        );
      }

      switch (block.type) {
        case 'text':
          final headingLevel = data['headingLevel'] as int? ?? 0;
          final isQuote = data['quote'] as bool? ?? false;
          if (headingLevel > 0 && headingLevel <= 3) {
            final type = [
              header1Attribution,
              header2Attribution,
              header3Attribution,
            ][headingLevel - 1];
            metadata['blockType'] = type;
            return ParagraphNode(
              id: nodeId,
              text: attributedText,
              metadata: metadata,
            );
          } else if (isQuote) {
            metadata['blockType'] = blockquoteAttribution;
            return ParagraphNode(
              id: nodeId,
              text: attributedText,
              metadata: metadata,
            );
          }
          return ParagraphNode(
            id: nodeId,
            text: attributedText,
            metadata: metadata.isNotEmpty ? metadata : null,
          );

        case 'callout':
          final icon = data['icon'] as String? ?? '💡';
          final color = data['color'] as String? ?? 'grey';
          return KetionCalloutNode(
            id: nodeId,
            text: attributedText,
            metadata: metadata,
            icon: icon,
            color: color,
          );

        case 'list':
          final listType = data['listType'] as String? ?? 'bullet';
          if (listType == 'numbered') {
            return ListItemNode.ordered(
              id: nodeId,
              text: attributedText,
              indent: depth,
              metadata: metadata.isNotEmpty ? metadata : null,
            );
          } else if (listType == 'checklist') {
            return TaskNode(
              id: nodeId,
              text: attributedText,
              isComplete: data['checked'] as bool? ?? false,
              indent: depth,
              metadata: metadata.isNotEmpty ? metadata : null,
            );
          } else if (listType == 'toggle') {
            metadata['blockType'] = const NamedAttribution('toggle');
            metadata['listType'] = 'toggle';
            metadata['isExpanded'] = data['isExpanded'] as bool? ?? false;
            return ParagraphNode(
              id: nodeId,
              text: attributedText,
              metadata: metadata,
            );
          } else {
            return ListItemNode.unordered(
              id: nodeId,
              text: attributedText,
              indent: depth,
              metadata: metadata.isNotEmpty ? metadata : null,
            );
          }

        case 'toggle':
          metadata['blockType'] = const NamedAttribution('toggle');
          metadata['listType'] = 'toggle';
          metadata['isExpanded'] = data['isExpanded'] as bool? ?? false;
          return ParagraphNode(
            id: nodeId,
            text: attributedText,
            metadata: metadata,
          );

        case 'code':
          final codeText = data['code'] as String? ?? '';
          metadata['blockType'] = codeAttribution;
          metadata['language'] = data['language'] as String? ?? 'plaintext';
          metadata['showLineNumbers'] =
              data['showLineNumbers'] as bool? ?? false;
          metadata['wrapLines'] = data['wrapLines'] as bool? ?? true;
          return ParagraphNode(
            id: nodeId,
            text: AttributedText(codeText),
            metadata: metadata,
          );

        case 'image':
          final attachmentId = data['attachmentId'] as String? ?? '';
          return ImageNode(
            id: nodeId,
            imageUrl: attachmentId,
            metadata: metadata.isNotEmpty ? metadata : null,
          );

        case 'video':
          final attachmentId = data['attachmentId'] as String? ?? '';
          return KetionVideoNode(
            id: nodeId,
            attachmentId: attachmentId,
            metadata: metadata,
          );

        case 'audio':
          final attachmentId = data['attachmentId'] as String? ?? '';
          return KetionAudioNode(
            id: nodeId,
            attachmentId: attachmentId,
            metadata: metadata,
          );

        case 'pdf':
          final attachmentId = data['attachmentId'] as String? ?? '';
          return KetionPdfNode(
            id: nodeId,
            attachmentId: attachmentId,
            metadata: metadata,
          );

        case 'file':
          final attachmentId = data['attachmentId'] as String? ?? '';
          return KetionFileNode(
            id: nodeId,
            attachmentId: attachmentId,
            metadata: metadata,
          );

        case 'bookmark':
          final url = data['url'] as String? ?? '';
          return KetionBookmarkNode(id: nodeId, url: url, metadata: metadata);

        case 'table':
          metadata['columnCount'] = data['columnCount'] as int? ?? 0;
          metadata['rows'] = data['rows'] as List<dynamic>? ?? [];
          return KetionTableNode(id: nodeId, metadata: metadata);

        case 'pageLink':
          final pageId = data['pageId'] as String? ?? '';
          return KetionPageLinkNode(
            id: nodeId,
            pageId: pageId,
            metadata: metadata,
          );

        case 'webLink':
          final url = data['url'] as String? ?? '';
          return KetionWebLinkNode(id: nodeId, url: url, metadata: metadata);

        case 'reminder':
          final title = data['title'] as String? ?? '';
          final dueAt = data['dueAt'] as String? ?? '';
          final timezone = data['timezone'] as String? ?? 'UTC';
          final recurrenceRule = data['recurrenceRule'] as String?;
          final completed = data['completed'] as bool? ?? false;
          return KetionReminderNode(
            id: nodeId,
            title: title,
            dueAt: dueAt,
            timezone: timezone,
            recurrenceRule: recurrenceRule,
            completed: completed,
            metadata: metadata,
          );

        case 'divider':
          return HorizontalRuleNode(
            id: nodeId,
            metadata: metadata.isNotEmpty ? metadata : null,
          );

        default:
          return ParagraphNode(
            id: nodeId,
            text: attributedText,
            metadata: metadata.isNotEmpty ? metadata : null,
          );
      }
    } catch (e) {
      return null;
    }
  }

  Timer? _debounceTimer;

  /// Registers a node as being within a semantic structural mutation scope.
  ///
  /// Called by [KetionEditRequestHandler] BEFORE executing the SE command.
  /// While active, all document events for this node are suppressed — the
  /// semantic handler owns persistence exclusively for this operation.
  ///
  /// IMPORTANT: This suppression exists only to prevent duplicate persistence
  /// of events already owned by the semantic handler. It does NOT determine
  /// whether a block is structurally new — the semantic request handler
  /// remains the authoritative source for structural mutations.
  void beginSemanticMutation(Set<String> nodeIds) {
    debugPrint(
      'KETION: beginSemanticMutation for $nodeIds\n${StackTrace.current}',
    );
    _activeSemanticMutationNodeIds.addAll(nodeIds);
  }

  /// Ends the semantic mutation scope for a node.
  ///
  /// Called by [KetionEditRequestHandler] AFTER the SE command completes.
  /// Any unconsumed suppression is cleaned up, and subsequent independent
  /// user edits for this node will flow through normally.
  void endSemanticMutation(Set<String> nodeIds) {
    debugPrint('KETION: endSemanticMutation for $nodeIds');
    _activeSemanticMutationNodeIds.removeAll(nodeIds);
  }

  /// Handles Document change notifications.
  ///
  /// **Phase 3 design**:
  /// - Structural changes (NodeInserted, NodeRemoved, NodeMoved) are handled by
  ///   `KetionEditRequestHandler` at the `EditRequest` level (semantic interception).
  /// - Undo/redo is handled by `KetionEditListener` via pre-history snapshot diffing.
  /// - This listener processes `NodeChangeEvent` for content updates (text, formatting)
  ///   and `NodeInsertedEvent` for node replacements — BUT only when the event is NOT
  ///   already owned by a semantic structural mutation.
  @visibleForTesting
  void onDocumentChangeForTesting(DocumentChangeLog log) {
    _onDocumentChange(log);
  }

  void _onDocumentChange(DocumentChangeLog log) {
    if (_isSyncingFromKetion) return;

    for (final change in log.changes) {
      debugPrint(
        'KETION: _onDocumentChange change type: ${change.runtimeType}',
      );
      if (change is NodeChangeEvent) {
        if (_activeSemanticMutationNodeIds.contains(change.nodeId)) {
          debugPrint('KETION: Suppressed NodeChangeEvent for ${change.nodeId}');
          continue;
        }

        final node = document.getNodeById(change.nodeId);
        if (node is KetionTableNode) {
          debugPrint(
            'KETION: Discarded generic NodeChangeEvent for KetionTableNode (must use semantic handler)',
          );
          continue;
        }

        debugPrint('KETION: Unsuppressed NodeChangeEvent for ${change.nodeId}');
        _pendingNodeIds.add(change.nodeId);
      } else if (change is NodeInsertedEvent) {
        if (_activeSemanticMutationNodeIds.contains(change.nodeId)) {
          debugPrint(
            'KETION: Suppressed NodeInsertedEvent for ${change.nodeId}',
          );
          continue;
        }
        debugPrint(
          'KETION: Unsuppressed NodeInsertedEvent for ${change.nodeId}',
        );

        // Allocate identity if it's missing
        if (_registry.blockIdForNode(change.nodeId) == null) {
          final newBlockId = const Uuid().v7();
          _registry.registerPendingMapping(
            nodeId: change.nodeId,
            blockId: newBlockId,
          );
        }

        _pendingInsertNodeIds.add(change.nodeId);
      }
    }

    if (_pendingNodeIds.isNotEmpty || _pendingInsertNodeIds.isNotEmpty) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        flushPendingChanges();
      });
    }
  }

  Future<void> flushPendingChanges() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (_activeFlush != null) {
      return _activeFlush!.then((_) => flushPendingChanges());
    }
    _activeFlush =
        _flushPendingChangesInternal().whenComplete(() => _activeFlush = null);
    return _activeFlush!;
  }

  void cancelPendingPersistence(String nodeId) {
    _pendingNodeIds.remove(nodeId);
    _pendingInsertNodeIds.remove(nodeId);
  }

  Future<void> _flushPendingChangesInternal() async {
    if (_pendingNodeIds.isEmpty && _pendingInsertNodeIds.isEmpty) return;

    // Process insertions in document order first
    final insertNodeIdsToProcess = _pendingInsertNodeIds.toSet();
    _pendingInsertNodeIds.clear();

    final documentNodesInOrder = document.map((n) => n.id).toList();
    final sortedInsertNodeIds = insertNodeIdsToProcess.toList()
      ..sort(
        (a, b) => documentNodesInOrder
            .indexOf(a)
            .compareTo(documentNodesInOrder.indexOf(b)),
      );

    final insertMutationsToEnqueue =
        <persistence_mutations.InsertBlockMutation>[];

    for (final nodeId in sortedInsertNodeIds) {
      final node = document.getNodeById(nodeId);
      if (node == null) continue;

      final newBlockId = _registry.blockIdForNode(nodeId);
      if (newBlockId == null) continue;

      final data = BlockDataSerializer.encodeDocumentNode(node);
      final type = BlockDataSerializer.blockTypeFor(node);

      final previousNode = document.getNodeBeforeById(nodeId);
      final nextNode = document.getNodeAfterById(nodeId);

      final previousBlockId = previousNode != null
          ? _registry.blockIdForNode(previousNode.id)
          : null;

      final nextBlockId =
          nextNode != null ? _registry.blockIdForNode(nextNode.id) : null;

      final previousMetadata =
          previousNode?.metadata ?? const <String, dynamic>{};
      final previousBlockIsToggle = previousMetadata['listType'] == 'toggle' ||
          previousMetadata['type'] == 'toggle' ||
          (previousMetadata['blockType'] is NamedAttribution &&
              (previousMetadata['blockType'] as NamedAttribution).name ==
                  'toggle');

      String? providedParent = node.metadata['parentBlockId'] as String?;
      if (providedParent != null) {
        final mappedBlockId = _registry.blockIdForNode(providedParent);
        if (mappedBlockId != null) {
          providedParent = mappedBlockId;
        }
      }

      final insertMutation = StructuralMutationBuilder.buildInsertMutation(
        pageId: pageId,
        blockId: newBlockId,
        data: data,
        type: type,
        previousBlockId: previousBlockId,
        nextBlockId: nextBlockId,
        snapshot: snapshot,
        providedParentBlockId: providedParent,
        previousBlockIsToggle: previousBlockIsToggle,
      );

      if (insertMutation != null) {
        debugPrint(
          '[KETION_TOGGLE_DIAG] Adapter built insertMutation: nodeId=$nodeId, blockId=$newBlockId, type=$type, parentBlockId=${insertMutation.parentBlockId}, position=${insertMutation.position}',
        );
        insertMutationsToEnqueue.add(insertMutation);
        snapshot.applyMutation(insertMutation);
        // Remove from pending updates if it was inadvertently added (e.g. text changed immediately)
        _pendingNodeIds.remove(nodeId);
      }
    }

    for (final mutation in insertMutationsToEnqueue) {
      try {
        coordinator.enqueue(mutation);
      } catch (e) {
        debugPrint(
          'KETION: Flush enqueue failed for insert block ${mutation.blockId}: $e',
        );
      }
    }

    // Now process any remaining updates
    if (_pendingNodeIds.isEmpty) return;

    final nodeIdsToProcess = _pendingNodeIds.toSet();
    _pendingNodeIds.clear();

    final mutationsToEnqueue = <persistence_mutations.UpdateBlockMutation>[];

    for (final nodeId in nodeIdsToProcess) {
      final node = document.getNodeById(nodeId);
      if (node != null) {
        final currentMetadata = node.metadata;
        final newData = _buildDataFromNode(node);
        final hash = EditorIdentityRegistry.hashContent(newData);

        final blockId = _registry.blockIdForNode(nodeId);
        if (blockId != null) {
          mutationsToEnqueue.add(
            persistence_mutations.UpdateBlockMutation(
              pageId: pageId,
              blockId: blockId,
              data: newData,
              parentBlockId: (currentMetadata['depth'] == 0)
                  ? null
                  : (currentMetadata['parentBlockId'] as String? ??
                      snapshot.getBlock(blockId)?.parentBlockId),
              position: (currentMetadata['position'] as num?)?.toDouble() ??
                  snapshot.getBlock(blockId)?.position ??
                  0.0,
              type: BlockDataSerializer.blockTypeFor(node),
              expectedVersion: _registry.getBlockVersion(blockId),
              blockCreatedAt: _registry.getBlockCreatedAt(blockId) ??
                  DateTime.now().toUtc(),
              createdAt: DateTime.now().toUtc(),
              contentHash: hash,
            ),
          );
        }
      }
    }

    for (final mutation in mutationsToEnqueue) {
      try {
        coordinator.enqueue(mutation);
      } catch (e) {
        debugPrint(
          'KETION: Flush enqueue failed for block ${mutation.blockId}: $e',
        );
      }
    }
  }

  String _buildDataFromNode(DocumentNode node) {
    return BlockDataSerializer.encodeDocumentNode(node);
  }
}
