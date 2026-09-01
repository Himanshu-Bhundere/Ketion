import 'package:flutter/material.dart';

class BlockWrapper extends StatefulWidget {
  final String blockId;
  final Widget child;
  final int index;

  const BlockWrapper({
    super.key,
    required this.blockId,
    required this.child,
    required this.index,
  });

  @override
  State<BlockWrapper> createState() => _BlockWrapperState();
}

class _BlockWrapperState extends State<BlockWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux;
        
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle and options
          SizedBox(
            width: 32,
            child: AnimatedOpacity(
              opacity: (!isDesktop || _isHovered) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: ReorderableDragStartListener(
                index: widget.index,
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
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ),
            ),
          ),

          // The block content
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
