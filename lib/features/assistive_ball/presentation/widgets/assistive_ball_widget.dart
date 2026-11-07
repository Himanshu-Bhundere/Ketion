import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/assistive_ball_provider.dart';

class AssistiveBallWidget extends ConsumerStatefulWidget {
  final BoxConstraints parentConstraints;

  const AssistiveBallWidget({
    super.key,
    required this.parentConstraints,
  });

  @override
  ConsumerState<AssistiveBallWidget> createState() =>
      _AssistiveBallWidgetState();
}

class _AssistiveBallWidgetState extends ConsumerState<AssistiveBallWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _snapAnimation;
  bool _isDragging = false;

  static const double _ballSize = 52.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _animController.stop();
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final parentW = widget.parentConstraints.maxWidth - _ballSize;
    final parentH = widget.parentConstraints.maxHeight - _ballSize;

    if (parentW <= 0 || parentH <= 0) return;

    final ballState = ref.read(assistiveBallProvider);
    final curPixelX = ballState.normalizedX * parentW;
    final curPixelY = ballState.normalizedY * parentH;

    final nextPixelX = curPixelX + details.delta.dx;
    final nextPixelY = curPixelY + details.delta.dy;

    ref.read(assistiveBallProvider.notifier).updatePosition(
          nextPixelX / parentW,
          nextPixelY / parentH,
        );
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    final ballState = ref.read(assistiveBallProvider);
    final targetX = ballState.normalizedX < 0.5 ? 0.04 : 0.94;

    final startX = ballState.normalizedX;
    _snapAnimation = Tween<double>(begin: startX, end: targetX).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    )..addListener(() {
        ref.read(assistiveBallProvider.notifier).updatePosition(
              _snapAnimation!.value,
              ballState.normalizedY,
            );
      });

    _animController.forward(from: 0.0).then((_) {
      ref.read(assistiveBallProvider.notifier).snapToNearestEdge(
            targetX,
            ballState.normalizedY,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ballState = ref.watch(assistiveBallProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.valueOrNull;

    final accentColor = settings != null
        ? AppColors.getAccentColor(settings.accentColor.name)
        : Theme.of(context).colorScheme.primary;

    final parentW = widget.parentConstraints.maxWidth - _ballSize;
    final parentH = widget.parentConstraints.maxHeight - _ballSize;

    final pixelLeft = (ballState.normalizedX * parentW).clamp(0.0, parentW);
    final pixelTop = (ballState.normalizedY * parentH).clamp(0.0, parentH);

    final isLeft = ballState.normalizedX < 0.5;

    return Stack(
      children: [
        // Dismiss backdrop when menu is open
        if (ballState.isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                ref.read(assistiveBallProvider.notifier).closeMenu();
              },
              child: Container(color: Colors.black26),
            ),
          ),

        // Popout Menu
        if (ballState.isMenuOpen)
          Positioned(
            left: isLeft ? pixelLeft + _ballSize + 12 : null,
            right: !isLeft
                ? widget.parentConstraints.maxWidth - pixelLeft + 12
                : null,
            top: (pixelTop - 50.0).clamp(
              16.0,
              widget.parentConstraints.maxHeight - 200.0,
            ),
            child: _buildPopoutMenu(accentColor),
          ),

        // Assistive Ball
        Positioned(
          left: pixelLeft,
          top: pixelTop,
          width: _ballSize,
          height: _ballSize,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onTap: () {
              if (ballState.isNoteMinimized) {
                ref.read(assistiveBallProvider.notifier).restoreFloatingNote();
              } else {
                ref.read(assistiveBallProvider.notifier).toggleMenu();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accentColor,
                    accentColor.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: _isDragging ? 14 : 8,
                    spreadRadius: _isDragging ? 2 : 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  ballState.isNoteMinimized
                      ? Icons.note_alt_outlined
                      : (ballState.isMenuOpen
                          ? Icons.close
                          : Icons.bubble_chart_rounded),
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopoutMenu(Color accentColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      color: isDark ? const Color(0xFF2A2D32) : Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuItem(
              icon: Icons.edit_note,
              label: 'Quick Note',
              onTap: () {
                ref.read(assistiveBallProvider.notifier).openFloatingNote();
              },
            ),
            _buildMenuItem(
              icon: Icons.history,
              label: 'Recent Note',
              onTap: () async {
                final recentAsync = await ref.read(recentPagesProvider.future);
                if (recentAsync.isNotEmpty) {
                  ref
                      .read(assistiveBallProvider.notifier)
                      .openFloatingNote(pageId: recentAsync.first.id);
                } else {
                  ref.read(assistiveBallProvider.notifier).openFloatingNote();
                }
              },
            ),
            const Divider(height: 12),
            _buildMenuItem(
              icon: Icons.visibility_off_outlined,
              label: 'Hide Ball',
              onTap: () {
                ref.read(assistiveBallProvider.notifier).closeMenu();
                ref.read(assistiveBallProvider.notifier).setVisibility(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
