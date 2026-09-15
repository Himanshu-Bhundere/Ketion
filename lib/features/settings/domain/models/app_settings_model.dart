import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings_model.freezed.dart';
part 'app_settings_model.g.dart';

@freezed
class AppSettingsModel with _$AppSettingsModel {
  const factory AppSettingsModel({
    @Default('System') String themeMode,
    @Default('15 minutes') String syncFrequency,
    @Default(true) bool autoSync,
    @Default(100) int cacheLimitMB,
    @Default(30) int tombstoneRetentionDays,
    DateTime? lastCleanup,
  }) = _AppSettingsModel;

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsModelFromJson(json);
}
