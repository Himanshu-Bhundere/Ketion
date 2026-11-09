import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/assistive_ball_provider.dart';
import 'floating_note_view.dart';
import 'note_selector_panel.dart';

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

    final targetX = ballState.normalizedX < 0.5 ? 0.02 : 0.98;
    final targetY = ballState.normalizedY < 0.5 ? 0.02 : 0.98;

    final startX = ballState.normalizedX;
    final startY = ballState.normalizedY;

    final animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    void update() {
      final t = animation.value;

      ref.read(assistiveBallProvider.notifier).updatePosition(
            startX + (targetX - startX) * t,
            startY + (targetY - startY) * t,
          );
    }

    animation.addListener(update);

    _animController.forward(from: 0).then((_) {
      animation.removeListener(update);

      if (!mounted) return;

      ref.read(assistiveBallProvider.notifier).snapToNearestCorner(
            targetX,
            targetY,
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

    final parentWidth = widget.parentConstraints.maxWidth;
    final parentHeight = widget.parentConstraints.maxHeight;

    final parentW = parentWidth - _ballSize;
    final parentH = parentHeight - _ballSize;

    final pixelLeft = (ballState.normalizedX * parentW).clamp(0.0, parentW);
    final pixelTop = (ballState.normalizedY * parentH).clamp(0.0, parentH);

    final isLeft = ballState.normalizedX < 0.5;
    final isTop = ballState.normalizedY < 0.5;

    final panelWidth = math.min(
      ballState.floatingNoteWidth,
      math.max(0.0, parentWidth - 24.0),
    );
    final panelHeight = math.min(
      ballState.floatingNoteHeight,
      math.max(0.0, parentHeight - 24.0),
    );

    final rawPanelLeft =
        isLeft ? pixelLeft : pixelLeft + _ballSize - panelWidth;
    final rawPanelTop =
        isTop ? pixelTop + _ballSize + 8.0 : pixelTop - panelHeight - 8.0;

    final panelLeft = rawPanelLeft
        .clamp(
          12.0,
          math.max(12.0, parentWidth - panelWidth - 12.0),
        )
        .toDouble();
    final panelTop = rawPanelTop
        .clamp(
          12.0,
          math.max(12.0, parentHeight - panelHeight - 12.0),
        )
        .toDouble();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Assistive Ball (first child)
        Positioned(
          left: pixelLeft,
          top: pixelTop,
          width: _ballSize,
          height: _ballSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
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

        // 2. Note Selector Panel
        if (ballState.isNoteSelectorOpen)
          Positioned(
            left: panelLeft,
            top: panelTop,
            width: panelWidth,
            height: panelHeight,
            child: Material(
              type: MaterialType.transparency,
              child: NoteSelectorPanel(
                onClose: () {
                  ref.read(assistiveBallProvider.notifier).closeNoteSelector();
                },
                onSelect: (pageId) {
                  ref
                      .read(assistiveBallProvider.notifier)
                      .openFloatingNote(pageId: pageId);
                },
              ),
            ),
          ),

        // 3. Floating Note
        if (ballState.isFloatingNoteOpen)
          Positioned(
            left: panelLeft,
            top: panelTop,
            width: panelWidth,
            height: panelHeight,
            child: Material(
              type: MaterialType.transparency,
              child: FloatingNoteView(
                parentConstraints: widget.parentConstraints,
              ),
            ),
          ),

        // 4. Popout Menu
        if (ballState.isMenuOpen)
          Positioned(
            left: isLeft ? pixelLeft + _ballSize + 12 : null,
            right: !isLeft ? parentWidth - pixelLeft + 12 : null,
            top: (pixelTop - 50.0).clamp(
              16.0,
              math.max(16.0, parentHeight - 200.0),
            ),
            child: _buildPopoutMenu(accentColor),
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
              theme: theme,
              onTap: () {
                ref.read(assistiveBallProvider.notifier).openFloatingNote();
              },
            ),
            _buildMenuItem(
              icon: Icons.note_alt_outlined,
              label: 'Note Selector',
              theme: theme,
              onTap: () {
                ref.read(assistiveBallProvider.notifier).openNoteSelector();
              },
            ),
            const Divider(height: 12),
            _buildMenuItem(
              icon: Icons.visibility_off_outlined,
              label: 'Hide Ball',
              theme: theme,
              onTap: () {
                ref.read(assistiveBallProvider.notifier).setEnabled(false);
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
    required ThemeData theme,
  }) {
    return SizedBox(
      width: 190,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
