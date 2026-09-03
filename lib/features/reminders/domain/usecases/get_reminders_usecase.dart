import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';

class GetRemindersUseCase {
  final ReminderRepository repository;

  GetRemindersUseCase(this.repository);

  Stream<List<ReminderEntity>> execute(String pageId) {
    return repository.watchRemindersForPage(pageId);
  }

  Stream<List<ReminderEntity>> watchAllActive() {
    return repository.watchAllActiveReminders();
  }
}
