import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/models/reminder_notification_content.dart';

abstract class ReminderScheduler {
  Future<void> scheduleReminder(ReminderEntity reminder, {ReminderNotificationContent? content});
  Future<void> cancelReminder(String id);
  Future<void> cancelAllReminders();
}
