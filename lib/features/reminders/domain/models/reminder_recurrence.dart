enum ReminderRecurrence {
  daily,
  weekly,
  monthly,
}

ReminderRecurrence? parseRecurrenceRule(String? value) {
  if (value == null) return null;
  switch (value.toUpperCase()) {
    case 'DAILY':
      return ReminderRecurrence.daily;
    case 'WEEKLY':
      return ReminderRecurrence.weekly;
    case 'MONTHLY':
      return ReminderRecurrence.monthly;
    default:
      return null;
  }
}

String? serializeRecurrenceRule(ReminderRecurrence? recurrence) {
  if (recurrence == null) return null;
  switch (recurrence) {
    case ReminderRecurrence.daily:
      return 'DAILY';
    case ReminderRecurrence.weekly:
      return 'WEEKLY';
    case ReminderRecurrence.monthly:
      return 'MONTHLY';
  }
}
