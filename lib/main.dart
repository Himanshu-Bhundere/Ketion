import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/bootstrap/app_bootstrap.dart';
import 'package:ketion/core/bootstrap/widget_bootstrap.dart';
import 'package:ketion/core/theme/app_theme.dart';
import 'package:ketion/core/theme/app_colors.dart';
import 'package:ketion/core/router/app_router.dart';
import 'package:ketion/core/router/routes.dart';
import 'package:ketion/features/settings/presentation/providers/settings_providers.dart';
import 'package:ketion/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/core/bootstrap/notification_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppBootstrap.initialize();
  } catch (error, stackTrace) {
    debugPrint('Ketion startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(
    const ProviderScope(
      child: KetionApp(),
    ),
  );
}

class KetionApp extends ConsumerStatefulWidget {
  const KetionApp({super.key});

  @override
  ConsumerState<KetionApp> createState() => _KetionAppState();
}

class _KetionAppState extends ConsumerState<KetionApp>
    with WidgetsBindingObserver {
  Timer? _reminderCleanupTimer;
  bool _isReminderCleanupRunning = false;

  Future<void> _restoreReminderSchedules() async {
    if (kIsWeb) return;

    try {
      final reminders = await ref
          .read(reminderRepositoryProvider)
          .watchAllActiveReminders()
          .first;

      final scheduler = ref.read(reminderSchedulerProvider);

      for (final reminder in reminders) {
        if (reminder.completed || reminder.deleted) {
          continue;
        }

        final effectiveTime =
            reminder.snoozeUntil != null &&
                    reminder.snoozeUntil!.isAfter(DateTime.now())
                ? reminder.snoozeUntil!
                : reminder.reminderTime;

        if (!effectiveTime.isAfter(DateTime.now())) {
          continue;
        }

        final reminderToSchedule = reminder.copyWith(
          reminderTime: effectiveTime,
        );

        try {
          await scheduler.scheduleReminder(reminderToSchedule);
        } catch (error, stackTrace) {
          debugPrint(
            'Failed to restore reminder ${reminder.id}: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Reminder schedule restoration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _cleanupExpiredReminders() async {
    if (_isReminderCleanupRunning) return;

    _isReminderCleanupRunning = true;

    try {
      await ref
          .read(reminderExpiryServiceProvider)
          .cleanupExpiredReminders();
    } catch (error, stackTrace) {
      debugPrint('Reminder expiry cleanup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isReminderCleanupRunning = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetBootstrap.listenToDeepLinks(
      onCreatePage: () async {
        final result = await ref.read(createPageUseCaseProvider)(title: '');
        return result.fold(
          (page) {
            ref.invalidate(recentPagesProvider);
            ref.invalidate(favoritePagesProvider);
            ref.invalidate(pageProvider(page.id));
            return page.id;
          },
          (error) => null,
        );
      },
      onValidatePage: (pageId) async {
        final result = await ref.read(getPageUseCaseProvider)(pageId);
        return result.fold(
          (page) => !page.deleted,
          (error) => false,
        );
      },
    );

    _reminderCleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _cleanupExpiredReminders(),
    );

    // Eagerly connect notification action dispatcher to Riverpod
    Future.microtask(() async {
      ref.read(notificationActionDispatcherProvider);

      await _restoreReminderSchedules();

      await _cleanupExpiredReminders();

      // Handle pending cold-start navigation
      final pending = NotificationBootstrap.pendingNavigation;
      if (pending != null && pending.type == 'alarm') {
        NotificationBootstrap.pendingNavigation = null;
        await appRouter.pushNamed(
          Routes.alarmRingingName,
          pathParameters: {'reminderId': pending.reminderId},
          extra: {'occurrenceTime': pending.occurrenceTime},
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cleanupExpiredReminders();
    }
  }

  @override
  void dispose() {
    _reminderCleanupTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        ThemeMode themeMode = ThemeMode.system;
        if (settings.themeMode == 'Light') {
          themeMode = ThemeMode.light;
        } else if (settings.themeMode == 'Dark') {
          themeMode = ThemeMode.dark;
        }

        return MaterialApp.router(
          title: 'Ketion',
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.getAccentColor(settings.accentColor.name),
            fontSizePreference: settings.fontSize,
            highContrast: settings.highContrast,
            reducedMotion: settings.reducedMotion,
          ),
          darkTheme: AppTheme.getDarkTheme(
            primaryColor: AppColors.getAccentColor(settings.accentColor.name),
            fontSizePreference: settings.fontSize,
            highContrast: settings.highContrast,
            reducedMotion: settings.reducedMotion,
          ),
          themeMode: themeMode,
          routerConfig: appRouter,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Failed to load settings: $err')),
    );
  }
}
