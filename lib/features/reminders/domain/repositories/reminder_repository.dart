import 'package:ketion/features/reminders/domain/entities/reminder.dart';

abstract class ReminderRepository {
  Stream<List<ReminderEntity>> watchRemindersForPage(String pageId);
  Stream<List<ReminderEntity>> watchAllActiveReminders();
  Future<ReminderEntity?> getReminder(String id);
  Future<void> addReminder(ReminderEntity reminder);
  Future<void> updateReminder(ReminderEntity reminder);
  Future<void> deleteReminder(String id);
  Future<void> markCompleted(String id, bool completed);
}
