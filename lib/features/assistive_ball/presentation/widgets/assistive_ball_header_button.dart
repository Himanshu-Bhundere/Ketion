import 'package:flutter/material.dart';

class AssistiveBallHeaderButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const AssistiveBallHeaderButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<AssistiveBallHeaderButton> createState() =>
      _AssistiveBallHeaderButtonState();
}

class _AssistiveBallHeaderButtonState extends State<AssistiveBallHeaderButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final foregroundColor = theme.colorScheme.onSurface;

    return Tooltip(
      message: widget.tooltip,
      triggerMode: TooltipTriggerMode.manual,
      waitDuration: const Duration(days: 365),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (mounted) {
            setState(() => _isHovered = true);
          }
        },
        onExit: (_) {
          if (mounted) {
            setState(() {
              _isHovered = false;
              _isPressed = false;
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: (_) {
            setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isPressed
                  ? theme.colorScheme.primary.withValues(alpha: 0.16)
                  : _isHovered
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 18,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}
