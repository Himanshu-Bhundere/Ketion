import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:convert';
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/features/reminders/presentation/services/notification_action_dispatcher.dart';
import 'package:ketion/core/router/app_router.dart';
import 'package:ketion/core/router/routes.dart';

class PendingNotificationNavigation {
  final String reminderId;
  final String type;
  final DateTime? occurrenceTime;

  PendingNotificationNavigation({
    required this.reminderId,
    required this.type,
    this.occurrenceTime,
  });
}

class NotificationBootstrap {
  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static PendingNotificationNavigation? pendingNavigation;

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      final String currentTimeZone =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(currentTimeZone));

      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        notificationCategories: [
          DarwinNotificationCategory(
            'reminder_actions',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('complete', 'Complete'),
              DarwinNotificationAction.plain('snooze', 'Snooze'),
            ],
          ),
        ],
      );
      final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await plugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final notificationAppLaunchDetails = await plugin.getNotificationAppLaunchDetails();
      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final response = notificationAppLaunchDetails!.notificationResponse;
        if (response != null) {
          _handleInitialResponse(response);
        }
      }
    } catch (e) {
      appLogger.e('Failed to initialize notifications: $e');
    }
  }

  static void _onNotificationResponse(NotificationResponse response) {
    String reminderId = response.payload ?? '';
    DateTime? occurrenceTime;
    String type = 'reminder';

    if (response.payload != null && response.payload!.startsWith('{')) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        reminderId = data['id'] as String;
        occurrenceTime = data['occurrenceTime'] != null
            ? DateTime.tryParse(data['occurrenceTime'] as String)
            : null;
        type = data['type'] as String? ?? 'reminder';
      } catch (e) {
        appLogger.w('Failed to parse notification payload: $e');
      }
    }

    if (response.actionId == null && type == 'alarm') {
      appRouter.pushNamed(
        Routes.alarmRingingName,
        pathParameters: {'reminderId': reminderId},
        extra: {'occurrenceTime': occurrenceTime},
      );
      return;
    }

    NotificationActionDispatcher.instance?.handleAction(
      actionId: response.actionId,
      payload: reminderId,
      occurrenceTime: occurrenceTime,
    );
  }

  static void _handleInitialResponse(NotificationResponse response) {
    final payloadStr = response.payload;
    if (payloadStr != null) {
      try {
        final data = jsonDecode(payloadStr) as Map<String, dynamic>;
        pendingNavigation = PendingNotificationNavigation(
          reminderId: data['id'] as String,
          type: data['type'] as String,
          occurrenceTime: data['occurrenceTime'] != null
              ? DateTime.parse(data['occurrenceTime'] as String)
              : null,
        );
      } catch (e) {
        // Fallback for old payloads (before symmetric payload)
        pendingNavigation = PendingNotificationNavigation(
          reminderId: payloadStr,
          type: 'reminder',
        );
      }
    }
  }
}
