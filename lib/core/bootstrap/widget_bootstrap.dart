import 'dart:async';
import 'package:home_widget/home_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:ketion/core/router/app_router.dart';

class WidgetBootstrap {
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId('group.com.example.ketion');
  }

  static void listenToDeepLinks() {
    HomeWidget.widgetClicked.listen(_launchedFromWidget);
    unawaited(
        HomeWidget.initiallyLaunchedFromHomeWidget().then(_launchedFromWidget));
  }

  static void _launchedFromWidget(Uri? uri) {
    if (uri != null && uri.scheme == 'ketion') {
      if (uri.host == 'new-note' || uri.host == 'quick_note') {
        final newId = const Uuid().v7();
        unawaited(appRouter.push('/editor/$newId'));
      } else if (uri.host == 'note' && uri.pathSegments.isNotEmpty) {
        final pageId = uri.pathSegments.first;
        unawaited(appRouter.push('/editor/$pageId'));
      } else if (uri.host == 'settings') {
        appRouter.push('/settings');
      }
    }
  }
}
