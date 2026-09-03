import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';

class DeleteReminderUseCase {
  final ReminderRepository repository;
  final ReminderScheduler scheduler;

  DeleteReminderUseCase(this.repository, this.scheduler);

  Future<void> execute(String id) async {
    await repository.deleteReminder(id);
    await scheduler.cancelReminder(id);
  }
}
