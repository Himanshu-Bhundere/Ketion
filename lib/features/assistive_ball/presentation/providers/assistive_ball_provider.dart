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
    _platformService.onPositionChanged = (x, y) {
      snapToNearestCorner(x, y);
    };

    _platformService.onBallClicked = () {
      if (state.isNoteMinimized) {
        restoreFloatingNote();
      } else {
        toggleMenu();
      }
    };

    _ref.listen(
      appSettingsProvider,
      (previous, next) async {
        final settings = next.valueOrNull;
        if (settings != null) {
          final enabledChanged =
              settings.assistiveBallEnabled != state.isEnabled;
          final posChanged =
              (settings.assistiveBallNormalizedX != state.normalizedX ||
                  settings.assistiveBallNormalizedY != state.normalizedY);

          if (enabledChanged || posChanged) {
            bool enabled = settings.assistiveBallEnabled;

            if (enabled && _platformService.isSystemOverlaySupported) {
              final hasPermission =
                  await _platformService.checkOverlayPermission();
              if (!hasPermission) {
                enabled = false;
                await _ref
                    .read(appSettingsProvider.notifier)
                    .toggleAssistiveBall(false);
              }
            }

            state = state.copyWith(
              isEnabled: enabled,
              isVisible: enabled,
              normalizedX: settings.assistiveBallNormalizedX,
              normalizedY: settings.assistiveBallNormalizedY,
            );
            if (state.isEnabled) {
              await _platformService.showSystemOverlay(
                x: state.normalizedX,
                y: state.normalizedY,
              );
            } else {
              await _platformService.hideSystemOverlay();
            }
          }
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled && _platformService.isSystemOverlaySupported) {
      final hasPermission = await _platformService.checkOverlayPermission();
      if (!hasPermission) {
        final requested = await _platformService.requestOverlayPermission();
        if (!requested) return;
      }

      // Android's settings screen is asynchronous. Recheck after returning
      // to Ketion before persisting the enabled state.
      final permissionGranted = await _platformService.checkOverlayPermission();
      if (!permissionGranted) return;
    }

    final settingsNotifier = _ref.read(appSettingsProvider.notifier);
    await settingsNotifier.toggleAssistiveBall(enabled);

    state = state.copyWith(
      isEnabled: enabled,
      isVisible: enabled,
      isMenuOpen: false,
      isFloatingNoteOpen: false,
      isNoteSelectorOpen: false,
    );

    if (enabled) {
      await _platformService.showSystemOverlay(
        x: state.normalizedX,
        y: state.normalizedY,
      );
    } else {
      await _platformService.hideSystemOverlay();
    }
  }

  void updatePosition(double nx, double ny) {
    final clampedX = nx.clamp(0.02, 0.98);
    final clampedY = ny.clamp(0.02, 0.98);
    state = state.copyWith(
      normalizedX: clampedX,
      normalizedY: clampedY,
    );
  }

  Future<void> snapToNearestCorner(double nx, double ny) async {
    const left = 0.02;
    const right = 0.98;
    const top = 0.02;
    const bottom = 0.98;

    final targetX = nx < 0.5 ? left : right;
    final targetY = ny < 0.5 ? top : bottom;

    state = state.copyWith(
      normalizedX: targetX,
      normalizedY: targetY,
    );

    await _platformService.updateSystemOverlayPosition(
      targetX,
      targetY,
    );

    try {
      await _ref.read(appSettingsProvider.notifier).updateAssistiveBallPosition(
            targetX,
            targetY,
          );
    } catch (_) {}
  }

  void snapToNearestEdge(double nx, double ny) {
    snapToNearestCorner(nx, ny);
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
      isNoteSelectorOpen: false,
      activePageId: pageId,
      isMenuOpen: false,
      isNoteMinimized: false,
    );
  }

  void closeFloatingNote() {
    state = state.copyWith(
      isFloatingNoteOpen: false,
      isNoteSelectorOpen: false,
      activePageId: null,
      isNoteMinimized: false,
    );
  }

  void openNoteSelector() {
    state = state.copyWith(
      isNoteSelectorOpen: true,
      isFloatingNoteOpen: false,
      isMenuOpen: false,
    );
  }

  void closeNoteSelector() {
    state = state.copyWith(
      isNoteSelectorOpen: false,
    );
  }

  void returnToNoteSelector() {
    state = state.copyWith(
      isNoteSelectorOpen: true,
      isFloatingNoteOpen: false,
      activePageId: null,
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
    setEnabled(isVisible);
  }
}

final assistiveBallProvider =
    StateNotifierProvider<AssistiveBallNotifier, AssistiveBallState>((ref) {
  final platformService = ref.watch(assistiveBallPlatformServiceProvider);
  return AssistiveBallNotifier(ref, platformService);
});
