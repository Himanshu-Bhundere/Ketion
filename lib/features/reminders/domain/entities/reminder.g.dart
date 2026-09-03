// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReminderEntityImpl _$$ReminderEntityImplFromJson(Map<String, dynamic> json) =>
    _$ReminderEntityImpl(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      blockId: json['blockId'] as String?,
      title: json['title'] as String? ?? '',
      reminderTime: DateTime.parse(json['reminderTime'] as String),
      timezone: json['timezone'] as String? ?? 'UTC',
      recurrenceRule: json['recurrenceRule'] as String?,
      snoozeUntil: json['snoozeUntil'] == null
          ? null
          : DateTime.parse(json['snoozeUntil'] as String),
      completed: json['completed'] as bool? ?? false,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deleted: json['deleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$ReminderEntityImplToJson(
        _$ReminderEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pageId': instance.pageId,
      'blockId': instance.blockId,
      'title': instance.title,
      'reminderTime': instance.reminderTime.toIso8601String(),
      'timezone': instance.timezone,
      'recurrenceRule': instance.recurrenceRule,
      'snoozeUntil': instance.snoozeUntil?.toIso8601String(),
      'completed': instance.completed,
      'version': instance.version,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deleted': instance.deleted,
    };
