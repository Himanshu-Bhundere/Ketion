// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsModelImpl _$$AppSettingsModelImplFromJson(
        Map<String, dynamic> json) =>
    _$AppSettingsModelImpl(
      themeMode: json['themeMode'] as String? ?? 'System',
      syncFrequency: json['syncFrequency'] as String? ?? '15 minutes',
      autoSync: json['autoSync'] as bool? ?? true,
      cacheLimitMB: (json['cacheLimitMB'] as num?)?.toInt() ?? 100,
      accentColor:
          $enumDecodeNullable(_$AccentColorEnumMap, json['accentColor']) ??
              AccentColor.blue,
      fontSize:
          $enumDecodeNullable(_$FontSizePreferenceEnumMap, json['fontSize']) ??
              FontSizePreference.medium,
      editorAppearance: $enumDecodeNullable(
              _$EditorAppearanceEnumMap, json['editorAppearance']) ??
          EditorAppearance.comfortable,
      highContrast: json['highContrast'] as bool? ?? false,
      reducedMotion: json['reducedMotion'] as bool? ?? false,
      lastCleanup: json['lastCleanup'] == null
          ? null
          : DateTime.parse(json['lastCleanup'] as String),
    );

Map<String, dynamic> _$$AppSettingsModelImplToJson(
        _$AppSettingsModelImpl instance) =>
    <String, dynamic>{
      'themeMode': instance.themeMode,
      'syncFrequency': instance.syncFrequency,
      'autoSync': instance.autoSync,
      'cacheLimitMB': instance.cacheLimitMB,
      'accentColor': _$AccentColorEnumMap[instance.accentColor]!,
      'fontSize': _$FontSizePreferenceEnumMap[instance.fontSize]!,
      'editorAppearance': _$EditorAppearanceEnumMap[instance.editorAppearance]!,
      'highContrast': instance.highContrast,
      'reducedMotion': instance.reducedMotion,
      'lastCleanup': instance.lastCleanup?.toIso8601String(),
    };

const _$AccentColorEnumMap = {
  AccentColor.blue: 'blue',
  AccentColor.purple: 'purple',
  AccentColor.teal: 'teal',
  AccentColor.green: 'green',
  AccentColor.orange: 'orange',
  AccentColor.red: 'red',
};

const _$FontSizePreferenceEnumMap = {
  FontSizePreference.small: 'small',
  FontSizePreference.medium: 'medium',
  FontSizePreference.large: 'large',
  FontSizePreference.extraLarge: 'extraLarge',
};

const _$EditorAppearanceEnumMap = {
  EditorAppearance.compact: 'compact',
  EditorAppearance.comfortable: 'comfortable',
  EditorAppearance.wide: 'wide',
  EditorAppearance.centered: 'centered',
};
