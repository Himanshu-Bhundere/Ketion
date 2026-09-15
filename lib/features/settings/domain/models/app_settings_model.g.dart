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
      tombstoneRetentionDays:
          (json['tombstoneRetentionDays'] as num?)?.toInt() ?? 30,
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
      'tombstoneRetentionDays': instance.tombstoneRetentionDays,
      'lastCleanup': instance.lastCleanup?.toIso8601String(),
    };
