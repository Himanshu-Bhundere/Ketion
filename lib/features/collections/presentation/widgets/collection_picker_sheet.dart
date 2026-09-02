import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/collections/presentation/providers/collection_providers.dart';

class CollectionPickerSheet extends ConsumerWidget {
  const CollectionPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsFutureProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Collection',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          collectionsAsync.when(
            data: (collections) {
              if (collections.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No collections found.'),
                  ),
                );
              }
              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final collection = collections[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(
                          int.parse(
                            (collection.color ?? '#CCCCCC')
                                .replaceFirst('#', '0xFF'),
                          ),
                        ),
                        radius: 12,
                        child: Text(collection.icon ?? ''),
                      ),
                      title: Text(collection.name),
                      onTap: () {
                        Navigator.pop(context, collection);
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
