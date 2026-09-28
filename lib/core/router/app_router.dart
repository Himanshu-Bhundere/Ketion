import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ketion/core/router/routes.dart';
import 'package:ketion/core/presentation/widgets/app_shell.dart';
import 'package:ketion/features/home/presentation/pages/home_page.dart';
import 'package:ketion/features/editor/presentation/pages/editor_page.dart';
import 'package:ketion/features/search/presentation/pages/search_page.dart';
import 'package:ketion/features/settings/presentation/pages/settings_page.dart';
import 'package:ketion/features/pages/presentation/pages/notes_page.dart';
import 'package:ketion/features/reminders/presentation/pages/reminders_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Home Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        // Search Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.search,
              builder: (context, state) => const SearchPage(),
            ),
          ],
        ),
        // Notes Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.notes,
              builder: (context, state) => const NotesPage(),
            ),
          ],
        ),
        // Reminders Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.reminders,
              builder: (context, state) => const RemindersPage(),
            ),
          ],
        ),
        // Settings Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    // Routes outside the shell, or independent
    GoRoute(
      name: Routes.editorName,
      parentNavigatorKey: _rootNavigatorKey,
      path: Routes.editor,
      builder: (context, state) {
        final pageId = state.pathParameters['pageId']!;
        return EditorPage(pageId: pageId);
      },
    ),
  ],
);
