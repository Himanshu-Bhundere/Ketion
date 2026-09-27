import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/models/reminder_notification_content.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';
import 'dart:convert';
import 'package:ketion/features/reminders/domain/models/reminder_kind.dart';
import 'package:ketion/features/reminders/presentation/utils/reminder_display_formatter.dart';
import 'package:timezone/timezone.dart' as tz;

int notificationIdFor(String id) {
  // Stable FNV-1a hash
  int hash = 0x811c9dc5;
  for (int i = 0; i < id.length; i++) {
    hash ^= id.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

class LocalNotificationScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  LocalNotificationScheduler(this.flutterLocalNotificationsPlugin);

  @override
  Future<void> scheduleReminder(ReminderEntity reminder, {ReminderNotificationContent? content}) async {
    // Only schedule if the reminder time is in the future
    if (reminder.reminderTime.isBefore(DateTime.now())) {
      return;
    }

    if (Platform.isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Request permissions for Android 13+
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
        
        // Request full-screen intent permission for Android 14+
        try {
          await androidPlugin.requestFullScreenIntentPermission();
        } catch (e) {
          // Method might not be available or fails on older Android versions/plugins.
        }
      }
    } else if (Platform.isIOS) {
      final iosPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }

    const reminderAndroidDetails = AndroidNotificationDetails(
      'reminders_channel_id',
      'Reminders',
      channelDescription: 'Notifications for your reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('complete', 'Complete'),
        AndroidNotificationAction('snooze', 'Snooze'),
      ],
    );

    const alarmAndroidDetails = AndroidNotificationDetails(
      'ketion_alarms_v3',
      'Alarms',
      channelDescription: 'Full-screen alarms',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('snooze', 'Snooze'),
      ],
    );

    const iOSDetails = DarwinNotificationDetails(
      categoryIdentifier: 'reminder_actions',
    );

    final notificationDetails = NotificationDetails(
      android: reminder.kind == ReminderKind.alarm ? alarmAndroidDetails : reminderAndroidDetails,
      iOS: iOSDetails,
    );
    
    final payload = jsonEncode({
      'id': reminder.id,
      'type': reminder.kind.name,
      'occurrenceTime': reminder.reminderTime.toIso8601String(),
    });

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: notificationIdFor(reminder.id),
      title: content?.title ?? (reminder.title.isEmpty ? 'Ketion Reminder' : reminder.title),
      body: content?.body ?? ReminderDisplayFormatter.formatNotificationBody(
        reminder.reminderTime,
        recurrenceRule: reminder.recurrenceRule,
      ),
      payload: payload,
      scheduledDate: tz.TZDateTime.from(reminder.reminderTime, tz.local),
      notificationDetails: notificationDetails,
      androidScheduleMode: reminder.kind == ReminderKind.alarm 
          ? AndroidScheduleMode.alarmClock 
          : AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelReminder(String id) async {
    await flutterLocalNotificationsPlugin.cancel(id: notificationIdFor(id));
  }

  @override
  Future<void> cancelAllReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
