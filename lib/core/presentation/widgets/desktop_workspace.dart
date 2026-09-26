import 'package:flutter/material.dart';

class DesktopWorkspace extends StatelessWidget {
  const DesktopWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Create Note
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Note'),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: const [
                      ListTile(
                          leading: Icon(Icons.dashboard_outlined),
                          title: Text('Workspace')),
                      ListTile(
                          leading: Icon(Icons.folder_outlined),
                          title: Text('Collections')),
                      ListTile(
                          leading: Icon(Icons.star_outline),
                          title: Text('Favorites')),
                      ListTile(
                          leading: Icon(Icons.history), title: Text('Recent')),
                      ListTile(leading: Icon(Icons.tag), title: Text('Tags')),
                      ListTile(
                          leading: Icon(Icons.archive_outlined),
                          title: Text('Archive')),
                      ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Trash')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Note List Pane
          SizedBox(
            width: 300,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(child: Text('Note List')),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Editor Pane
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(child: Text('Editor / Properties')),
            ),
          ),
        ],
      ),
    );
  }
}
