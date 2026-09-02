import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/tags/presentation/providers/tag_providers.dart';

class TagPickerSheet extends ConsumerWidget {
  const TagPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsFutureProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Tag',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          tagsAsync.when(
            data: (tags) {
              if (tags.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No tags found.'),
                  ),
                );
              }
              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(
                          int.parse(
                            (tag.color ?? '#CCCCCC').replaceFirst('#', '0xFF'),
                          ),
                        ),
                        radius: 12,
                      ),
                      title: Text(tag.name),
                      onTap: () {
                        Navigator.pop(context, tag);
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ],
      ),
    );
  }
}
