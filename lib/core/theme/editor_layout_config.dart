import 'package:flutter/material.dart';
import '../../features/settings/domain/models/app_settings_model.dart';

class EditorLayoutConfig {
  final double contentWidth;
  final EdgeInsets padding;
  final double lineSpacing;

  const EditorLayoutConfig({
    required this.contentWidth,
    required this.padding,
    required this.lineSpacing,
  });

  factory EditorLayoutConfig.fromAppearance(EditorAppearance appearance) {
    switch (appearance) {
      case EditorAppearance.compact:
        return const EditorLayoutConfig(
          contentWidth: 800,
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          lineSpacing: 1.2,
        );
      case EditorAppearance.wide:
        return const EditorLayoutConfig(
          contentWidth: 1200,
          padding: EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
          lineSpacing: 1.6,
        );
      case EditorAppearance.centered:
        return const EditorLayoutConfig(
          contentWidth: 600,
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          lineSpacing: 1.5,
        );
      case EditorAppearance.comfortable:
        return const EditorLayoutConfig(
          contentWidth: 800,
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          lineSpacing: 1.5,
        );
    }
  }
}
