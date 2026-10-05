import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/collection_providers.dart';

class CollectionPickerSheet extends ConsumerStatefulWidget {
  final String? pageId;

  const CollectionPickerSheet({super.key, this.pageId});

  @override
  ConsumerState<CollectionPickerSheet> createState() =>
      _CollectionPickerSheetState();
}

class _CollectionPickerSheetState extends ConsumerState<CollectionPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _collectionIcons = [
    '📁',
    '📚',
    '💼',
    '🎯',
    '🚀',
    '💡',
    '🏷️',
    '📝',
  ];

  static const List<String> _collectionColors = [
    '#4A90E2', // Blue
    '#50E3C2', // Teal
    '#B8E986', // Light Green
    '#F5A623', // Orange
    '#E74C3C', // Red
    '#9B59B6', // Purple
    '#95A5A6', // Grey
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final clean = hexString.replaceFirst('#', '');
      final fullHex = clean.length == 6 ? 'FF$clean' : clean;
      final val = int.tryParse(fullHex, radix: 16);
      return val != null ? Color(val) : fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _showCreateCollectionDialog(
    BuildContext context, {
    String initialName = '',
  }) async {
    final nameController = TextEditingController(text: initialName.trim());
    String selectedIcon = _collectionIcons.first;
    String selectedColor = _collectionColors.first;
    String? validationError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Collection'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Collection Name',
                        hintText: 'e.g., Projects, Research',
                        errorText: validationError,
                      ),
                      onChanged: (_) {
                        if (validationError != null) {
                          setDialogState(() => validationError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Icon:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _collectionIcons.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedIcon = icon);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade100,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Color:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _collectionColors.map((colorHex) {
                        final color = _parseColor(colorHex, Colors.blue);
                        final isSelected = selectedColor == colorHex;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedColor = colorHex);
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final trimmed = nameController.text.trim();
                    if (trimmed.isEmpty) {
                      setDialogState(() {
                        validationError = 'Collection name cannot be empty';
                      });
                      return;
                    }

                    // Check uniqueness against loaded collections
                    final existingCollections =
                        ref.read(collectionsFutureProvider).valueOrNull ?? [];
                    final isDuplicate = existingCollections.any(
                      (c) => c.name.toLowerCase() == trimmed.toLowerCase(),
                    );
                    if (isDuplicate) {
                      setDialogState(() {
                        validationError =
                            'A collection with this name already exists';
                      });
                      return;
                    }

                    final createUseCase =
                        ref.read(createCollectionUseCaseProvider);
                    final result = await createUseCase(
                      name: trimmed,
                      icon: selectedIcon,
                      color: selectedColor,
                    );

                    if (result.isSuccess) {
                      final newCollection = result.valueOrNull!;
                      ref.invalidate(collectionsFutureProvider);

                      if (widget.pageId != null) {
                        await ref.read(assignCollectionToPageUseCaseProvider)(
                          widget.pageId!,
                          newCollection.id,
                        );
                        ref.invalidate(
                          pageCollectionsFutureProvider(widget.pageId!),
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (widget.pageId == null && context.mounted) {
                        Navigator.pop(context, newCollection);
                      }
                    } else {
                      setDialogState(() {
                        validationError = result.errorOrNull?.message ??
                            'Failed to create collection';
                      });
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCollectionsAsync = ref.watch(collectionsFutureProvider);
    final pageCollectionsAsync = widget.pageId != null
        ? ref.watch(pageCollectionsFutureProvider(widget.pageId!))
        : null;

    final assignedCollectionIds =
        pageCollectionsAsync?.valueOrNull?.map((c) => c.id).toSet() ?? {};

    return Container(
      padding: const EdgeInsets.all(16.0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.pageId != null
                    ? 'Page Collections'
                    : 'Select Collection',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Create Collection',
                onPressed: () => _showCreateCollectionDialog(
                  context,
                  initialName: _searchQuery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search collections…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val.trim());
            },
          ),
          const SizedBox(height: 12),
          Flexible(
            child: allCollectionsAsync.when(
              data: (collections) {
                final filtered = collections.where((collection) {
                  if (_searchQuery.isEmpty) return true;
                  return collection.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No collections found.'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text(
                              _searchQuery.isNotEmpty
                                  ? 'Create "$_searchQuery"'
                                  : 'Create collection',
                            ),
                            onPressed: () => _showCreateCollectionDialog(
                              context,
                              initialName: _searchQuery,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final collection = filtered[index];
                    final isAssigned =
                        assignedCollectionIds.contains(collection.id);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _parseColor(collection.color, Colors.blueGrey),
                        radius: 12,
                        child: Text(
                          collection.icon ?? '📁',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      title: Text(collection.name),
                      trailing: widget.pageId != null
                          ? Icon(
                              isAssigned
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isAssigned
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            )
                          : null,
                      onTap: () async {
                        if (widget.pageId != null) {
                          if (isAssigned) {
                            await ref
                                .read(removeCollectionFromPageUseCaseProvider)(
                              widget.pageId!,
                              collection.id,
                            );
                          } else {
                            await ref
                                .read(assignCollectionToPageUseCaseProvider)(
                              widget.pageId!,
                              collection.id,
                            );
                          }
                          ref.invalidate(
                            pageCollectionsFutureProvider(widget.pageId!),
                          );
                        } else {
                          Navigator.pop(context, collection);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: $err'),
                ),
              ),
            ),
          ),
          if (widget.pageId != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
