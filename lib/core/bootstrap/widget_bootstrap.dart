import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:ketion/core/router/app_router.dart';
import 'package:ketion/core/router/routes.dart';

class WidgetBootstrap {
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId('group.com.example.ketion');
  }

  static void listenToDeepLinks({Future<String?> Function()? onCreatePage}) {
    HomeWidget.widgetClicked.listen((uri) => _launchedFromWidget(uri, onCreatePage));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
          if (uri != null) {
            _launchedFromWidget(uri, onCreatePage);
          }
        }),
      );
    });
  }

  @visibleForTesting
  static Future<void> handleDeepLink(
    Uri? uri, [
    Future<String?> Function()? onCreatePage,
  ]) =>
      _launchedFromWidget(uri, onCreatePage);

  static Future<void> _launchedFromWidget(
    Uri? uri, [
    Future<String?> Function()? onCreatePage,
  ]) async {
    if (uri != null && uri.scheme == 'ketion') {
      if (uri.host == 'new-note' || uri.host == 'quick_note') {
        final pageId = (onCreatePage != null ? await onCreatePage() : null) ??
            const Uuid().v7();
        unawaited(
          appRouter.pushNamed(
            Routes.editorName,
            pathParameters: {'pageId': pageId},
            extra: const {'focusTitle': true},
          ),
        );
      } else if (uri.host == 'note' && uri.pathSegments.isNotEmpty) {
        final pageId = uri.pathSegments.first;
        unawaited(
          appRouter.pushNamed(
            Routes.editorName,
            pathParameters: {'pageId': pageId},
          ),
        );
      } else if (uri.host == 'settings') {
        unawaited(appRouter.push(Routes.settings));
      }
    }
  }
}
