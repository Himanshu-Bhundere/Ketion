import 'package:flutter/material.dart';

/// Centralized presentation formatter for reminder dates and times.
///
/// Replaces the three inconsistent approaches previously used across
/// HomePage, RemindersPage, CreateReminderDialog, and LocalNotificationScheduler.
class ReminderDisplayFormatter {
  /// Locale-aware time formatting: "11:59 AM"
  ///
  /// Uses [MaterialLocalizations] for locale-correct time display.
  static String formatTime(BuildContext context, DateTime dateTime) {
    final local = dateTime.toLocal();
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
    );
  }

  /// Compact due-date label for UI display:
  ///   - Today:    "Due: 11:59 AM"
  ///   - Tomorrow: "Due: Tomorrow • 11:59 AM"
  ///   - Other:    "Due: 21 Sep • 11:59 AM"
  static String formatDueLabel(BuildContext context, DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final reminderDay = DateTime(local.year, local.month, local.day);
    final time = formatTime(context, dateTime);

    if (reminderDay == today) return 'Due: $time';
    if (reminderDay == tomorrow) return 'Due: Tomorrow • $time';
    return 'Due: ${_formatShortDate(local)} • $time';
  }

  /// Notification body text (no BuildContext available):
  ///   - "Due today at 11:59 AM"
  ///   - "Due tomorrow at 11:59 AM"
  ///   - "Due 20 Sep at 11:59 AM"
  ///   - Optionally appends "Repeats daily" etc.
  static String formatNotificationBody(
    DateTime dateTime, {
    String? recurrenceRule,
  }) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final reminderDay = DateTime(local.year, local.month, local.day);
    final time = _formatTimeManual(local);

    String body;
    if (reminderDay == today) {
      body = 'Due today at $time';
    } else if (reminderDay == tomorrow) {
      body = 'Due tomorrow at $time';
    } else {
      body = 'Due ${_formatShortDate(local)} at $time';
    }

    final recurrence = formatRecurrence(recurrenceRule);
    if (recurrence != null) body += '\nRepeats $recurrence';
    return body;
  }

  /// Manual AM/PM formatting without the `intl` dependency.
  static String _formatTimeManual(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:$minute $period';
  }

  /// Short date: "21 Sep"
  static String _formatShortDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  /// Human-readable recurrence rule.
  /// Returns null if no rule or empty.
  static String? formatRecurrence(String? rule) {
    if (rule == null || rule.isEmpty) return null;
    final lower = rule.toLowerCase();
    if (lower.contains('daily')) return 'daily';
    if (lower.contains('weekly')) return 'weekly';
    if (lower.contains('monthly')) return 'monthly';
    return rule; // pass through custom rules
  }
}
