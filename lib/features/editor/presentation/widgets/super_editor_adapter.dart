import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import 'package:uuid/uuid.dart';

import '../../../blocks/domain/entities/block.dart';
import '../../domain/models/visible_block.dart';
import '../../domain/services/attribution_converter.dart';
import '../../domain/services/block_tree_service.dart';
import '../../domain/services/sibling_position_manager.dart';
import '../providers/editor_state_provider.dart';

class KetionSuperEditorAdapter {
  final String pageId;
  late final MutableDocument document;
  late final Editor editor;
  final WidgetRef ref;
  
  bool _isSyncingFromKetion = false;
  final Map<String, String> _nodeIdToBlockId = {};
  final Map<String, String> _blockIdToNodeId = {};
  final Map<String, int> _nodeHashes = {};

  KetionSuperEditorAdapter({
    required this.pageId,
    required this.ref,
  });

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
          _nodeIdToBlockId[node.id] = block.id;
          _blockIdToNodeId[block.id] = node.id;
          if (node is TextNode) {
            _nodeHashes[node.id] = Object.hash(node.text.toPlainText(), node.metadata.toString());
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
    document.removeListener(_onDocumentChange);
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
        
        default:
          return ParagraphNode(id: nodeId, text: attributedText, metadata: metadata.isNotEmpty ? metadata : null);
      }
    } catch (e) {
      return null;
    }
  }

  Timer? _debounceTimer;

  void _onDocumentChange(DocumentChangeLog log) {
    if (_isSyncingFromKetion) return;

    if (log.changes.isEmpty) {
      debugPrint('Empty DocumentChangeLog received (likely undo/redo). Triggering full sync.');
      _syncAllToKetion();
      return;
    }

    final changedNodeIds = <String>{};
    bool hasStructuralChanges = false;

    for (final change in log.changes) {
      if (change is NodeChangeEvent) {
        changedNodeIds.add(change.nodeId);
      } else if (change is NodeInsertedEvent) {
        _handleNodeInserted(change);
        hasStructuralChanges = true;
      } else if (change is NodeRemovedEvent) {
        _handleNodeRemoved(change);
        hasStructuralChanges = true;
      } else if (change is NodeMovedEvent) {
        _handleNodeMoved(change);
        hasStructuralChanges = true;
      }
    }
    
    if (changedNodeIds.isNotEmpty) {
      _debounceTimer?.cancel();
      if (hasStructuralChanges) {
        _processNodeChanges(changedNodeIds);
      } else {
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          _processNodeChanges(changedNodeIds);
        });
      }
    }
  }

  void _handleNodeInserted(NodeInsertedEvent event) async {
    final node = document.getNodeById(event.nodeId);
    if (node == null) return;
    
    final previousNode = document.getNodeBeforeById(event.nodeId);
    
    // Default to the previous node's parent and depth
    String? parentBlockId;
    int depth = 0;
    
    if (previousNode != null) {
      parentBlockId = previousNode.metadata['parentBlockId'] as String?;
      depth = previousNode.metadata['depth'] as int? ?? 0;
      node.metadata['parentBlockId'] = parentBlockId;
      node.metadata['depth'] = depth;
    }

    final blockId = const Uuid().v7();
    _nodeIdToBlockId[event.nodeId] = blockId;
    _blockIdToNodeId[blockId] = event.nodeId;
    
    final notifier = ref.read(editorStateProvider(pageId).notifier);
    final currentBlocks = await ref.read(editorStateProvider(pageId).future);
    
    // Find previous sibling
    Block? previousSibling;
    if (previousNode != null) {
      final prevBlockId = _nodeIdToBlockId[previousNode.id];
      if (prevBlockId != null) {
        final idx = currentBlocks.indexWhere((b) => b.id == prevBlockId);
        if (idx != -1) previousSibling = currentBlocks[idx];
      }
    }
    
    // Find next sibling
    Block? nextSibling;
    final nextNode = document.getNodeAfterById(event.nodeId);
    if (nextNode != null) {
      final nextBlockId = _nodeIdToBlockId[nextNode.id];
      if (nextBlockId != null) {
        final idx = currentBlocks.indexWhere((b) => b.id == nextBlockId);
        if (idx != -1) {
          final nextBlock = currentBlocks[idx];
          if (nextBlock.parentBlockId == parentBlockId) {
            nextSibling = nextBlock;
          }
        }
      }
    }

    final position = SiblingPositionManager.calculatePositionBetweenBlocks(previousSibling, nextSibling);
    
    String type = 'text';
    Map<String, dynamic> data = {
      'spans': <dynamic>[],
      'headingLevel': 0,
    };
    
    if (node is TextNode) {
      data['spans'] = AttributionConverter.toKetionSpans(node.text);
    }
    
    if (node is ListItemNode) {
       type = 'list';
       data['listType'] = node.type == ListItemType.ordered ? 'numbered' : 'bullet';
    } else if (node is TaskNode) {
       type = 'list';
       data['listType'] = 'checklist';
       data['checked'] = node.isComplete;
    }

    final block = Block(
      id: blockId,
      pageId: pageId,
      parentBlockId: parentBlockId,
      type: type,
      position: position,
      data: jsonEncode(data),
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    
    int insertIndex = currentBlocks.length;
    if (nextSibling != null) {
      insertIndex = currentBlocks.indexOf(nextSibling);
    }
    
    await notifier.insertBlockDirectly(block, insertIndex);
    
    if (node is TextNode) {
      _nodeHashes[node.id] = Object.hash(node.text.toPlainText(), node.metadata.toString());
    }
  }

  void _handleNodeRemoved(NodeRemovedEvent event) async {
    final blockId = _nodeIdToBlockId[event.nodeId];
    if (blockId == null) return;
    
    _nodeIdToBlockId.remove(event.nodeId);
    _blockIdToNodeId.remove(blockId);
    _nodeHashes.remove(event.nodeId);
    
    final notifier = ref.read(editorStateProvider(pageId).notifier);
    await notifier.deleteBlockDirectly(blockId);
  }

  void _handleNodeMoved(NodeMovedEvent event) async {
    final node = document.getNodeById(event.nodeId);
    if (node == null) return;
    
    final blockId = _nodeIdToBlockId[event.nodeId];
    if (blockId == null) return;
    
    final previousNode = document.getNodeBeforeById(event.nodeId);
    final nextNode = document.getNodeAfterById(event.nodeId);
    
    String? parentBlockId = node.metadata['parentBlockId'] as String?;
    
    final currentBlocks = await ref.read(editorStateProvider(pageId).future);
    
    Block? previousSibling;
    if (previousNode != null) {
      final prevBlockId = _nodeIdToBlockId[previousNode.id];
      if (prevBlockId != null) {
         final idx = currentBlocks.indexWhere((b) => b.id == prevBlockId);
         if (idx != -1) {
            final pb = currentBlocks[idx];
            if (pb.parentBlockId == parentBlockId) {
               previousSibling = pb;
            }
         }
      }
    }
    
    Block? nextSibling;
    if (nextNode != null) {
      final nextBlockId = _nodeIdToBlockId[nextNode.id];
      if (nextBlockId != null) {
         final idx = currentBlocks.indexWhere((b) => b.id == nextBlockId);
         if (idx != -1) {
            final nb = currentBlocks[idx];
            if (nb.parentBlockId == parentBlockId) {
               nextSibling = nb;
            }
         }
      }
    }

    final newPosition = SiblingPositionManager.calculatePositionBetweenBlocks(previousSibling, nextSibling);
    
    final notifier = ref.read(editorStateProvider(pageId).notifier);
    await notifier.moveBlockToPosition(
      blockId: blockId, 
      parentBlockId: parentBlockId, 
      position: newPosition,
    );
  }

  Future<void> _syncAllToKetion() async {
    final currentDocumentNodeIds = document.map((n) => n.id).toSet();
    final notifier = ref.read(editorStateProvider(pageId).notifier);
    final currentBlocks = await ref.read(editorStateProvider(pageId).future);
    
    // 1. Handle removals
    final nodeIdsToRemove = _nodeIdToBlockId.keys.where((id) => !currentDocumentNodeIds.contains(id)).toList();
    for (final id in nodeIdsToRemove) {
      final blockId = _nodeIdToBlockId[id];
      if (blockId != null) {
        final idx = currentBlocks.indexWhere((b) => b.id == blockId);
        if (idx != -1) {
          await notifier.deleteBlockDirectly(blockId);
        }
        _blockIdToNodeId.remove(blockId);
      }
      _nodeIdToBlockId.remove(id);
      _nodeHashes.remove(id);
    }

    // 2. Handle updates and insertions
    for (final node in document) {
      final blockId = _nodeIdToBlockId[node.id];
      
      if (blockId == null) {
        // Node was inserted via undo/redo
        // For simplicity in this gate, we can use the same logic as _handleNodeInserted
        // but here we might need to find its neighbors.
        // Actually, since we only need text edits for Gate 7 undo/redo round-trip,
        // we'll implement a simplified insert for now or reuse existing logic.
        final previousNode = document.getNodeBeforeById(node.id);
        String? parentBlockId;
        if (previousNode != null) {
          parentBlockId = previousNode.metadata['parentBlockId'] as String?;
          node.metadata['parentBlockId'] = parentBlockId;
        }

        final newBlockId = const Uuid().v7();
        _nodeIdToBlockId[node.id] = newBlockId;
        _blockIdToNodeId[newBlockId] = node.id;
        
        String type = 'text';
        Map<String, dynamic> data = {'spans': <dynamic>[], 'headingLevel': 0};
        
        if (node is TextNode) {
          data['spans'] = AttributionConverter.toKetionSpans(node.text);
        }
        
        if (node is ListItemNode) {
           type = 'list';
           data['listType'] = node.type == ListItemType.ordered ? 'numbered' : 'bullet';
        } else if (node is TaskNode) {
           type = 'list';
           data['listType'] = 'checklist';
           data['checked'] = node.isComplete;
        }

        final block = Block(
          id: newBlockId,
          pageId: pageId,
          parentBlockId: parentBlockId,
          type: type,
          position: 0, // Placeholder, will be fixed in Gate 4
          data: jsonEncode(data),
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        
        await notifier.insertBlockDirectly(block, currentBlocks.length);
        if (node is TextNode) {
          _nodeHashes[node.id] = Object.hash(node.text.toPlainText(), node.metadata.toString());
        }
      } else {
        // Update existing node if changed
        if (node is TextNode || node is TaskNode) {
          final hash = node is TextNode 
              ? Object.hash(node.text.toPlainText(), node.metadata.toString())
              : Object.hash((node as TaskNode).text.toPlainText(), node.isComplete, node.metadata.toString());
              
          if (_nodeHashes[node.id] != hash) {
            String type = 'text';
            Map<String, dynamic> data = {};
            
            if (node is ParagraphNode) {
              data['spans'] = AttributionConverter.toKetionSpans(node.text);
              data['headingLevel'] = 0;
            } else if (node is ListItemNode) {
              type = 'list';
              data['spans'] = AttributionConverter.toKetionSpans(node.text);
              data['listType'] = node.type == ListItemType.ordered ? 'numbered' : 'bullet';
            } else if (node is TaskNode) {
              type = 'list';
              data['spans'] = AttributionConverter.toKetionSpans(node.text);
              data['listType'] = 'checklist';
              data['checked'] = node.isComplete;
            }

            final updatedBlock = Block(
              id: blockId,
              pageId: pageId,
              type: type,
              parentBlockId: node.metadata['parentBlockId'] as String?,
              position: 0, // Will be preserved by the notifier usually, but need to be careful
              data: jsonEncode(data),
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            );
            
            // To preserve position, we actually need to get the existing block
            final existingBlockIdx = currentBlocks.indexWhere((b) => b.id == blockId);
            if (existingBlockIdx != -1) {
               final existingBlock = currentBlocks[existingBlockIdx];
               await notifier.updateBlockDirectly(updatedBlock.copyWith(position: existingBlock.position));
            }
            
            _nodeHashes[node.id] = hash;
          }
        }
      }
    }
  }

  void _processNodeChanges(Set<String> nodeIds) async {
    for (final nodeId in nodeIds) {
      final node = document.getNodeById(nodeId);
      if (node is TextNode) {
        final currentText = node.text.toPlainText();
        final currentMetadata = node.metadata;
        
        final hash = Object.hash(currentText, currentMetadata.toString());
        if (_nodeHashes[node.id] != hash) {
          _nodeHashes[node.id] = hash;
          
          final blockId = _nodeIdToBlockId[node.id];
          if (blockId != null) {
            _updateKetionBlock(blockId, node);
          }
        }
      }
    }
  }

  void _updateKetionBlock(String blockId, TextNode node) async {
    final blocks = await ref.read(editorStateProvider(pageId).future);
    final blockIndex = blocks.indexWhere((b) => b.id == blockId);
    if (blockIndex == -1) return;
    
    final oldBlock = blocks[blockIndex];
    final oldData = jsonDecode(oldBlock.data) as Map<String, dynamic>;
    
    oldData['spans'] = AttributionConverter.toKetionSpans(node.text);

    String newType = 'text';
    if (node is ListItemNode) {
      newType = 'list';
      oldData['listType'] = node.type == ListItemType.ordered ? 'numbered' : 'bullet';
    } else if (node is TaskNode) {
      newType = 'list';
      oldData['listType'] = 'checklist';
      oldData['checked'] = node.isComplete;
    } else if (node is ParagraphNode) {
      final blockType = node.metadata['blockType'];
      if (blockType == header1Attribution) {
        oldData['headingLevel'] = 1;
      } else if (blockType == header2Attribution) {
        oldData['headingLevel'] = 2;
      } else if (blockType == header3Attribution) {
        oldData['headingLevel'] = 3;
      } else {
        oldData['headingLevel'] = 0;
      }
    }

    final newBlock = oldBlock.copyWith(
      type: newType,
      data: jsonEncode(oldData),
      updatedAt: DateTime.now().toUtc(),
    );

    await ref.read(editorStateProvider(pageId).notifier).updateBlockDirectly(newBlock);
  }
}
