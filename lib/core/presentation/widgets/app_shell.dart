import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      // Three pane layout, independent of mobile branches
      shell = const DesktopWorkspace();
    } else if (width >= AppBreakpoints.medium) {
      // Two pane layout
      shell = TabletWorkspace(navigationShell: navigationShell);
    } else {
      // Compact layout
      shell = MobileNavigation(navigationShell: navigationShell);
    }

    return GlobalOverlayLayer(
      child: shell,
    );
  }
}
