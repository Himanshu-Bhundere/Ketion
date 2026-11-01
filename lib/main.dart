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

    // Eagerly connect notification action dispatcher to Riverpod
    Future.microtask(() async {
      ref.read(notificationActionDispatcherProvider);

      try {
        await ref.read(reminderExpiryServiceProvider).cleanupExpiredReminders();
      } catch (e) {
        debugPrint('Error cleaning up expired reminders on startup: $e');
      }

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
      ref
          .read(reminderExpiryServiceProvider)
          .cleanupExpiredReminders()
          .catchError(
        (Object e) {
          debugPrint('Error cleaning up expired reminders on resume: $e');
          return 0;
        },
      );
    }
  }

  @override
  void dispose() {
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
