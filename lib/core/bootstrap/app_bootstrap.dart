import 'package:flutter/widgets.dart';
import 'package:ketion/core/config/env_config.dart';
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/core/bootstrap/widget_bootstrap.dart';
import 'package:ketion/core/bootstrap/background_bootstrap.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    EnvConfig.init(environment: 'dev', isProduction: false);
    appLogger.i(
      'Starting Ketion App in ${EnvConfig.instance.environment} environment.',
    );

    await WidgetBootstrap.initialize();
    await BackgroundBootstrap.initialize();
  }
}
