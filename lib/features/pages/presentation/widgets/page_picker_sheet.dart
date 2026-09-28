import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/page_providers.dart';

class PagePickerSheet extends ConsumerWidget {
  const PagePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentPagesAsync = ref.watch(recentPagesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Link to Page',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: recentPagesAsync.when(
              data: (pages) {
                if (pages.isEmpty) {
                  return const Center(
                    child: Text('No pages found'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(page.title),
                      onTap: () {
                        Navigator.pop(context, page);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
