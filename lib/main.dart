import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/bootstrap/app_bootstrap.dart';
import 'package:ketion/core/bootstrap/widget_bootstrap.dart';
import 'package:ketion/core/theme/app_theme.dart';
import 'package:ketion/core/theme/app_colors.dart';
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
      error: (err, stack) => Center(child: Text('Failed to load settings: $err')),
    );
  }
}
