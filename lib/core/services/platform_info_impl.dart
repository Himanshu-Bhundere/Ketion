import 'package:flutter/foundation.dart';
import 'platform_info.dart';

class PlatformInfoImpl implements PlatformInfo {
  @override
  bool get isWeb => kIsWeb;

  @override
  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  bool get isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  bool get isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
}
