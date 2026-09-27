import 'package:ketion/features/reminders/domain/models/reminder_recurrence.dart';

class RecurrenceCalculator {
  /// Calculates the next occurrence for a reminder, preserving local wall-clock time
  /// across timezone and DST transitions.
  DateTime? nextOccurrence({
    required DateTime current,
    required String? rule,
  }) {
    final recurrence = parseRecurrenceRule(rule);
    if (recurrence == null) return null;

    // Convert stored UTC to local time for calculation
    final currentLocal = current.toLocal();
    DateTime nextLocal;

    switch (recurrence) {
      case ReminderRecurrence.daily:
        // Adding 1 day via constructor handles DST safely compared to Duration(days: 1)
        nextLocal = DateTime(
          currentLocal.year,
          currentLocal.month,
          currentLocal.day + 1,
          currentLocal.hour,
          currentLocal.minute,
          currentLocal.second,
          currentLocal.millisecond,
          currentLocal.microsecond,
        );
        break;

      case ReminderRecurrence.weekly:
        nextLocal = DateTime(
          currentLocal.year,
          currentLocal.month,
          currentLocal.day + 7,
          currentLocal.hour,
          currentLocal.minute,
          currentLocal.second,
          currentLocal.millisecond,
          currentLocal.microsecond,
        );
        break;

      case ReminderRecurrence.monthly:
        nextLocal = _addMonthSafely(currentLocal);
        break;
    }

    // Convert back to UTC for persistence
    return nextLocal.toUtc();
  }

  DateTime _addMonthSafely(DateTime date) {
    final nextMonth = date.month == 12 ? 1 : date.month + 1;
    final nextYear = date.month == 12 ? date.year + 1 : date.year;

    final lastDayOfNextMonth = DateTime(
      nextYear,
      nextMonth + 1,
      0, 
    ).day;

    final nextDay = date.day > lastDayOfNextMonth ? lastDayOfNextMonth : date.day;

    return DateTime(
      nextYear,
      nextMonth,
      nextDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}
