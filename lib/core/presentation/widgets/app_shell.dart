import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ketion/core/presentation/widgets/create_action_sheet.dart';
import 'package:ketion/core/router/routes.dart';
import 'package:ketion/core/theme/breakpoints.dart';
import 'mobile_navigation.dart';
import 'tablet_workspace.dart';
import 'desktop_workspace.dart';
import 'global_overlay_layer.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    Widget shell;
    if (width >= AppBreakpoints.expanded) {
      shell = DesktopWorkspace(
        navigationShell: navigationShell,
        onCreateNote: () => _createNote(context),
      );
    } else if (width >= AppBreakpoints.medium) {
      // Two pane layout
      shell = TabletWorkspace(
        navigationShell: navigationShell,
        onCreateNote: () => _createNote(context),
      );
    } else {
      // Compact layout
      shell = MobileNavigation(navigationShell: navigationShell);
    }

    return GlobalOverlayLayer(
      child: shell,
    );
  }

  Future<void> _createNote(BuildContext context) async {
    try {
      final page = await CreateActionSheet.show(context);
      if (page == null || !context.mounted) return;

      await context.pushNamed(
        Routes.editorName,
        pathParameters: {'pageId': page.id},
        extra: const {'focusTitle': true},
      );
    } catch (error, stackTrace) {
      debugPrint('New Note failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Unable to create a note. Check the application logs.'),
          ),
        );
      }
    }
  }
}
