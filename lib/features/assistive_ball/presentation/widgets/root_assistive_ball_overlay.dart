import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/assistive_ball_provider.dart';
import 'assistive_ball_widget.dart';
import 'floating_note_view.dart';
import 'note_selector_panel.dart';

class RootAssistiveBallOverlay extends ConsumerWidget {
  final Widget child;

  const RootAssistiveBallOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ballState = ref.watch(assistiveBallProvider);

    if (!ballState.isEnabled) {
      return child;
    }

    final platform = Theme.of(context).platform;
    final isNativeOverlayPlatform =
        platform == TargetPlatform.android ||
        platform == TargetPlatform.windows;

    final isOverlayWindowActive =
        ballState.isFloatingNoteOpen || ballState.isNoteSelectorOpen;

    // In standalone overlay mode (opened from assistive ball outside the app):
    // Render ONLY the overlay dialog, without the main app dashboard!
    if (isOverlayWindowActive && ballState.isStandaloneOverlay) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ballState.isNoteSelectorOpen
                ? NoteSelectorPanel(
                    onClose: () {
                      ref
                          .read(assistiveBallProvider.notifier)
                          .closeNoteSelector();
                    },
                    onSelect: (pageId) {
                      ref.read(assistiveBallProvider.notifier).openFloatingNote(
                            pageId: pageId,
                            isStandalone: true,
                          );
                    },
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return FloatingNoteView(
                        key: const ValueKey('standalone_floating_note_view'),
                        parentConstraints: constraints,
                      );
                    },
                  ),
          ),
        ),
      );
    }

    // If native overlay is handling the ball and no dialog/menu is open, keep tree minimal
    if (isNativeOverlayPlatform &&
        !ballState.isMenuOpen &&
        !isOverlayWindowActive) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            AssistiveBallWidget(parentConstraints: constraints),
          ],
        );
      },
    );
  }
}
