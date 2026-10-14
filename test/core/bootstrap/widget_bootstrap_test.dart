import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/core/bootstrap/widget_bootstrap.dart';
import 'package:ketion/core/router/app_router.dart';
import 'package:ketion/core/router/routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WidgetBootstrap Deep Link Routing', () {
    test('ketion://new-note invokes onCreatePage and routes to editor', () async {
      bool onCreatePageCalled = false;
      const expectedPageId = 'created-test-page-id';

      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://new-note'),
        () async {
          onCreatePageCalled = true;
          return expectedPageId;
        },
      );

      expect(onCreatePageCalled, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, contains(expectedPageId));
    });

    test('ketion://quick_note invokes onCreatePage and routes to editor', () async {
      bool onCreatePageCalled = false;
      const expectedPageId = 'quick-note-page-id';

      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://quick_note'),
        () async {
          onCreatePageCalled = true;
          return expectedPageId;
        },
      );

      expect(onCreatePageCalled, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, contains(expectedPageId));
    });

    test('ketion://quick-note invokes onCreatePage and routes to editor', () async {
      bool onCreatePageCalled = false;
      const expectedPageId = 'quick-dash-note-page-id';

      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://quick-note'),
        () async {
          onCreatePageCalled = true;
          return expectedPageId;
        },
      );

      expect(onCreatePageCalled, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, contains(expectedPageId));
    });

    test('ketion://note/{id} routes directly to editor for that note', () async {
      const existingPageId = 'existing-note-xyz';

      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://note/$existingPageId'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, contains(existingPageId));
    });

    test('ketion://page/{id} routes directly to editor for that note', () async {
      const existingPageId = 'existing-page-abc';

      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://page/$existingPageId'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, contains(existingPageId));
    });

    test('ignores invalid or empty note IDs', () async {
      final currentPath = appRouter.routeInformationProvider.value.uri.path;

      await WidgetBootstrap.handleDeepLink(Uri.parse('ketion://note/ '));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, currentPath);

      await WidgetBootstrap.handleDeepLink(Uri.parse('ketion://note/null'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, currentPath);

      await WidgetBootstrap.handleDeepLink(Uri.parse('ketion://note/undefined'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, currentPath);
    });

    test('ketion://settings routes to settings page', () async {
      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://settings'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, Routes.settings);
    });

    test('ketion://settings/sync routes to settings sync destination', () async {
      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://settings/sync'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, Routes.settingsSync);
    });

    test('cold start launch navigates to destination correctly', () async {
      const coldStartNoteId = 'cold-start-note-123';
      await WidgetBootstrap.handleColdStart(
        null,
        () async => Uri.parse('ketion://note/$coldStartNoteId'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, contains(coldStartNoteId));
    });

    test('warm start launch navigates to destination correctly', () async {
      const warmStartNoteId = 'warm-start-note-456';
      await WidgetBootstrap.handleWarmStart(
        Uri.parse('ketion://note/$warmStartNoteId'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, contains(warmStartNoteId));
    });

    test('ignores non-ketion uri', () async {
      final currentPath = appRouter.routeInformationProvider.value.uri.path;
      await WidgetBootstrap.handleDeepLink(
        Uri.parse('https://example.com/note'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, currentPath);
    });

    test('failed note creation triggers onError and does not navigate to fabricated UUID', () async {
      final initialPath = appRouter.routeInformationProvider.value.uri.path;
      String? errorMessage;

      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://new-note'),
        () async => null, // Failed creation returns null
        (err) => errorMessage = err,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(errorMessage, 'Failed to create note. Please try again.');
      expect(appRouter.routeInformationProvider.value.uri.path, initialPath);
    });

    test('repeated rapid widget taps are locked and execute onCreatePage only once', () async {
      int creationCount = 0;
      final completer = Completer<String?>();

      // Fire first tap
      final future1 = WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://new-note'),
        () async {
          creationCount++;
          return completer.future;
        },
      );

      // Fire rapid second tap while first is in-flight
      final future2 = WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://new-note'),
        () async {
          creationCount++;
          return 'second-id';
        },
      );

      // Resolve in-flight creation
      completer.complete('first-page-id');
      await Future.wait([future1, future2]);

      expect(creationCount, 1);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, contains('first-page-id'));
    });

    test('cold start with failed creation does not open fabricated UUID', () async {
      final initialPath = appRouter.routeInformationProvider.value.uri.path;
      String? reportedError;

      await WidgetBootstrap.handleColdStart(
        () async => null,
        () async => Uri.parse('ketion://new-note'),
        (err) => reportedError = err,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(reportedError, isNotNull);
      expect(appRouter.routeInformationProvider.value.uri.path, initialPath);
    });
  });
}
