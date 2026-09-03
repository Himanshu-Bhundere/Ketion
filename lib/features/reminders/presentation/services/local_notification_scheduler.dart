import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  LocalNotificationScheduler(this.flutterLocalNotificationsPlugin);

  @override
  Future<void> scheduleReminder(ReminderEntity reminder) async {
    // Only schedule if the reminder time is in the future
    if (reminder.reminderTime.isBefore(DateTime.now())) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'reminders_channel_id',
      'Reminders',
      channelDescription: 'Notifications for your reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: reminder.id.hashCode,
      title: reminder.title.isEmpty ? 'Ketion Reminder' : reminder.title,
      body: 'You have a reminder scheduled.',
      scheduledDate: tz.TZDateTime.from(reminder.reminderTime, tz.local),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelReminder(String id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id.hashCode);
  }

  @override
  Future<void> cancelAllReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
