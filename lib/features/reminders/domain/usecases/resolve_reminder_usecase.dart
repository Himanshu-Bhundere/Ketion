import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/domain/services/recurrence_calculator.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';
import 'package:ketion/features/reminders/domain/usecases/delete_reminder_usecase.dart';
import 'package:ketion/features/reminders/domain/usecases/update_reminder_usecase.dart';
import 'package:ketion/features/reminders/domain/models/reminder_kind.dart';
import 'package:ketion/core/utils/logger.dart';

enum ReminderResolutionAction { complete, dismiss }

class ResolveReminderUseCase {
  final ReminderRepository repository;
  final ReminderScheduler scheduler;
  final RecurrenceCalculator recurrenceCalculator;
  final DeleteReminderUseCase deleteUseCase;
  final UpdateReminderUseCase updateUseCase;

  ResolveReminderUseCase({
    required this.repository,
    required this.scheduler,
    required this.recurrenceCalculator,
    required this.deleteUseCase,
    required this.updateUseCase,
  });

  Future<void> execute({
    required String reminderId,
    required ReminderResolutionAction action,
    required DateTime? occurrenceTime,
  }) async {
    final reminder = await repository.getReminder(reminderId);
    if (reminder == null || reminder.deleted) {
      appLogger.d('ResolveReminderUseCase: Reminder $reminderId not found or already deleted');
      return;
    }

    // Stale Event Protection
    // Note: If occurrenceTime is null (e.g. from legacy actions without payload), we bypass the check
    if (occurrenceTime != null && reminder.reminderTime != occurrenceTime) {
      appLogger.d('ResolveReminderUseCase: Stale event for $reminderId. Expected: ${reminder.reminderTime}, Got: $occurrenceTime');
      // Just cancel the stale OS notification
      await scheduler.cancelReminder(reminderId);
      return;
    }

    // Validate Action Compatibility
    if (action == ReminderResolutionAction.complete && reminder.kind == ReminderKind.alarm) {
      appLogger.w('ResolveReminderUseCase: Cannot "complete" an alarm. Treating as dismiss.');
      action = ReminderResolutionAction.dismiss;
    } else if (action == ReminderResolutionAction.dismiss && reminder.kind == ReminderKind.reminder) {
      appLogger.w('ResolveReminderUseCase: Cannot "dismiss" a reminder via this usecase. Treating as complete.');
      action = ReminderResolutionAction.complete;
    }

    if (reminder.recurrenceRule != null) {
      // Advance to next recurrence
      final nextTime = recurrenceCalculator.nextOccurrence(
        current: reminder.reminderTime,
        rule: reminder.recurrenceRule,
      );
      
      if (nextTime != null) {
        final updatedReminder = reminder.copyWith(
          reminderTime: nextTime,
          snoozeUntil: null,
          updatedAt: DateTime.now().toUtc(),
        );
        await updateUseCase.execute(updatedReminder);
      } else {
        await deleteUseCase.execute(reminderId);
      }
    } else {
      // One-shot: soft delete and cancel OS notification
      // Both complete and dismiss map to soft-delete/cancel for one-shot
      await deleteUseCase.execute(reminderId);
    }
  }
}
