import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:ketion/core/router/app_router.dart';
import 'package:ketion/core/router/routes.dart';

class WidgetBootstrap {
  static bool _isCreatingPage = false;

  static Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    await HomeWidget.setAppGroupId('group.com.example.ketion');
  }

  static void listenToDeepLinks({
    Future<String?> Function()? onCreatePage,
    Future<bool> Function(String pageId)? onValidatePage,
    void Function(String error)? onError,
  }) {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    HomeWidget.widgetClicked.listen(
      (uri) => _launchedFromWidget(
        uri,
        onCreatePage: onCreatePage,
        onValidatePage: onValidatePage,
        onError: onError,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
          if (uri != null) {
            _launchedFromWidget(
              uri,
              onCreatePage: onCreatePage,
              onValidatePage: onValidatePage,
              onError: onError,
            );
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
    Future<bool> Function(String pageId)? onValidatePage,
  ]) =>
      _launchedFromWidget(
        uri,
        onCreatePage: onCreatePage,
        onValidatePage: onValidatePage,
        onError: onError,
      );

  @visibleForTesting
  static Future<void> handleWarmStart(
    Uri? uri, [
    Future<String?> Function()? onCreatePage,
    void Function(String error)? onError,
    Future<bool> Function(String pageId)? onValidatePage,
  ]) =>
      _launchedFromWidget(
        uri,
        onCreatePage: onCreatePage,
        onValidatePage: onValidatePage,
        onError: onError,
      );

  @visibleForTesting
  static Future<void> handleColdStart([
    Future<String?> Function()? onCreatePage,
    Future<Uri?> Function()? initialUriProvider,
    void Function(String error)? onError,
    Future<bool> Function(String pageId)? onValidatePage,
  ]) async {
    final uri = initialUriProvider != null
        ? await initialUriProvider()
        : await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null) {
      await _launchedFromWidget(
        uri,
        onCreatePage: onCreatePage,
        onValidatePage: onValidatePage,
        onError: onError,
      );
    }
  }

  static Future<void> _navigateToEditor({
    required String pageId,
    bool focusTitle = false,
  }) async {
    // Ensure the home shell route is established first so Back always has a destination.
    final currentPath = appRouter.routeInformationProvider.value.uri.path;
    if (currentPath != Routes.home && !currentPath.startsWith(Routes.home)) {
      appRouter.go(Routes.home);
      await Future<void>.delayed(Duration.zero);
    }

    // Push the editor on top of the established home shell
    unawaited(
      appRouter.pushNamed(
        Routes.editorName,
        pathParameters: {'pageId': pageId},
        extra: focusTitle ? const {'focusTitle': true} : null,
      ),
    );
  }

  static Future<void> _launchedFromWidget(
    Uri? uri, {
    Future<String?> Function()? onCreatePage,
    Future<bool> Function(String pageId)? onValidatePage,
    void Function(String error)? onError,
  }) async {
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
            await _navigateToEditor(
              pageId: pageId,
              focusTitle: true,
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

        if (onValidatePage != null) {
          final isValid = await onValidatePage(pageId);
          if (!isValid) {
            const errorMsg = 'Note not found or deleted.';
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
            return;
          }
        }

        await _navigateToEditor(
          pageId: pageId,
          focusTitle: false,
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
