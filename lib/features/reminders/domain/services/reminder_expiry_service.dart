import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';

class ReminderExpiryService {
  final ReminderRepository _repository;
  final ReminderScheduler? _scheduler;

  ReminderExpiryService(this._repository, [this._scheduler]);

  /// Scans all active reminders and deletes any one-shot, non-snoozed reminders
  /// that fired at least 5 minutes ago.
  ///
  /// Returns the number of expired reminders deleted.
  Future<int> cleanupExpiredReminders({DateTime? now}) async {
    final nowUtc = (now ?? DateTime.now()).toUtc();
    final activeReminders = await _repository.watchAllActiveReminders().first;
    int expiredCount = 0;

    final scheduler = _scheduler;
    for (final reminder in activeReminders) {
      if (isExpired(reminder, now: nowUtc)) {
        await _repository.deleteReminder(reminder.id);
        if (scheduler != null) {
          await scheduler.cancelReminder(reminder.id);
        }
        expiredCount++;
      }
    }

    return expiredCount;
  }

  /// Determines whether a reminder is expired and eligible for deletion.
  ///
  /// A reminder is expired if:
  /// 1. It is not already deleted or completed.
  /// 2. It is not recurring (one-shot).
  /// 3. It is not currently snoozed into the future.
  /// 4. Its effective fire time (snoozeUntil or reminderTime) was at least
  ///    5 minutes ago (UTC).
  bool isExpired(ReminderEntity reminder, {DateTime? now}) {
    if (reminder.deleted || reminder.completed) {
      return false;
    }

    // Recurring reminders must not be deleted.
    if (reminder.recurrenceRule != null &&
        reminder.recurrenceRule!.trim().isNotEmpty) {
      return false;
    }

    final nowUtc = (now ?? DateTime.now()).toUtc();

    // If currently snoozed to a future time, it is not expired.
    if (reminder.snoozeUntil != null) {
      final snoozeUtc = reminder.snoozeUntil!.toUtc();
      if (snoozeUtc.isAfter(nowUtc)) {
        return false;
      }
    }

    final effectiveFiredTime =
        (reminder.snoozeUntil ?? reminder.reminderTime).toUtc();

    return nowUtc.difference(effectiveFiredTime) >= const Duration(minutes: 5);
  }
}
