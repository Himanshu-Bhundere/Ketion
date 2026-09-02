import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/search_providers.dart';
import '../widgets/search_result_item.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String? _selectedFilter;
  final TextEditingController _controller = TextEditingController();

  void _onSearch() {
    ref.read(searchNotifierProvider.notifier).search(
      _controller.text, 
      typeFilter: _selectedFilter,
    );
  }

  @override
  void dispose() {
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
            return const Center(child: Text('No results found.'));
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
