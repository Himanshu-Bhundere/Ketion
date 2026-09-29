import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

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
    String? timezone,
    String? recurrenceRule,
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
      createdAt: now,
      updatedAt: now,
    );

    await repository.addReminder(reminder);
    await scheduler.scheduleReminder(reminder);

    return reminder;
  }
}
