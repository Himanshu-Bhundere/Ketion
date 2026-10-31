import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ketion/core/presentation/widgets/create_action_sheet.dart';
import 'package:ketion/core/router/routes.dart';

class DesktopWorkspace extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DesktopWorkspace({
    super.key,
    required this.navigationShell,
  });

  static const _destinations = <_DesktopDestination>[
    _DesktopDestination(
      label: 'Workspace',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _DesktopDestination(
      label: 'Search',
      icon: Icons.search,
      selectedIcon: Icons.search,
    ),
    _DesktopDestination(
      label: 'Notes',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
    ),
    _DesktopDestination(
      label: 'Reminders',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
    ),
    _DesktopDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  Future<void> _createNote(BuildContext context) async {
    try {
      final page = await CreateActionSheet.show(context);

      if (page == null || !context.mounted) {
        return;
      }

      unawaited(
        context.pushNamed(
          Routes.editorName,
          pathParameters: {'pageId': page.id},
          extra: const {'focusTitle': true},
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Desktop New Note failed: $error');
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

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () => _createNote(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New Note'),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _destinations.length,
                    itemBuilder: (context, index) {
                      final destination = _destinations[index];
                      final selected = selectedIndex == index;

                      return ListTile(
                        selected: selected,
                        leading: Icon(
                          selected
                              ? destination.selectedIcon
                              : destination.icon,
                        ),
                        title: Text(destination.label),
                        onTap: () {
                          navigationShell.goBranch(
                            index,
                            initialLocation: index == selectedIndex,
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Trash'),
                  onTap: () {
                    context.push(Routes.trash);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _DesktopDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _DesktopDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
