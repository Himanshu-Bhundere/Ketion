import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/assistive_ball_provider.dart';
import 'assistive_ball_widget.dart';

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

    if (isNativeOverlayPlatform &&
        !ballState.isMenuOpen &&
        !ballState.isFloatingNoteOpen &&
        !ballState.isNoteSelectorOpen) {
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
