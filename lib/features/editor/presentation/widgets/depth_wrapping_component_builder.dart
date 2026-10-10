import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../table/ketion_table_node.dart';

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

    if (editor != null && node != null && node is! KetionTableNode) {
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

    if (_dragDistanceX > swipeThreshold || velocity > 200) {
      // Swipe right -> Indent
      widget.editor.execute([
        IndentParagraphRequest(widget.nodeId),
      ]);
    } else if (_dragDistanceX < -swipeThreshold || velocity < -200) {
      // Swipe left -> Unindent
      widget.editor.execute([
        UnIndentParagraphRequest(widget.nodeId),
      ]);
    }
  }

  void _onHorizontalDragCancel() {
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onHorizontalDragCancel: _onHorizontalDragCancel,
      child: widget.child,
    );
  }
}
