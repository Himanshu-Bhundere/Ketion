import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ketion/core/presentation/widgets/skeleton_loader.dart';
import 'package:ketion/core/theme/app_spacing.dart';
import 'package:ketion/core/theme/app_typography.dart';
import 'package:ketion/features/collections/presentation/providers/collection_providers.dart';
import 'package:ketion/features/tags/presentation/providers/tag_providers.dart';
import '../../../editor/domain/models/editor_open_target.dart';
import '../providers/search_providers.dart';
import '../widgets/search_result_item.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String? _selectedFilter;
  String? _selectedTag;
  String? _selectedCollection;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  void _onSearch() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(searchNotifierProvider.notifier).search(
            _controller.text,
            typeFilter: _selectedFilter,
            tagFilter: _selectedTag,
            collectionFilter: _selectedCollection,
          );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final tags = ref.watch(tagsFutureProvider).valueOrNull ?? const [];
    final collections =
        ref.watch(collectionsFutureProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search notes...',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _controller.clear();
                      _onSearch();
                    },
                  )
                : null,
          ),
          onChanged: (value) => _onSearch(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedFilter == null,
                  onSelected: (_) {
                    setState(() => _selectedFilter = null);
                    _onSearch();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pages'),
                  selected: _selectedFilter == 'page',
                  onSelected: (_) {
                    setState(() => _selectedFilter = 'page');
                    _onSearch();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Blocks'),
                  selected: _selectedFilter == 'block',
                  onSelected: (_) {
                    setState(() => _selectedFilter = 'block');
                    _onSearch();
                  },
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedTag != null
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedTag,
                      hint: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.label_outline, size: 14),
                          SizedBox(width: 4),
                          Text('Tag', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      isDense: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child:
                              Text('All Tags', style: TextStyle(fontSize: 13)),
                        ),
                        ...tags.map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(
                              '#${t.name}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedTag = val);
                        _onSearch();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedCollection != null
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedCollection,
                      hint: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_outlined, size: 14),
                          SizedBox(width: 4),
                          Text('Collection', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      isDense: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'All Collections',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        ...collections.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedCollection = val);
                        _onSearch();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: searchState.when(
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('No results found', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Try adjusting your search terms or filters.',
                    style: AppTypography.body,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return SearchResultItem(
                result: result,
                onTap: () {
                  final targetPageId = result.strongestMatch.pageId;
                  if (targetPageId != null && targetPageId.isNotEmpty) {
                    context.push(
                      '/editor/$targetPageId',
                      extra: {
                        'openTarget': EditorOpenTarget(
                          pageId: targetPageId,
                          targetBlockId:
                              result.strongestMatch.entityType == 'block'
                                  ? result.strongestMatch.entityId
                                  : null,
                        ),
                      },
                    );
                  } else if (result.strongestMatch.entityType == 'tag') {
                    setState(
                      () => _selectedTag = result.strongestMatch.entityId,
                    );
                    _onSearch();
                  } else if (result.strongestMatch.entityType == 'collection') {
                    setState(
                      () =>
                          _selectedCollection = result.strongestMatch.entityId,
                    );
                    _onSearch();
                  } else {
                    final entityId = result.strongestMatch.entityId;
                    context.push(
                      '/editor/$entityId',
                      extra: {
                        'openTarget': EditorOpenTarget(
                          pageId: entityId,
                        ),
                      },
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 5,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => SkeletonLoader(
            width: double.infinity,
            height: 80,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Search Failed', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              Text(error.toString(), style: AppTypography.body),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _onSearch,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
