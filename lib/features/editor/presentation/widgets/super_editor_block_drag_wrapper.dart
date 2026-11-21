import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import 'depth_wrapping_component_builder.dart';
import 'ketion_edit_requests.dart';

class BlockDragPayload {
  final String nodeId;
  const BlockDragPayload(this.nodeId);
}

class SuperEditorBlockDragWrapper extends StatefulWidget {
  final String nodeId;
  final Document document;
  final Editor editor;
  final Widget child;

  const SuperEditorBlockDragWrapper({
    super.key,
    required this.nodeId,
    required this.document,
    required this.editor,
    required this.child,
  });

  @override
  State<SuperEditorBlockDragWrapper> createState() =>
      _SuperEditorBlockDragWrapperState();
}

class _SuperEditorBlockDragWrapperState
    extends State<SuperEditorBlockDragWrapper> {
  bool _isHovered = false;
  bool _isDropBefore = false;
  bool _isDropAfter = false;

  bool _isDescendantOf(
    Document document,
    String candidateNodeId,
    String ancestorNodeId,
  ) {
    if (candidateNodeId == ancestorNodeId) return true;
    final ancestorIndex = document.getNodeIndexById(ancestorNodeId);
    if (ancestorIndex == -1) return false;
    final ancestorNode = document.getNodeAt(ancestorIndex);
    if (ancestorNode == null) return false;
    final ancestorDepth = getNodeDepth(ancestorNode);

    for (int i = ancestorIndex + 1; i < document.nodeCount; i++) {
      final node = document.getNodeAt(i);
      if (node == null) break;
      final depth = getNodeDepth(node);
      if (depth <= ancestorDepth) break;
      if (node.id == candidateNodeId) return true;
    }
    return false;
  }

  void _handleDrop(String draggedNodeId, bool isBefore) {
    if (draggedNodeId == widget.nodeId) return;

    widget.editor.execute([
      MoveBlockRequest(
        sourceNodeId: draggedNodeId,
        targetNodeId: widget.nodeId,
        isBefore: isBefore,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isDesktop = platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;

    final dragHandle = Icon(
      Icons.drag_indicator,
      key: ValueKey('block_drag_handle_${widget.nodeId}'),
      size: 18,
      color: Colors.grey.shade600,
    );

    final feedbackWidget = Material(
      elevation: 6.0,
      borderRadius: BorderRadius.circular(6.0),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_indicator, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Moving block...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );

    Widget buildHandle({required bool isDragging}) {
      Widget handle = SizedBox(
        width: 24,
        height: 24,
        child: Center(child: dragHandle),
      );

      if (isDragging) {
        return Opacity(
          opacity: 0.3,
          child: handle,
        );
      }

      if (isDesktop) {
        return MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Tooltip(
            message: 'Drag to reorder',
            waitDuration: const Duration(milliseconds: 500),
            child: handle,
          ),
        );
      }

      return handle;
    }

    final draggable = isDesktop
        ? Draggable<BlockDragPayload>(
            data: BlockDragPayload(widget.nodeId),
            feedback: feedbackWidget,
            childWhenDragging: buildHandle(isDragging: true),
            child: buildHandle(isDragging: false),
          )
        : LongPressDraggable<BlockDragPayload>(
            data: BlockDragPayload(widget.nodeId),
            feedback: feedbackWidget,
            hapticFeedbackOnStart: true,
            delay: const Duration(milliseconds: 250),
            childWhenDragging: buildHandle(isDragging: true),
            child: buildHandle(isDragging: false),
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: DragTarget<BlockDragPayload>(
        onWillAcceptWithDetails: (details) {
          if (details.data.nodeId == widget.nodeId) return false;
          if (_isDescendantOf(
            widget.document,
            widget.nodeId,
            details.data.nodeId,
          )) {
            return false;
          }
          return true;
        },
        onMove: (details) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final localPos = renderBox.globalToLocal(details.offset);
          final isTopHalf = localPos.dy < (renderBox.size.height / 2);
          if (_isDropBefore != isTopHalf || _isDropAfter != !isTopHalf) {
            setState(() {
              _isDropBefore = isTopHalf;
              _isDropAfter = !isTopHalf;
            });
          }
        },
        onLeave: (_) {
          setState(() {
            _isDropBefore = false;
            _isDropAfter = false;
          });
        },
        onAcceptWithDetails: (details) {
          final isBefore = _isDropBefore;
          setState(() {
            _isDropBefore = false;
            _isDropAfter = false;
          });
          _handleDrop(details.data.nodeId, isBefore);
        },
        builder: (context, candidateData, rejectedData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isDropBefore)
                Container(
                  key: const ValueKey('block_drop_indicator_before'),
                  height: 2,
                  margin: const EdgeInsets.symmetric(vertical: 1.0),
                  color: Theme.of(context).colorScheme.primary,
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: AnimatedOpacity(
                      opacity: _isHovered || !isDesktop ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: draggable,
                    ),
                  ),
                  Expanded(
                    child: widget.child,
                  ),
                ],
              ),
              if (_isDropAfter)
                Container(
                  key: const ValueKey('block_drop_indicator_after'),
                  height: 2,
                  margin: const EdgeInsets.symmetric(vertical: 1.0),
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          );
        },
      ),
    );
  }
}
