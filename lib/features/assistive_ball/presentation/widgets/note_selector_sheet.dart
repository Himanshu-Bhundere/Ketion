import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pages/presentation/providers/page_providers.dart';

class NoteSelectorSheet extends ConsumerWidget {
  const NoteSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(recentPagesProvider);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select a Note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: pagesAsync.when(
                data: (pages) {
                  if (pages.isEmpty) {
                    return const Center(
                      child: Text('No notes available'),
                    );
                  }

                  return ListView.builder(
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      final page = pages[index];

                      return ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(
                          page.title.isEmpty ? 'Untitled' : page.title,
                        ),
                        onTap: () {
                          Navigator.pop(context, page.id);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => const Center(
                  child: Text('Unable to load notes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
