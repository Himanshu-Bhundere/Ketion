import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../data/services/assistive_ball_platform_service_impl.dart';
import '../../domain/models/assistive_ball_state.dart';
import '../../domain/services/assistive_ball_platform_service.dart';

final assistiveBallPlatformServiceProvider =
    Provider<AssistiveBallPlatformService>((ref) {
  return AssistiveBallPlatformServiceImpl();
});

class AssistiveBallNotifier extends StateNotifier<AssistiveBallState> {
  final Ref _ref;
  final AssistiveBallPlatformService _platformService;

  AssistiveBallNotifier(this._ref, this._platformService)
      : super(const AssistiveBallState()) {
    _init();
  }

  void _init() {
    _ref.listen(appSettingsProvider, (previous, next) {
      final settings = next.valueOrNull;
      if (settings != null && settings.assistiveBallEnabled != state.isEnabled) {
        state = state.copyWith(isEnabled: settings.assistiveBallEnabled);
        if (state.isEnabled) {
          _platformService.showSystemOverlay(
            x: state.normalizedX,
            y: state.normalizedY,
          );
        } else {
          _platformService.hideSystemOverlay();
        }
      }
    },
      fireImmediately: true,
    );
  }

  void updatePosition(double nx, double ny) {
    final clampedX = nx.clamp(0.02, 0.98);
    final clampedY = ny.clamp(0.08, 0.92);
    state = state.copyWith(
      normalizedX: clampedX,
      normalizedY: clampedY,
    );
  }

  void snapToNearestEdge(double nx, double ny) {
    // Snap to left edge (0.04) or right edge (0.94)
    final targetX = nx < 0.5 ? 0.04 : 0.94;
    final clampedY = ny.clamp(0.08, 0.92);

    state = state.copyWith(
      normalizedX: targetX,
      normalizedY: clampedY,
    );

    _platformService.updateSystemOverlayPosition(targetX, clampedY);
  }

  void toggleMenu() {
    state = state.copyWith(isMenuOpen: !state.isMenuOpen);
  }

  void closeMenu() {
    if (state.isMenuOpen) {
      state = state.copyWith(isMenuOpen: false);
    }
  }

  void openFloatingNote({String? pageId}) {
    state = state.copyWith(
      isFloatingNoteOpen: true,
      activePageId: pageId,
      isMenuOpen: false,
      isNoteMinimized: false,
    );
  }

  void closeFloatingNote() {
    state = state.copyWith(
      isFloatingNoteOpen: false,
      activePageId: null,
      isNoteMinimized: false,
    );
  }

  void minimizeFloatingNote() {
    state = state.copyWith(
      isNoteMinimized: true,
      isFloatingNoteOpen: false,
    );
  }

  void restoreFloatingNote() {
    state = state.copyWith(
      isNoteMinimized: false,
      isFloatingNoteOpen: true,
      isMenuOpen: false,
    );
  }

  void updateFloatingNotePosition(double nx, double ny) {
    state = state.copyWith(
      floatingNoteNormalizedX: nx.clamp(0.05, 0.95),
      floatingNoteNormalizedY: ny.clamp(0.05, 0.95),
    );
  }

  void updateFloatingNoteSize(double width, double height) {
    state = state.copyWith(
      floatingNoteWidth: math.max(260.0, math.min(600.0, width)),
      floatingNoteHeight: math.max(240.0, math.min(800.0, height)),
    );
  }

  void setVisibility(bool isVisible) {
    state = state.copyWith(isVisible: isVisible);
  }
}

final assistiveBallProvider =
    StateNotifierProvider<AssistiveBallNotifier, AssistiveBallState>((ref) {
  final platformService = ref.watch(assistiveBallPlatformServiceProvider);
  return AssistiveBallNotifier(ref, platformService);
});
