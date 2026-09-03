import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';

class UpdateReminderUseCase {
  final ReminderRepository repository;
  final ReminderScheduler scheduler;

  UpdateReminderUseCase(this.repository, this.scheduler);

  Future<void> execute(ReminderEntity reminder) async {
    await repository.updateReminder(reminder);
    if (!reminder.completed && !reminder.deleted) {
      await scheduler.scheduleReminder(reminder);
    } else {
      await scheduler.cancelReminder(reminder.id);
    }
  }

  Future<void> markCompleted(String id, bool completed) async {
    await repository.markCompleted(id, completed);
    if (completed) {
      await scheduler.cancelReminder(id);
    } else {
      final reminder = await repository.getReminder(id);
      if (reminder != null && !reminder.deleted) {
        await scheduler.scheduleReminder(reminder);
      }
    }
  }
}
