import 'package:drift/drift.dart' as drift;
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/reminders/domain/entities/reminder.dart';

class ReminderMapper {
  static ReminderEntity fromDb(Reminder reminder) {
    return ReminderEntity(
      id: reminder.id,
      pageId: reminder.pageId,
      blockId: reminder.blockId,
      title: reminder.title,
      reminderTime: reminder.reminderTime,
      timezone: reminder.timezone,
      recurrenceRule: reminder.recurrenceRule,
      snoozeUntil: reminder.snoozeUntil,
      completed: reminder.completed,
      version: reminder.version,
      createdAt: reminder.createdAt,
      updatedAt: reminder.updatedAt,
      deleted: reminder.deleted,
    );
  }

  static RemindersCompanion toDbCompanion(ReminderEntity entity) {
    return RemindersCompanion(
      id: drift.Value(entity.id),
      pageId: drift.Value(entity.pageId),
      blockId: drift.Value(entity.blockId),
      title: drift.Value(entity.title),
      reminderTime: drift.Value(entity.reminderTime),
      timezone: drift.Value(entity.timezone),
      recurrenceRule: drift.Value(entity.recurrenceRule),
      snoozeUntil: drift.Value(entity.snoozeUntil),
      completed: drift.Value(entity.completed),
      version: drift.Value(entity.version),
      createdAt: drift.Value(entity.createdAt),
      updatedAt: drift.Value(entity.updatedAt),
      deleted: drift.Value(entity.deleted),
    );
  }
}
