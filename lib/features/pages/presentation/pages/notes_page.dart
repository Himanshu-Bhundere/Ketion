import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/theme/app_spacing.dart';
import 'package:ketion/core/theme/app_typography.dart';
import 'package:ketion/features/home/presentation/providers/home_providers.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as entity;
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/core/theme/breakpoints.dart';
import 'package:ketion/core/presentation/widgets/skeleton_loader.dart';

enum NoteSortOption { dateCreated, dateUpdated, alphabetical }

enum NoteViewType { list, grid }

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  NoteSortOption _sortOption = NoteSortOption.dateUpdated;
  NoteViewType _viewType = NoteViewType.list;

  @override
  Widget build(BuildContext context) {
    final recentPagesAsync = ref.watch(recentPagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notes'),
        actions: [
          IconButton(
            icon: Icon(_viewType == NoteViewType.list
                ? Icons.grid_view
                : Icons.view_list),
            onPressed: () {
              setState(() {
                _viewType = _viewType == NoteViewType.list
                    ? NoteViewType.grid
                    : NoteViewType.list;
              });
            },
          ),
          PopupMenuButton<NoteSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: NoteSortOption.dateUpdated,
                  child: Text('Date Updated')),
              const PopupMenuItem(
                  value: NoteSortOption.dateCreated,
                  child: Text('Date Created')),
              const PopupMenuItem(
                  value: NoteSortOption.alphabetical,
                  child: Text('Alphabetical')),
            ],
          ),
        ],
      ),
      body: recentPagesAsync.when(
        data: (pages) {
          if (pages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: AppSpacing.md),
                  const Text('No notes yet', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Capture your thoughts and ideas here.',
                      style: AppTypography.body, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () {
                      // TODO: Navigate to create new note
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Note'),
                  ),
                ],
              ),
            );
          }

          final sortedPages = List<entity.Page>.from(pages);
          switch (_sortOption) {
            case NoteSortOption.dateUpdated:
              sortedPages.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
              break;
            case NoteSortOption.dateCreated:
              sortedPages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              break;
            case NoteSortOption.alphabetical:
              sortedPages.sort((a, b) => a.title.compareTo(b.title));
              break;
          }

          if (_viewType == NoteViewType.grid) {
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: 0.8,
              ),
              itemCount: sortedPages.length,
              itemBuilder: (context, index) =>
                  _buildGridItem(context, sortedPages[index]),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: sortedPages.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _buildListItem(context, sortedPages[index]),
          );
        },
        loading: () {
          if (_viewType == NoteViewType.grid) {
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: 0.8,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => SkeletonLoader(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: 6,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => SkeletonLoader(
              width: double.infinity,
              height: 72,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              const Text('Something went wrong', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => ref.invalidate(recentPagesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, entity.Page page) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(
          page.isFavorite ? Icons.star : Icons.description,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(page.title.isEmpty ? 'Untitled' : page.title),
        subtitle: Text(
            'Updated ${page.updatedAt.toLocal().toString().substring(0, 10)}'),
        onTap: () => _openNote(context, page),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, entity.Page page) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _openNote(context, page),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                page.isFavorite ? Icons.star : Icons.description,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                page.title.isEmpty ? 'Untitled' : page.title,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                'Updated ${page.updatedAt.toLocal().toString().substring(0, 10)}',
                style: AppTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNote(BuildContext context, entity.Page page) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.medium) {
      ref.read(activePageIdProvider.notifier).state = page.id;
    } else {
      // TODO: Use go_router push
    }
  }
}
