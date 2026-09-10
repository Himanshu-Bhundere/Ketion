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

  const BlockWrapper({
    super.key,
    required this.blockId,
    required this.child,
    required this.index,
    this.depth = 0,
    required this.pageId,
  });

  @override
  ConsumerState<BlockWrapper> createState() => _BlockWrapperState();
}

class _BlockWrapperState extends ConsumerState<BlockWrapper> {
  bool _isHovered = false;

  void _handleDrop(String draggedBlockId, String intentType) {
    if (draggedBlockId == widget.blockId) return;

    DropIntent intent;
    switch (intentType) {
      case 'before':
        intent = DropIntent.before(widget.blockId);
        break;
      case 'child':
        intent = DropIntent.child(widget.blockId);
        break;
      case 'after':
      default:
        intent = DropIntent.after(widget.blockId);
        break;
    }

    ref.read(editorStateProvider(widget.pageId).notifier).handleDropIntent(draggedBlockId, intent);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: EdgeInsets.only(left: (widget.depth * 24.0)),
        child: DragTarget<String>(
          onAcceptWithDetails: (details) {
            // Simplified drop zone resolution. 
            // Real implementation could check local cursor position to determine Before/Child/After.
            // For now, assume After.
            _handleDrop(details.data, 'after');
          },
          builder: (context, candidateData, rejectedData) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle and options
                SizedBox(
                  width: 32,
                  child: AnimatedOpacity(
                    opacity: (!isDesktop || _isHovered) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Draggable<String>(
                      data: widget.blockId,
                      feedback: Material(
                        elevation: 4.0,
                        child: Container(
                          width: 300,
                          padding: const EdgeInsets.all(8),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Text('Dragging block...'),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: IconButton(
                          icon: const Icon(
                            Icons.drag_indicator,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.drag_indicator,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          // Show block options menu
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ),
                  ),
                ),

                // The block content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: candidateData.isNotEmpty
                          ? Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2.0,
                              ),
                            )
                          : null,
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
