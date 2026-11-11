abstract class AssistiveBallPlatformService {
  bool get isSystemOverlaySupported;
  Future<bool> checkOverlayPermission();
  Future<bool> requestOverlayPermission();
  Future<void> showSystemOverlay({double? x, double? y});
  Future<void> hideSystemOverlay();
  Future<void> updateSystemOverlayPosition(double x, double y);
  void Function(double x, double y)? onPositionChanged;
  void Function()? onBallClicked;
}
