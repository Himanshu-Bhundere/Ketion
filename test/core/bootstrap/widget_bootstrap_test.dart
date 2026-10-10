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
      // Wait for async router push to complete
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

    test('ketion://note/{id} routes directly to editor for that note', () async {
      const existingPageId = 'existing-note-xyz';

      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://note/$existingPageId'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, contains(existingPageId));
    });

    test('ketion://settings routes to settings page', () async {
      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://settings'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, Routes.settings);
    });

    test('ignores non-ketion uri', () async {
      final currentPath = appRouter.routeInformationProvider.value.uri.path;
      await WidgetBootstrap.handleDeepLink(
        Uri.parse('https://example.com/note'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, currentPath);
    });
  });
}
