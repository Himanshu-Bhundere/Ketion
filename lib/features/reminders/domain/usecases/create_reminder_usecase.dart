import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';
import 'package:uuid/uuid.dart';

class CreateReminderUseCase {
  final ReminderRepository repository;
  final ReminderScheduler scheduler;
  final Uuid uuid;

  CreateReminderUseCase(
    this.repository,
    this.scheduler, {
    this.uuid = const Uuid(),
  });

  Future<ReminderEntity> execute({
    required String pageId,
    String? blockId,
    required String title,
    required DateTime reminderTime,
    String timezone = 'UTC',
    String? recurrenceRule,
  }) async {
    final now = DateTime.now().toUtc();
    final reminder = ReminderEntity(
      id: uuid.v7(),
      pageId: pageId,
      blockId: blockId,
      title: title,
      reminderTime: reminderTime,
      timezone: timezone,
      recurrenceRule: recurrenceRule,
      createdAt: now,
      updatedAt: now,
    );

    await repository.addReminder(reminder);
    await scheduler.scheduleReminder(reminder);

    return reminder;
  }
}
