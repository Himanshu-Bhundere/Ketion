import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:super_editor/super_editor.dart';
import 'package:uuid/uuid.dart';

import '../../../blocks/domain/entities/block.dart';
import '../../domain/models/visible_block.dart';
import '../../domain/services/attribution_converter.dart';
import '../../domain/services/block_tree_service.dart';
import '../../domain/services/block_data_serializer.dart';
import '../../services/editor_persistence_coordinator.dart';
import '../../services/editor_persistence_mutations.dart' as persistence_mutations;
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

  /// Exposes the identity registry for use by [KetionEditRequestHandler]
  /// and [KetionEditListener].
  EditorIdentityRegistry get registry => _registry;

  StreamSubscription<persistence_mutations.EditorPersistenceMutation>? _mutationSuccessSubscription;

  KetionSuperEditorAdapter({
    required this.pageId,
    required this.coordinator,
    required this.snapshot,
  }) {
    _mutationSuccessSubscription = coordinator.onMutationSuccess.listen(_onMutationSuccess);
  }

  void _onMutationSuccess(persistence_mutations.EditorPersistenceMutation mutation) {
    for (final transition in mutation.versionTransitions) {
      if (transition.operation == persistence_mutations.VersionChangeOperation.increment) {
        final current = _registry.getBlockVersion(transition.blockId);
        _registry.setBlockVersion(transition.blockId, current + 1);
      } else if (transition.operation == persistence_mutations.VersionChangeOperation.create) {
        _registry.promotePendingMapping(transition.blockId);
        _registry.setBlockVersion(transition.blockId, 1);
      } else if (transition.operation == persistence_mutations.VersionChangeOperation.softDelete) {
        final current = _registry.getBlockVersion(transition.blockId);
        _registry.markDeleted(transition.blockId, current + 1);
      }
    }

    if (mutation is persistence_mutations.UpdateBlockMutation) {
      final nodeId = _registry.nodeIdForBlock(mutation.blockId);
      if (nodeId != null) {
        final node = document.getNodeById(nodeId);
        if (node is TextNode) {
          final currentHash = EditorIdentityRegistry.hashContent(_buildDataFromNode(node));
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
      final visibleBlocks = BlockTreeService.buildVisibleTree(blocks);
      
      final nodes = <DocumentNode>[];
      
      for (final vb in visibleBlocks) {
        final block = vb.block;
        final node = _convertKetionBlockToNode(vb);
        if (node != null) {
          nodes.add(node);
          _registry.registerMapping(nodeId: node.id, blockId: block.id);
          _registry.setBlockVersion(block.id, block.version);
          _registry.setBlockCreatedAt(block.id, block.createdAt);
          if (node is TextNode) {
            _registry.setContentHash(node.id, EditorIdentityRegistry.hashContent(_buildDataFromNode(node)));
          }
        }
      }
      
      if (nodes.isEmpty) {
         final node = ParagraphNode(id: Editor.createNodeId(), text: AttributedText());
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

  DocumentNode? _convertKetionBlockToNode(VisibleBlock vb) {
    try {
      final block = vb.block;
      final data = jsonDecode(block.data) as Map<String, dynamic>;
      final spans = data['spans'] as List<dynamic>? ?? [];
      
      final attributedText = AttributionConverter.fromKetionSpans(spans);
      
      final nodeId = Editor.createNodeId();
      final metadata = <String, dynamic>{};
      if (block.parentBlockId != null) {
        metadata['parentBlockId'] = block.parentBlockId;
      }
      metadata['depth'] = vb.depth;
      metadata['position'] = block.position;

      switch (block.type) {
        case 'text':
          final headingLevel = data['headingLevel'] as int? ?? 0;
          if (headingLevel > 0 && headingLevel <= 3) {
            final type = [
              header1Attribution,
              header2Attribution,
              header3Attribution,
            ][headingLevel - 1];
            metadata['blockType'] = type;
            return ParagraphNode(id: nodeId, text: attributedText, metadata: metadata);
          }
          return ParagraphNode(id: nodeId, text: attributedText, metadata: metadata.isNotEmpty ? metadata : null);
        
        case 'list':
          final listType = data['listType'] as String? ?? 'bullet';
          if (listType == 'numbered') {
            return ListItemNode.ordered(id: nodeId, text: attributedText, metadata: metadata.isNotEmpty ? metadata : null);
          } else if (listType == 'checklist') {
            return TaskNode(id: nodeId, text: attributedText, isComplete: data['checked'] as bool? ?? false, metadata: metadata.isNotEmpty ? metadata : null);
          } else {
            return ListItemNode.unordered(id: nodeId, text: attributedText, metadata: metadata.isNotEmpty ? metadata : null);
          }
        
        case 'divider':
          return HorizontalRuleNode(id: nodeId);

        default:
          return ParagraphNode(id: nodeId, text: attributedText, metadata: metadata.isNotEmpty ? metadata : null);
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
    debugPrint('KETION: beginSemanticMutation for $nodeIds');
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
      debugPrint('KETION: _onDocumentChange change type: ${change.runtimeType}');
      if (change is NodeChangeEvent) {
        if (_activeSemanticMutationNodeIds.contains(change.nodeId)) {
          debugPrint('KETION: Suppressed NodeChangeEvent for ${change.nodeId}');
          continue;
        }
        debugPrint('KETION: Unsuppressed NodeChangeEvent for ${change.nodeId}');
        _pendingNodeIds.add(change.nodeId);
      } else if (change is NodeInsertedEvent) {
        if (_activeSemanticMutationNodeIds.contains(change.nodeId)) {
          debugPrint('KETION: Suppressed NodeInsertedEvent for ${change.nodeId}');
          continue;
        }
        debugPrint('KETION: Unsuppressed NodeInsertedEvent for ${change.nodeId}');
        
        // Allocate identity if it's missing
        if (_registry.blockIdForNode(change.nodeId) == null) {
          final newBlockId = const Uuid().v7();
          _registry.registerPendingMapping(nodeId: change.nodeId, blockId: newBlockId);
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
    if (_activeFlush != null) return _activeFlush!;
    _activeFlush = _flushPendingChangesInternal().whenComplete(() => _activeFlush = null);
    return _activeFlush!;
  }

  Future<void> _flushPendingChangesInternal() async {
    if (_pendingNodeIds.isEmpty && _pendingInsertNodeIds.isEmpty) return;
    
    // Process insertions in document order first
    final insertNodeIdsToProcess = _pendingInsertNodeIds.toSet();
    _pendingInsertNodeIds.clear();
    
    final documentNodesInOrder = document.map((n) => n.id).toList();
    final sortedInsertNodeIds = insertNodeIdsToProcess.toList()
      ..sort((a, b) => documentNodesInOrder.indexOf(a).compareTo(documentNodesInOrder.indexOf(b)));

    final insertMutationsToEnqueue = <persistence_mutations.InsertBlockMutation>[];

    for (final nodeId in sortedInsertNodeIds) {
      final node = document.getNodeById(nodeId);
      if (node == null) continue;

      final newBlockId = _registry.blockIdForNode(nodeId);
      if (newBlockId == null) continue;

      final data = BlockDataSerializer.encodeDocumentNode(node);
      final type = BlockDataSerializer.blockTypeFor(node);

      final previousNode = document.getNodeBeforeById(nodeId);
      final nextNode = document.getNodeAfterById(nodeId);

      final previousBlockId = previousNode != null ? _registry.blockIdForNode(previousNode.id) : null;
      final nextBlockId = nextNode != null ? _registry.blockIdForNode(nextNode.id) : null;

      final insertMutation = StructuralMutationBuilder.buildInsertMutation(
        pageId: pageId,
        blockId: newBlockId,
        data: data,
        type: type,
        previousBlockId: previousBlockId,
        nextBlockId: nextBlockId,
        snapshot: snapshot,
      );

      if (insertMutation != null) {
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
        debugPrint('KETION: Flush enqueue failed for insert block ${mutation.blockId}: $e');
      }
    }

    // Now process any remaining updates
    if (_pendingNodeIds.isEmpty) return;

    final nodeIdsToProcess = _pendingNodeIds.toSet();
    _pendingNodeIds.clear();

    final mutationsToEnqueue = <persistence_mutations.UpdateBlockMutation>[];
    
    for (final nodeId in nodeIdsToProcess) {
      final node = document.getNodeById(nodeId);
      if (node is TextNode) {
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
              parentBlockId: currentMetadata['parentBlockId'] as String?,
              position: (currentMetadata['position'] as num?)?.toDouble() ?? 0.0,
              type: BlockDataSerializer.blockTypeFor(node),
              expectedVersion: _registry.getBlockVersion(blockId),
              blockCreatedAt: _registry.getBlockCreatedAt(blockId) ?? DateTime.now().toUtc(),
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
        debugPrint('KETION: Flush enqueue failed for block ${mutation.blockId}: $e');
      }
    }
  }

  String _buildDataFromNode(TextNode node) {
    return BlockDataSerializer.encodeDocumentNode(node);
  }
}
