import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/bootstrap/app_bootstrap.dart';
import 'package:ketion/core/bootstrap/widget_bootstrap.dart';
import 'package:ketion/core/theme/app_theme.dart';
import 'package:ketion/core/router/app_router.dart';
import 'package:ketion/features/settings/presentation/providers/settings_providers.dart';

void main() async {
  await AppBootstrap.initialize();

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
    WidgetBootstrap.listenToDeepLinks();
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
