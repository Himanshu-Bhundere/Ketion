import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../table/ketion_table_node.dart';
import '../../domain/services/block_tree_service.dart';
import 'ketion_toggle_component.dart';

/// Gets the effective depth of a node from its canonical indent property or metadata.
int getNodeDepth(DocumentNode? node) {
  if (node == null) return 0;
  if (node is ListItemNode) return node.indent;
  if (node is TaskNode) return node.indent;
  final depth = node.metadata['depth'];
  if (depth is int) return depth;
  return 0;
}

/// Resolves a [DocumentNode] by either its in-memory [node.id] or its persistent
/// [node.metadata['blockId']].
DocumentNode? findDocumentNode(Document document, String id) {
  final byId = document.getNodeById(id);
  if (byId != null) return byId;
  for (final node in document) {
    if (node.metadata['blockId'] == id) {
      return node;
    }
  }
  return null;
}

/// Checks whether [node] is nested inside a toggle block.
bool isNodeInsideToggle(DocumentNode node, Document document) {
  // 1. Direct or indirect parent check via parentBlockId
  final parentBlockId = node.metadata['parentBlockId'] as String?;
  if (parentBlockId != null) {
    DocumentNode? curr = findDocumentNode(document, parentBlockId);
    final visited = <String>{};
    while (curr != null && !visited.contains(curr.id)) {
      visited.add(curr.id);
      if (KetionToggleComponentBuilder.isToggleNode(curr)) {
        return true;
      }
      final nextParentId = curr.metadata['parentBlockId'] as String?;
      if (nextParentId == null || nextParentId == curr.id) break;
      curr = findDocumentNode(document, nextParentId);
    }
  }

  // 2. Preceding ancestor check by depth
  int currDepth = getNodeDepth(node);
  DocumentNode? curr = node;
  while (currDepth > 0 && curr != null) {
    DocumentNode? prev = document.getNodeBeforeById(curr.id);
    DocumentNode? immediateParent;
    while (prev != null) {
      final prevDepth = getNodeDepth(prev);
      if (prevDepth < currDepth) {
        immediateParent = prev;
        break;
      }
      prev = document.getNodeBeforeById(prev.id);
    }
    if (immediateParent == null) break;
    if (KetionToggleComponentBuilder.isToggleNode(immediateParent)) {
      return true;
    }
    curr = immediateParent;
    currDepth = getNodeDepth(immediateParent);
  }

  return false;
}

/// Finds the enclosing toggle block that contains [node].
DocumentNode? findParentToggleNode(DocumentNode node, Document document) {
  final parentBlockId = node.metadata['parentBlockId'] as String?;
  if (parentBlockId != null) {
    DocumentNode? curr = findDocumentNode(document, parentBlockId);
    final visited = <String>{};
    while (curr != null && !visited.contains(curr.id)) {
      visited.add(curr.id);
      if (KetionToggleComponentBuilder.isToggleNode(curr)) {
        return curr;
      }
      final nextParentId = curr.metadata['parentBlockId'] as String?;
      if (nextParentId == null || nextParentId == curr.id) break;
      curr = findDocumentNode(document, nextParentId);
    }
  }

  int currDepth = getNodeDepth(node);
  DocumentNode? curr = node;
  while (currDepth > 0 && curr != null) {
    DocumentNode? prev = document.getNodeBeforeById(curr.id);
    DocumentNode? immediateParent;
    while (prev != null) {
      final prevDepth = getNodeDepth(prev);
      if (prevDepth < currDepth) {
        immediateParent = prev;
        break;
      }
      prev = document.getNodeBeforeById(prev.id);
    }
    if (immediateParent == null) break;
    if (KetionToggleComponentBuilder.isToggleNode(immediateParent)) {
      return immediateParent;
    }
    curr = immediateParent;
    currDepth = getNodeDepth(immediateParent);
  }

  return null;
}

