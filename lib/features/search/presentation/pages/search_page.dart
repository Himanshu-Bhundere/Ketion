import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/search_providers.dart';
import '../widgets/search_result_item.dart';
import 'package:ketion/core/theme/app_spacing.dart';
import 'package:ketion/core/theme/app_typography.dart';
import 'package:ketion/core/presentation/widgets/skeleton_loader.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String? _selectedFilter;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  void _onSearch() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(searchNotifierProvider.notifier).search(
        _controller.text, 
        typeFilter: _selectedFilter,
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

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search notes...',
            border: InputBorder.none,
          ),
          onChanged: (value) => _onSearch(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedFilter == null,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = null);
                    _onSearch();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pages'),
                  selected: _selectedFilter == 'page',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'page');
                    _onSearch();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Blocks'),
                  selected: _selectedFilter == 'block',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'block');
                    _onSearch();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Tags'),
                  selected: _selectedFilter == 'tag',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'tag');
                    _onSearch();
                  },
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
                  Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: AppSpacing.md),
                  Text('No results found', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Try adjusting your search terms or filters.', style: AppTypography.body),
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
                  if (result.entityType == 'tag') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tag filtering coming soon: ${result.snippet}',
                        ),
                      ),
                    );
                    return;
                  }

                  final targetPageId = result.pageId ?? result.entityId;
                  context.push('/editor/$targetPageId');
                },
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
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
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text('Search Failed', style: AppTypography.title),
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
