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

  @visibleForTesting
  static Future<void> handleWarmStart(
    Uri? uri, [
    Future<String?> Function()? onCreatePage,
  ]) =>
      _launchedFromWidget(uri, onCreatePage);

  @visibleForTesting
  static Future<void> handleColdStart([
    Future<String?> Function()? onCreatePage,
    Future<Uri?> Function()? initialUriProvider,
  ]) async {
    final uri = initialUriProvider != null
        ? await initialUriProvider()
        : await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null) {
      await _launchedFromWidget(uri, onCreatePage);
    }
  }

  static Future<void> _launchedFromWidget(
    Uri? uri, [
    Future<String?> Function()? onCreatePage,
  ]) async {
    if (uri != null && uri.scheme == 'ketion') {
      if (uri.host == 'new-note' ||
          uri.host == 'quick_note' ||
          uri.host == 'quick-note') {
        final pageId = (onCreatePage != null ? await onCreatePage() : null) ??
            const Uuid().v7();
        unawaited(
          appRouter.pushNamed(
            Routes.editorName,
            pathParameters: {'pageId': pageId},
            extra: const {'focusTitle': true},
          ),
        );
      } else if ((uri.host == 'note' || uri.host == 'page') &&
          uri.pathSegments.isNotEmpty) {
        final pageId = uri.pathSegments.first.trim();
        // Ignore invalid / empty note IDs
        if (pageId.isEmpty || pageId == 'null' || pageId == 'undefined') {
          return;
        }
        unawaited(
          appRouter.pushNamed(
            Routes.editorName,
            pathParameters: {'pageId': pageId},
          ),
        );
      } else if (uri.host == 'settings') {
        if (uri.pathSegments.contains('sync') || uri.path == '/sync') {
          unawaited(appRouter.push(Routes.settingsSync));
        } else {
          unawaited(appRouter.push(Routes.settings));
        }
      }
    }
  }
}
