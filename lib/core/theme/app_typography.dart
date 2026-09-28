import 'package:flutter/material.dart';
import '../../features/settings/domain/models/app_settings_model.dart';

/// Canonical typography tokens as defined in the UI architecture.
class AppTypography {
  const AppTypography._();

  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static double _getScaleFactor(FontSizePreference preference) {
    switch (preference) {
      case FontSizePreference.small:
        return 0.85;
      case FontSizePreference.large:
        return 1.15;
      case FontSizePreference.extraLarge:
        return 1.30;
      case FontSizePreference.medium:
        return 1.0;
    }
  }

  static TextTheme getScaledTextTheme(FontSizePreference preference) {
    final scale = _getScaleFactor(preference);
    return TextTheme(
      displayLarge: display.copyWith(fontSize: display.fontSize! * scale),
      headlineMedium: heading.copyWith(fontSize: heading.fontSize! * scale),
      titleMedium: title.copyWith(fontSize: title.fontSize! * scale),
      bodyMedium: body.copyWith(fontSize: body.fontSize! * scale),
      bodySmall: caption.copyWith(fontSize: caption.fontSize! * scale),
    );
  }
}
