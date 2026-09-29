import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/drop_intent.dart';
import '../providers/editor_state_provider.dart';

class BlockWrapper extends ConsumerStatefulWidget {
  final String blockId;
  final Widget child;
  final int index;
  final int depth;
  final String pageId;
  final void Function(String type)? onInsert;
  final void Function(Offset)? onDragUpdate;
  final VoidCallback? onDragEnd;

  const BlockWrapper({
    super.key,
    required this.blockId,
    required this.child,
    required this.index,
    this.depth = 0,
    required this.pageId,
    this.onInsert,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  ConsumerState<BlockWrapper> createState() => _BlockWrapperState();
}

class _BlockWrapperState extends ConsumerState<BlockWrapper> {
  bool _isHovered = false;
  DropIntent? _currentDropIntent;

  void _handleDrop(String draggedBlockId, DropIntent intent) {
    if (draggedBlockId == widget.blockId) return;

    ref
        .read(editorStateProvider(widget.pageId).notifier)
        .handleDropIntent(draggedBlockId, intent);
    
    setState(() {
      _currentDropIntent = null;
    });
  }

  DropIntent _calculateDropIntent(Offset localPosition, Size size) {
    // Top 25% = before
    // Bottom 25% = after
    // Middle 50% = child, UNLESS x-offset is very negative (unnest)
    
    final relativeY = localPosition.dy / size.height;
    
    // Check for unnest intention (dragged to the far left)
    if (localPosition.dx < -20.0 && widget.depth > 0) {
      return DropIntent.unnest(widget.blockId);
    }

    if (relativeY < 0.25) {
      return DropIntent.before(widget.blockId);
    } else if (relativeY > 0.75) {
      return DropIntent.after(widget.blockId);
    } else {
      return DropIntent.child(widget.blockId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux;

    final feedbackWidget = Material(
      elevation: 4.0,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Text('Dragging block...'),
      ),
    );

    const dragHandle = Icon(
      Icons.drag_indicator,
      size: 18,
      color: Colors.grey,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: EdgeInsets.only(left: (widget.depth * 24.0)),
        child: DragTarget<String>(
          onWillAcceptWithDetails: (details) => details.data != widget.blockId,
          onMove: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(details.offset);
            final intent = _calculateDropIntent(localPosition, renderBox.size);
            
            if (_currentDropIntent != intent) {
              setState(() {
                _currentDropIntent = intent;
              });
            }
          },
          onLeave: (_) {
            setState(() {
              _currentDropIntent = null;
            });
          },
          onAcceptWithDetails: (details) {
            if (_currentDropIntent != null) {
              _handleDrop(details.data, _currentDropIntent!);
            } else {
              _handleDrop(details.data, DropIntent.after(widget.blockId));
            }
          },
          builder: (context, candidateData, rejectedData) {
            final isBefore = _currentDropIntent == DropIntent.before(widget.blockId);
            final isAfter = _currentDropIntent == DropIntent.after(widget.blockId);
            final isChild = _currentDropIntent == DropIntent.child(widget.blockId);
            final isUnnest = _currentDropIntent == DropIntent.unnest(widget.blockId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isBefore)
                  Container(
                    height: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle and options
                    SizedBox(
                      width: 32,
                      child: AnimatedOpacity(
                        opacity: _isHovered || !isDesktop ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: isDesktop
                            ? Draggable<String>(
                                data: widget.blockId,
                                feedback: feedbackWidget,
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: IconButton(
                                    icon: dragHandle,
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                  ),
                                ),
                                child: IconButton(
                                  icon: dragHandle,
                                  onPressed: () {},
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                ),
                                onDragUpdate: (details) => widget.onDragUpdate?.call(details.globalPosition),
                                onDragEnd: (_) => widget.onDragEnd?.call(),
                              )
                            : LongPressDraggable<String>(
                                data: widget.blockId,
                                feedback: feedbackWidget,
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: IconButton(
                                    icon: dragHandle,
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                  ),
                                ),
                                child: IconButton(
                                  icon: dragHandle,
                                  onPressed: () {},
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                ),
                                onDragUpdate: (details) => widget.onDragUpdate?.call(details.globalPosition),
                                onDragEnd: (_) => widget.onDragEnd?.call(),
                              ),
                      ),
                    ),

                    // The block content
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: isChild
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2.0,
                                )
                              : isUnnest
                                ? Border(
                                    left: BorderSide(
                                      color: Theme.of(context).colorScheme.secondary,
                                      width: 4.0,
                                    ),
                                  )
                                : null,
                        ),
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
                if (isAfter)
                  Container(
                    height: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
