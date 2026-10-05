import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tag_providers.dart';

class TagPickerSheet extends ConsumerStatefulWidget {
  final String? pageId;

  const TagPickerSheet({super.key, this.pageId});

  @override
  ConsumerState<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends ConsumerState<TagPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _tagColors = [
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

  Future<void> _showCreateTagDialog(
    BuildContext context, {
    String initialName = '',
  }) async {
    final nameController = TextEditingController(text: initialName.trim());
    String selectedColor = _tagColors.first;
    String? validationError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Tag'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Tag Name',
                      hintText: 'e.g., Work, Personal',
                      errorText: validationError,
                    ),
                    onChanged: (_) {
                      if (validationError != null) {
                        setDialogState(() => validationError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Color:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _tagColors.map((colorHex) {
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
                        validationError = 'Tag name cannot be empty';
                      });
                      return;
                    }

                    // Check uniqueness against loaded tags
                    final existingTags =
                        ref.read(tagsFutureProvider).valueOrNull ?? [];
                    final isDuplicate = existingTags.any(
                      (t) => t.name.toLowerCase() == trimmed.toLowerCase(),
                    );
                    if (isDuplicate) {
                      setDialogState(() {
                        validationError = 'A tag with this name already exists';
                      });
                      return;
                    }

                    final createUseCase = ref.read(createTagUseCaseProvider);
                    final result = await createUseCase(
                      name: trimmed,
                      color: selectedColor,
                    );

                    if (result.isSuccess) {
                      final newTag = result.valueOrNull!;
                      ref.invalidate(tagsFutureProvider);

                      if (widget.pageId != null) {
                        await ref.read(assignTagToPageUseCaseProvider)(
                          widget.pageId!,
                          newTag.id,
                        );
                        ref.invalidate(pageTagsFutureProvider(widget.pageId!));
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (widget.pageId == null && context.mounted) {
                        Navigator.pop(context, newTag);
                      }
                    } else {
                      setDialogState(() {
                        validationError = result.errorOrNull?.message ??
                            'Failed to create tag';
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
    final allTagsAsync = ref.watch(tagsFutureProvider);
    final pageTagsAsync = widget.pageId != null
        ? ref.watch(pageTagsFutureProvider(widget.pageId!))
        : null;

    final assignedTagIds =
        pageTagsAsync?.valueOrNull?.map((t) => t.id).toSet() ?? {};

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
                widget.pageId != null ? 'Page Tags' : 'Select Tag',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Create Tag',
                onPressed: () =>
                    _showCreateTagDialog(context, initialName: _searchQuery),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tags…',
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
            child: allTagsAsync.when(
              data: (tags) {
                final filtered = tags.where((tag) {
                  if (_searchQuery.isEmpty) return true;
                  return tag.name
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
                          const Text('No tags found.'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text(
                              _searchQuery.isNotEmpty
                                  ? 'Create "$_searchQuery"'
                                  : 'Create tag',
                            ),
                            onPressed: () => _showCreateTagDialog(
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
                    final tag = filtered[index];
                    final isAssigned = assignedTagIds.contains(tag.id);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _parseColor(tag.color, Colors.blueGrey),
                        radius: 12,
                      ),
                      title: Text(tag.name),
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
                            await ref.read(removeTagFromPageUseCaseProvider)(
                              widget.pageId!,
                              tag.id,
                            );
                          } else {
                            await ref.read(assignTagToPageUseCaseProvider)(
                              widget.pageId!,
                              tag.id,
                            );
                          }
                          ref.invalidate(
                            pageTagsFutureProvider(widget.pageId!),
                          );
                        } else {
                          Navigator.pop(context, tag);
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
