import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/services/assistive_ball_platform_service.dart';

class AssistiveBallPlatformServiceImpl implements AssistiveBallPlatformService {
  static const MethodChannel _channel =
      MethodChannel('com.example.ketion/assistive_ball');

  @override
  void Function(double x, double y)? onPositionChanged;

  @override
  void Function()? onBallClicked;

  void Function(bool isStandalone)? onOpenQuickNote;
  void Function(bool isStandalone)? onOpenNoteSelector;
  void Function()? onHideOverlay;

  AssistiveBallPlatformServiceImpl() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPositionChanged':
        final x = (call.arguments?['x'] as num?)?.toDouble();
        final y = (call.arguments?['y'] as num?)?.toDouble();
        if (x != null && y != null) {
          onPositionChanged?.call(x, y);
        }
        break;
      case 'onBallClicked':
        onBallClicked?.call();
        break;
      case 'openQuickNote':
        final isStandalone =
            call.arguments is Map && (call.arguments['isStandalone'] == true);
        onOpenQuickNote?.call(isStandalone);
        break;
      case 'openNoteSelector':
        final isStandalone =
            call.arguments is Map && (call.arguments['isStandalone'] == true);
        onOpenNoteSelector?.call(isStandalone);
        break;
      case 'hideOverlay':
        onHideOverlay?.call();
        break;
    }
  }

  Future<void> setOverlayWindowMode({
    required bool enable,
    double width = 440,
    double height = 580,
  }) async {
    if (!isSystemOverlaySupported) return;
    try {
      await _channel.invokeMethod<void>('setOverlayWindowMode', {
        'enable': enable,
        'width': width,
        'height': height,
      });
    } catch (_) {}
  }


  @override
  bool get isSystemOverlaySupported {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  Future<bool> checkOverlayPermission() async {
    if (!isSystemOverlaySupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestOverlayPermission() async {
    if (!isSystemOverlaySupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showSystemOverlay({double? x, double? y}) async {
    if (!isSystemOverlaySupported) return;
    try {
      await _channel.invokeMethod<void>('showOverlay', {
        'x': x,
        'y': y,
      });
    } catch (_) {}
  }

  @override
  Future<void> hideSystemOverlay() async {
    if (!isSystemOverlaySupported) return;
    try {
      await _channel.invokeMethod<void>('hideOverlay');
    } catch (_) {}
  }

  @override
  Future<void> updateSystemOverlayPosition(double x, double y) async {
    if (!isSystemOverlaySupported) return;
    try {
      await _channel.invokeMethod<void>('updatePosition', {
        'x': x,
        'y': y,
      });
    } catch (_) {}
  }
}
