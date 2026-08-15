import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/env_config.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/logger.dart';

void main() {
  // Initialize environment configuration
  EnvConfig.init(environment: 'dev', isProduction: false);

  // Initial startup log
  appLogger.i('Starting Ketion App in ${EnvConfig.instance.environment} environment.');

  runApp(
    const ProviderScope(
      child: KetionApp(),
    ),
  );
}

class KetionApp extends StatelessWidget {
  const KetionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ketion',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
