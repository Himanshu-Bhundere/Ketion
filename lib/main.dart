import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'core/config/env_config.dart';
import 'core/utils/result.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/logger.dart';
import 'features/sync/presentation/providers/sync_providers.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    EnvConfig.init(environment: 'dev', isProduction: false);
    final container = ProviderContainer();
    final syncNowUseCase = container.read(syncNowUseCaseProvider);
    
    try {
      final res = await syncNowUseCase();
      return res is Success;
    } catch (e) {
      appLogger.e('Background sync failed: $e');
      return false;
    } finally {
      container.dispose();
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  EnvConfig.init(environment: 'dev', isProduction: false);

  // Initial startup log
  appLogger.i(
    'Starting Ketion App in ${EnvConfig.instance.environment} environment.',
  );

  await HomeWidget.setAppGroupId('group.com.example.ketion');
  
  await Workmanager().initialize(
    callbackDispatcher,
  );
  
  await Workmanager().registerPeriodicTask(
    'syncTask',
    'sync_now',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

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

class _KetionAppState extends ConsumerState<KetionApp> {
  @override
  void initState() {
    super.initState();
    HomeWidget.widgetClicked.listen(_launchedFromWidget);
    unawaited(HomeWidget.initiallyLaunchedFromHomeWidget().then(_launchedFromWidget));
  }

  void _launchedFromWidget(Uri? uri) {
    if (uri != null && uri.scheme == 'ketion') {
      if (uri.host == 'new-note' || uri.host == 'quick_note') {
        final newId = const Uuid().v7();
        unawaited(appRouter.push('/editor/$newId'));
      } else if (uri.host == 'note' && uri.pathSegments.isNotEmpty) {
        final pageId = uri.pathSegments.first;
        unawaited(appRouter.push('/editor/$pageId'));
      } else if (uri.host == 'settings') {
        // Sync status widget tap -> opens settings
        appRouter.push('/settings');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    
    ThemeMode themeMode = ThemeMode.system;
    settingsAsync.whenData((settings) {
      if (settings.themeMode == 'Light') {
        themeMode = ThemeMode.light;
      } else if (settings.themeMode == 'Dark') {
        themeMode = ThemeMode.dark;
      }
    });

    return MaterialApp.router(
      title: 'Ketion',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
