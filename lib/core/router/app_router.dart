import 'package:go_router/go_router.dart';
import 'package:ketion/core/router/routes.dart';
import 'package:ketion/features/home/presentation/pages/home_page.dart';
import 'package:ketion/features/editor/presentation/pages/editor_page.dart';
import 'package:ketion/features/search/presentation/pages/search_page.dart';
final appRouter = GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: Routes.editor,
      builder: (context, state) {
        final pageId = state.pathParameters['pageId']!;
        return EditorPage(pageId: pageId);
      },
    ),
    GoRoute(
      path: Routes.search,
      builder: (context, state) => const SearchPage(),
    ),
  ],
);
