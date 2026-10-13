import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../table/ketion_table_node.dart';

/// Checks whether [node] is nested inside a toggle block.
bool isNodeInsideToggle(DocumentNode node, Document document) {
  // 1. Direct or indirect parent check via parentBlockId
  final parentBlockId = node.metadata['parentBlockId'] as String?;
  if (parentBlockId != null) {
    DocumentNode? curr = document.getNodeById(parentBlockId);
    final visited = <String>{};
    while (curr != null && !visited.contains(curr.id)) {
      visited.add(curr.id);
      final blockType = curr.metadata['blockType'];
      final isToggle = blockType == 'toggle' ||
          blockType == const NamedAttribution('toggle') ||
          (blockType is NamedAttribution && blockType.name == 'toggle') ||
          (curr.metadata['listType'] == 'toggle');
      if (isToggle) {
        return true;
      }
      final nextParentId = curr.metadata['parentBlockId'] as String?;
      if (nextParentId == null || nextParentId == curr.id) break;
      curr = document.getNodeById(nextParentId);
    }
  }

  // 2. Preceding ancestor check by depth
  final nodeDepth = node.metadata['depth'] as int? ??
      (node is ListItemNode ? node.indent : 0);
  if (nodeDepth > 0) {
    DocumentNode? prev = document.getNodeBeforeById(node.id);
    while (prev != null) {
      final prevDepth = prev.metadata['depth'] as int? ??
          (prev is ListItemNode ? prev.indent : 0);
      if (prevDepth < nodeDepth) {
        final blockType = prev.metadata['blockType'];
        final isToggle = blockType == 'toggle' ||
            blockType == const NamedAttribution('toggle') ||
            (blockType is NamedAttribution && blockType.name == 'toggle') ||
            (prev.metadata['listType'] == 'toggle');
        if (isToggle) {
          return true;
        }
      }
      prev = document.getNodeBeforeById(prev.id);
    }
  }

  return false;
}

/// Finds the root toggle block that contains [node].
DocumentNode? findParentToggleNode(DocumentNode node, Document document) {
  final parentBlockId = node.metadata['parentBlockId'] as String?;
  if (parentBlockId != null) {
    DocumentNode? curr = document.getNodeById(parentBlockId);
    final visited = <String>{};
    while (curr != null && !visited.contains(curr.id)) {
      visited.add(curr.id);
      final blockType = curr.metadata['blockType'];
      final isToggle = blockType == 'toggle' ||
          blockType == const NamedAttribution('toggle') ||
          (blockType is NamedAttribution && blockType.name == 'toggle') ||
          (curr.metadata['listType'] == 'toggle');
      if (isToggle) {
        return curr;
      }
      final nextParentId = curr.metadata['parentBlockId'] as String?;
      if (nextParentId == null || nextParentId == curr.id) break;
      curr = document.getNodeById(nextParentId);
    }
  }

  final nodeDepth = node.metadata['depth'] as int? ??
      (node is ListItemNode ? node.indent : 0);
  DocumentNode? prev = document.getNodeBeforeById(node.id);
  while (prev != null) {
    final prevDepth = prev.metadata['depth'] as int? ??
        (prev is ListItemNode ? prev.indent : 0);
    if (prevDepth < nodeDepth) {
      final blockType = prev.metadata['blockType'];
      final isToggle = blockType == 'toggle' ||
          blockType == const NamedAttribution('toggle') ||
          (blockType is NamedAttribution && blockType.name == 'toggle') ||
          (prev.metadata['listType'] == 'toggle');
      if (isToggle) {
        return prev;
      }
    }
    prev = document.getNodeBeforeById(prev.id);
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

  final toggleDepth = toggleNode.metadata['depth'] as int? ??
      (toggleNode is ListItemNode ? toggleNode.indent : 0);

  // Find the last descendant of toggleNode in the document
  DocumentNode lastDescendant = toggleNode;
  DocumentNode? candidate = document.getNodeAfterById(toggleNode.id);
  while (candidate != null) {
    final candidateDepth = candidate.metadata['depth'] as int? ??
        (candidate is ListItemNode ? candidate.indent : 0);
    if (candidateDepth <= toggleDepth) {
      break;
    }
    lastDescendant = candidate;
    candidate = document.getNodeAfterById(candidate.id);
  }

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
          metadata: const {'depth': 0},
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
    final depth = node?.metadata['depth'] as int? ?? 0;

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
