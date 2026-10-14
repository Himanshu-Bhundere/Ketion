import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:ketion/core/router/app_router.dart';
import 'package:ketion/core/router/routes.dart';

class WidgetBootstrap {
  static bool _isCreatingPage = false;

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId('group.com.example.ketion');
  }

  static void listenToDeepLinks({
    Future<String?> Function()? onCreatePage,
    void Function(String error)? onError,
  }) {
    HomeWidget.widgetClicked.listen(
      (uri) => _launchedFromWidget(uri, onCreatePage, onError),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
          if (uri != null) {
            _launchedFromWidget(uri, onCreatePage, onError);
          }
        }),
      );
    });
  }

  @visibleForTesting
  static Future<void> handleDeepLink(
    Uri? uri, [
    Future<String?> Function()? onCreatePage,
    void Function(String error)? onError,
  ]) =>
      _launchedFromWidget(uri, onCreatePage, onError);

  @visibleForTesting
  static Future<void> handleWarmStart(
    Uri? uri, [
    Future<String?> Function()? onCreatePage,
    void Function(String error)? onError,
  ]) =>
      _launchedFromWidget(uri, onCreatePage, onError);

  @visibleForTesting
  static Future<void> handleColdStart([
    Future<String?> Function()? onCreatePage,
    Future<Uri?> Function()? initialUriProvider,
    void Function(String error)? onError,
  ]) async {
    final uri = initialUriProvider != null
        ? await initialUriProvider()
        : await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null) {
      await _launchedFromWidget(uri, onCreatePage, onError);
    }
  }

  static Future<void> _launchedFromWidget(
    Uri? uri, [
    Future<String?> Function()? onCreatePage,
    void Function(String error)? onError,
  ]) async {
    if (uri != null && uri.scheme == 'ketion') {
      if (uri.host == 'new-note' ||
          uri.host == 'quick_note' ||
          uri.host == 'quick-note') {
        if (_isCreatingPage) {
          // Debounce / lock against repeated rapid taps
          return;
        }
        _isCreatingPage = true;
        try {
          String? pageId;
          if (onCreatePage != null) {
            try {
              pageId = await onCreatePage();
            } catch (e) {
              pageId = null;
            }
          }

          if (pageId != null && pageId.isNotEmpty) {
            unawaited(
              appRouter.pushNamed(
                Routes.editorName,
                pathParameters: {'pageId': pageId},
                extra: const {'focusTitle': true},
              ),
            );
          } else {
            // Failed creation: show an error rather than opening a fabricated page ID!
            const errorMsg = 'Failed to create note. Please try again.';
            if (onError != null) {
              onError(errorMsg);
            } else {
              final context = rootNavigatorKey.currentContext;
              if (context != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(errorMsg),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        } finally {
          _isCreatingPage = false;
        }
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