/// Exits the toggle by placing the caret immediately outside (after) the toggle.
void exitToggle({
  required Editor editor,
  required Document document,
  required String nodeId,
}) {
  final node = document.getNodeById(nodeId);
  if (node == null) return;

  final toggleNode = findParentToggleNode(node, document);
  if (toggleNode == null) return;

  final toggleDepth = getNodeDepth(toggleNode);

  // Find the last descendant of toggleNode in the document using unified hierarchy service
  final lastDescendant = BlockTreeService.findLastDescendant(
    document,
    toggleNode,
    getNodeDepth,
  );

  final outsideNode = document.getNodeAfterById(lastDescendant.id);
  if (outsideNode != null) {
    editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: outsideNode.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
  } else {
    // Last block in the document: insert a new paragraph outside the toggle
    final newParagraphId = Editor.createNodeId();
    editor.execute([
      InsertNodeAfterNodeRequest(
        existingNodeId: lastDescendant.id,
        newNode: ParagraphNode(
          id: newParagraphId,
          text: AttributedText(),
          metadata: {'depth': toggleDepth},
        ),
      ),
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: newParagraphId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
  }
}

class DepthWrappingComponentBuilder implements ComponentBuilder {
  const DepthWrappingComponentBuilder(
    this.innerBuilder,
    this.document, {
    this.editor,
    this.composer,
  });

  final ComponentBuilder innerBuilder;
  final Document document;
  final Editor? editor;
  final DocumentComposer? composer;

  static const double kIndentPerLevel = 16.0;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    return innerBuilder.createViewModel(document, node);
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    final widget =
        innerBuilder.createComponent(componentContext, componentViewModel);
    if (widget == null) return null;

    final node = document.getNodeById(componentViewModel.nodeId);
    final depth = getNodeDepth(node);

    Widget content = widget;
    if (depth > 0) {
      content = Padding(
        padding: EdgeInsets.only(left: depth * kIndentPerLevel),
        child: content,
      );
    }

    final isIndentable = node is ParagraphNode || node is ListItemNode || node is TaskNode;

    if (editor != null && node != null && isIndentable && node is! KetionTableNode) {
      content = SwipeIndentationWrapper(
        nodeId: node.id,
        editor: editor!,
        document: document,
        composer: composer,
        child: content,
      );
    }

    return content;
  }
}

class SwipeIndentationWrapper extends StatefulWidget {
  final String nodeId;
  final Editor editor;
  final Document document;
  final DocumentComposer? composer;
  final Widget child;

  const SwipeIndentationWrapper({
    super.key,
    required this.nodeId,
    required this.editor,
    required this.document,
    this.composer,
    required this.child,
  });

  @override
  State<SwipeIndentationWrapper> createState() =>
      _SwipeIndentationWrapperState();
}

class _SwipeIndentationWrapperState extends State<SwipeIndentationWrapper> {
  double _dragDistanceX = 0.0;
  double _dragDistanceY = 0.0;
  bool _isDragging = false;

  void _onHorizontalDragStart(DragStartDetails details) {
    // If text selection is active (expanded selection), do not intercept
    if (widget.composer?.selection != null &&
        !widget.composer!.selection!.isCollapsed) {
      _isDragging = false;
      return;
    }
    _dragDistanceX = 0.0;
    _dragDistanceY = 0.0;
    _isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    _dragDistanceX += details.primaryDelta ?? details.delta.dx;
    _dragDistanceY += details.delta.dy;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    // Do not interfere with diagonal or vertical scrolling
    if (_dragDistanceY.abs() > _dragDistanceX.abs() * 0.8) {
      return;
    }

    const double swipeThreshold = 30.0;
    final velocity = details.primaryVelocity ?? 0.0;

    final node = widget.document.getNodeById(widget.nodeId);
    EditRequest indentRequest;
    EditRequest unindentRequest;
    if (node is ListItemNode) {
      indentRequest = IndentListItemRequest(nodeId: widget.nodeId);
      unindentRequest = UnIndentListItemRequest(nodeId: widget.nodeId);
    } else if (node is TaskNode) {
      indentRequest = IndentTaskRequest(widget.nodeId);
      unindentRequest = UnIndentTaskRequest(widget.nodeId);
    } else {
      indentRequest = IndentParagraphRequest(widget.nodeId);
      unindentRequest = UnIndentParagraphRequest(widget.nodeId);
    }

    if (_dragDistanceX > swipeThreshold || velocity > 200) {
      // Swipe right -> Indent
      widget.editor.execute([indentRequest]);
    } else if (_dragDistanceX < -swipeThreshold || velocity < -200) {
      // Swipe left -> Unindent
      widget.editor.execute([unindentRequest]);
    }
  }

  void _onHorizontalDragCancel() {
    _isDragging = false;
  }

  void _onDoubleTap() {
    final node = widget.document.getNodeById(widget.nodeId);
    if (node != null && isNodeInsideToggle(node, widget.document)) {
      exitToggle(
        editor: widget.editor,
        document: widget.document,
        nodeId: widget.nodeId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onHorizontalDragCancel: _onHorizontalDragCancel,
      onDoubleTap: _onDoubleTap,
      child: widget.child,
    );
  }
}
