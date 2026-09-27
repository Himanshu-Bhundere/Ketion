import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';

class ReminderSnoozeReconciler {
  final ReminderRepository repository;

  ReminderSnoozeReconciler(this.repository);

  /// Reconciles expired snoozes by setting `snoozeUntil` to null.
  /// Returns the updated list of reminders.
  Future<List<ReminderEntity>> reconcileExpiredSnoozes(List<ReminderEntity> reminders) async {
    final now = DateTime.now();
    final updatedList = <ReminderEntity>[];

    for (final reminder in reminders) {
      if (reminder.snoozeUntil != null && reminder.snoozeUntil!.isBefore(now)) {
        final cleared = reminder.copyWith(snoozeUntil: null, updatedAt: now.toUtc());
        await repository.updateReminder(cleared);
        updatedList.add(cleared);
      } else {
        updatedList.add(reminder);
      }
    }
    return updatedList;
  }
}
