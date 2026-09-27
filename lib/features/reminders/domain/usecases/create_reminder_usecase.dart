import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/models/reminder_notification_content.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';
import 'package:ketion/features/reminders/presentation/utils/reminder_display_formatter.dart';
import 'package:ketion/features/pages/domain/repositories/page_repository.dart';
import 'package:ketion/features/reminders/domain/models/reminder_kind.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class CreateReminderUseCase {
  final ReminderRepository repository;
  final ReminderScheduler scheduler;
  final PageRepository pageRepository;
  final Uuid uuid;

  CreateReminderUseCase(
    this.repository,
    this.scheduler,
    this.pageRepository, {
    this.uuid = const Uuid(),
  });

  Future<ReminderEntity> execute({
    required String pageId,
    String? blockId,
    required String title,
    required DateTime reminderTime,
    String? timezone,
    String? recurrenceRule,
    ReminderKind kind = ReminderKind.reminder,
  }) async {
    if (timezone == null || timezone == 'UTC') {
      try {
        final localTz = await FlutterTimezone.getLocalTimezone();
        // Handle both cases where it might be a string or an object with an identifier.
        timezone = (localTz as dynamic).toString();
      } catch (e) {
        timezone = 'UTC';
      }
    }
    final now = DateTime.now().toUtc();
    final reminder = ReminderEntity(
      id: uuid.v7(),
      pageId: pageId,
      blockId: blockId,
      title: title,
      reminderTime: reminderTime,
      timezone: timezone,
      recurrenceRule: recurrenceRule,
      kind: kind,
      createdAt: now,
      updatedAt: now,
    );

    await repository.addReminder(reminder);
    
    String pageTitle = 'Unknown Page';
    final pageResult = await pageRepository.getPage(pageId);
    if (pageResult.isSuccess) {
      final page = pageResult.valueOrNull!;
      pageTitle = page.title.isNotEmpty ? page.title : 'Untitled Page';
    }

    final content = ReminderNotificationContent(
      title: title.isEmpty ? 'Ketion Reminder' : title,
      body: 'Page: $pageTitle\n${ReminderDisplayFormatter.formatNotificationBody(reminder.reminderTime, recurrenceRule: reminder.recurrenceRule)}',
    );
    
    await scheduler.scheduleReminder(reminder, content: content);

    return reminder;
  }
}
