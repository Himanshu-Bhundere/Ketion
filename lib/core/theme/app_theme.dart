import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'motion_config.dart';

import '../../features/settings/domain/models/app_settings_model.dart';

/// Centralized application theme configurations.
class AppTheme {
  const AppTheme._();

  static ThemeData getLightTheme({
    Color? primaryColor,
    FontSizePreference fontSizePreference = FontSizePreference.medium,
    bool highContrast = false,
    bool reducedMotion = false,
  }) {
    final colorScheme = highContrast
        ? ColorScheme.highContrastLight(
            primary: primaryColor ?? AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surfaceLight,
            error: AppColors.error,
          )
        : ColorScheme.light(
            primary: primaryColor ?? AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surfaceLight,
            error: AppColors.error,
            onPrimary: Colors.white,
            onSecondary: Colors.black,
            onSurface: AppColors.textPrimaryLight,
            onError: Colors.white,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      pageTransitionsTheme: MotionConfig.getPageTransitionsTheme(reducedMotion),
      textTheme: AppTypography.getScaledTextTheme(fontSizePreference).apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),
    );
  }

  static ThemeData getDarkTheme({
    Color? primaryColor,
    FontSizePreference fontSizePreference = FontSizePreference.medium,
    bool highContrast = false,
    bool reducedMotion = false,
  }) {
    final colorScheme = highContrast
        ? ColorScheme.highContrastDark(
            primary: primaryColor ?? AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surfaceDark,
            error: AppColors.error,
          )
        : ColorScheme.dark(
            primary: primaryColor ?? AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surfaceDark,
            error: AppColors.error,
            onPrimary: Colors.white,
            onSecondary: Colors.black,
            onSurface: AppColors.textPrimaryDark,
            onError: Colors.white,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      pageTransitionsTheme: MotionConfig.getPageTransitionsTheme(reducedMotion),
      textTheme: AppTypography.getScaledTextTheme(fontSizePreference).apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
    );
  }
}
