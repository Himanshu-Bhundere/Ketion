import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:home_widget/home_widget.dart';
import 'core/config/env_config.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment configuration
  EnvConfig.init(environment: 'dev', isProduction: false);

  // Initial startup log
  appLogger.i('Starting Ketion App in ${EnvConfig.instance.environment} environment.');

  HomeWidget.setAppGroupId('group.com.example.ketion');
  
  runApp(
    const ProviderScope(
      child: KetionApp(),
    ),
  );
}

class KetionApp extends StatefulWidget {
  const KetionApp({super.key});

  @override
  State<KetionApp> createState() => _KetionAppState();
}

class _KetionAppState extends State<KetionApp> {
  @override
  void initState() {
    super.initState();
    HomeWidget.widgetClicked.listen(_launchedFromWidget);
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_launchedFromWidget);
  }

  void _launchedFromWidget(Uri? uri) {
    if (uri != null) {
      if (uri.scheme == 'ketion' && uri.host == 'quick_note') {
        final newId = const Uuid().v7();
        appRouter.push('/editor/$newId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ketion',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
