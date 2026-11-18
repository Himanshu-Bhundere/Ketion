import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings_model.freezed.dart';
part 'app_settings_model.g.dart';

enum AccentColor { blue, purple, teal, green, orange, red }

enum FontSizePreference { small, medium, large, extraLarge }

enum EditorAppearance { compact, comfortable, wide, centered }

@freezed
class AppSettingsModel with _$AppSettingsModel {
  const factory AppSettingsModel({
    @Default('System') String themeMode,
    @Default('15 minutes') String syncFrequency,
    @Default(true) bool autoSync,
    @Default(100) int cacheLimitMB,
    @Default(AccentColor.blue) AccentColor accentColor,
    @Default(FontSizePreference.medium) FontSizePreference fontSize,
    @Default(EditorAppearance.comfortable) EditorAppearance editorAppearance,
    @Default(false) bool highContrast,
    @Default(false) bool reducedMotion,
    @Default(false) bool assistiveBallEnabled,
    @Default(1.0) double assistiveBallNormalizedX,
    @Default(1.0) double assistiveBallNormalizedY,
    @Default([
      'bullet_list',
      'heading',
      'image',
      'file',
      'hide_keyboard',
    ])
    List<String> toolbarSymbolOrder,
    DateTime? lastCleanup,
  }) = _AppSettingsModel;

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsModelFromJson(json);
}
