import 'package:ketion/features/reminders/domain/entities/reminder.dart';

abstract class ReminderScheduler {
  Future<void> scheduleReminder(ReminderEntity reminder);
  Future<void> cancelReminder(String id);
  Future<void> cancelAllReminders();
}
