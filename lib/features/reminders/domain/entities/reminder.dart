// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/reminder_kind.dart';

part 'reminder.freezed.dart';
part 'reminder.g.dart';

@freezed
class ReminderEntity with _$ReminderEntity {
  const factory ReminderEntity({
    required String id,
    required String pageId,
    String? blockId,
    @Default('') String title,
    required DateTime reminderTime,
    @Default('UTC') String timezone,
    @JsonKey(defaultValue: ReminderKind.reminder, unknownEnumValue: ReminderKind.reminder)
    @Default(ReminderKind.reminder) ReminderKind kind,
    String? recurrenceRule,
    DateTime? snoozeUntil,
    @Default(false) bool completed,
    @Default(1) int version,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool deleted,
  }) = _ReminderEntity;

  factory ReminderEntity.fromJson(Map<String, dynamic> json) =>
      _$ReminderEntityFromJson(json);
}
