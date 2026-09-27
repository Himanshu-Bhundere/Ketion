import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';
import 'package:ketion/core/utils/logger.dart';

class SnoozeReminderUseCase {
  final ReminderRepository repository;
  final ReminderScheduler scheduler;

  SnoozeReminderUseCase({
    required this.repository,
    required this.scheduler,
  });

  Future<void> execute({
    required String reminderId,
    required DateTime? occurrenceTime,
  }) async {
    final reminder = await repository.getReminder(reminderId);
    if (reminder == null) return;
    
    if (occurrenceTime != null && reminder.reminderTime != occurrenceTime) {
      appLogger.d('SnoozeReminderUseCase: Stale event for $reminderId. Ignoring snooze.');
      return;
    }

    final snoozeUntil = DateTime.now().add(const Duration(minutes: 10));
    final snoozed = reminder.copyWith(
      snoozeUntil: snoozeUntil,
      updatedAt: DateTime.now().toUtc(),
    );

    // Persist the snooze metadata
    await repository.updateReminder(snoozed);

    // Schedule a new notification at the snooze time.
    await scheduler.scheduleReminder(
      snoozed.copyWith(reminderTime: snoozeUntil),
    );
  }
}
