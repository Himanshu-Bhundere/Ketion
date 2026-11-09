import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/services/assistive_ball_platform_service.dart';

class AssistiveBallPlatformServiceImpl implements AssistiveBallPlatformService {
  static const MethodChannel _channel =
      MethodChannel('com.example.ketion/assistive_ball');

  @override
  void Function(double x, double y)? onPositionChanged;

  AssistiveBallPlatformServiceImpl() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onPositionChanged') {
      final x = (call.arguments?['x'] as num?)?.toDouble();
      final y = (call.arguments?['y'] as num?)?.toDouble();
      if (x != null && y != null) {
        onPositionChanged?.call(x, y);
      }
    }
  }

  @override
  bool get isSystemOverlaySupported {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.android;
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
