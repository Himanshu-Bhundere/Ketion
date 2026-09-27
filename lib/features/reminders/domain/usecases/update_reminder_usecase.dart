import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/models/reminder_notification_content.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';
import 'package:ketion/features/reminders/presentation/utils/reminder_display_formatter.dart';
import 'package:ketion/features/pages/domain/repositories/page_repository.dart';

import 'package:ketion/features/reminders/domain/services/recurrence_calculator.dart';

class UpdateReminderUseCase {
  final ReminderRepository repository;
  final ReminderScheduler scheduler;
  final PageRepository pageRepository;
  final RecurrenceCalculator recurrenceCalculator;

  UpdateReminderUseCase(
    this.repository,
    this.scheduler,
    this.pageRepository,
    this.recurrenceCalculator,
  );

  Future<void> execute(ReminderEntity reminder) async {
    await repository.updateReminder(reminder);
    if (!reminder.completed && !reminder.deleted) {
      String pageTitle = 'Unknown Page';
      final pageResult = await pageRepository.getPage(reminder.pageId);
      if (pageResult.isSuccess) {
        final page = pageResult.valueOrNull!;
        pageTitle = page.title.isNotEmpty ? page.title : 'Untitled Page';
      }

      final content = ReminderNotificationContent(
        title: reminder.title.isEmpty ? 'Ketion Reminder' : reminder.title,
        body: 'Page: $pageTitle\n${ReminderDisplayFormatter.formatNotificationBody(reminder.reminderTime, recurrenceRule: reminder.recurrenceRule)}',
      );
      
      await scheduler.scheduleReminder(reminder, content: content);
    } else {
      await scheduler.cancelReminder(reminder.id);
    }
  }

  Future<void> markCompleted(String id, bool completed) async {
    final reminder = await repository.getReminder(id);
    if (reminder == null || reminder.deleted) return;

    if (completed) {
      if (reminder.recurrenceRule != null && reminder.recurrenceRule!.isNotEmpty) {
        // Advance recurrence instead of completing
        final nextTime = recurrenceCalculator.nextOccurrence(
          current: reminder.reminderTime,
          rule: reminder.recurrenceRule,
        );

        if (nextTime != null) {
          final advancedReminder = reminder.copyWith(
            reminderTime: nextTime,
            snoozeUntil: null,
            updatedAt: DateTime.now().toUtc(),
          );
          await repository.updateReminder(advancedReminder);
          await _reschedule(advancedReminder);
          return;
        }
      }

      await repository.markCompleted(id, true);
      await scheduler.cancelReminder(id);
    } else {
      await repository.markCompleted(id, false);
      final updatedReminder = await repository.getReminder(id);
      if (updatedReminder != null) {
        await _reschedule(updatedReminder);
      }
    }
  }

  Future<void> _reschedule(ReminderEntity reminder) async {
    String pageTitle = 'Unknown Page';
        final pageResult = await pageRepository.getPage(reminder.pageId);
        if (pageResult.isSuccess) {
          final page = pageResult.valueOrNull!;
          pageTitle = page.title.isNotEmpty ? page.title : 'Untitled Page';
        }

    final content = ReminderNotificationContent(
      title: reminder.title.isEmpty ? 'Ketion Reminder' : reminder.title,
      body: 'Page: $pageTitle\n${ReminderDisplayFormatter.formatNotificationBody(reminder.reminderTime, recurrenceRule: reminder.recurrenceRule)}',
    );
    
    await scheduler.scheduleReminder(reminder, content: content);
  }
}
