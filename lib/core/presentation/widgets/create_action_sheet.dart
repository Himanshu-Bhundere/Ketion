import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ketion/core/router/routes.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';

class CreateActionSheet extends ConsumerWidget {
  const CreateActionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Create New',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('New Note'),
            onTap: () async {
              // Pop the bottom sheet first
              Navigator.of(context).pop();

              // Execute use case
              final createPage = ref.read(createPageUseCaseProvider);
              final result = await createPage(title: '');

              result.fold(
                (page) {
                  // Invalidate lists so new page appears immediately
                  ref.invalidate(recentPagesProvider);
                  ref.invalidate(favoritePagesProvider);
                  ref.invalidate(pageProvider(page.id));

                  // Navigate to the new page
                  context.pushNamed(
                    Routes.editorName,
                    pathParameters: {'pageId': page.id},
                    extra: {'focusTitle': true},
                  );
                },
                (error) {
                  if (context.mounted) {

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create note: $error')),
                    );
                  }
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_box),
            title: const Text('Checklist'),
            subtitle: const Text('Coming Soon', style: TextStyle(fontStyle: FontStyle.italic)),
            enabled: false,
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import'),
            subtitle: const Text('Coming Soon', style: TextStyle(fontStyle: FontStyle.italic)),
            enabled: false,
            onTap: () {},
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const CreateActionSheet(),
    );
  }
}
