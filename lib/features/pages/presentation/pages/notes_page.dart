import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ketion/core/presentation/widgets/create_action_sheet.dart';
import 'package:ketion/core/presentation/widgets/skeleton_loader.dart';
import 'package:ketion/core/router/routes.dart';
import 'package:ketion/core/theme/app_spacing.dart';
import 'package:ketion/core/theme/app_typography.dart';
import 'package:ketion/core/theme/breakpoints.dart';
import 'package:ketion/features/collections/presentation/providers/collection_providers.dart';
import 'package:ketion/features/home/presentation/providers/home_providers.dart';
import 'package:ketion/features/media/presentation/providers/attachment_provider.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as entity;
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/tags/presentation/providers/tag_providers.dart';

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
            icon: Icon(
              _viewType == NoteViewType.list
                  ? Icons.grid_view
                  : Icons.view_list,
            ),
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
                child: Text('Date Updated'),
              ),
              const PopupMenuItem(
                value: NoteSortOption.dateCreated,
                child: Text('Date Created'),
              ),
              const PopupMenuItem(
                value: NoteSortOption.alphabetical,
                child: Text('Alphabetical'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Trash',
            onPressed: () => context.push(Routes.trash),
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
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('No notes yet', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Capture your thoughts and ideas here.',
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () async {
                      final page = await CreateActionSheet.show(context);
                      if (page != null && context.mounted) {
                        unawaited(
                          context.pushNamed(
                            Routes.editorName,
                            pathParameters: {'pageId': page.id},
                            extra: const {'focusTitle': true},
                          ),
                        );
                      }
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
                maxCrossAxisExtent: 220,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: 0.75,
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
                maxCrossAxisExtent: 220,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: 0.75,
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
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
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
    final hasIcon = page.icon != null && page.icon!.isNotEmpty;
    final hasCover = page.coverImage != null && page.coverImage!.isNotEmpty;

    Widget leadingWidget;
    if (hasCover) {
      leadingWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          _PageCoverThumbnail(
            cover: page.coverImage!,
            width: 44,
            height: 44,
            borderRadius: BorderRadius.circular(6),
          ),
          if (hasIcon)
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  page.icon!,
                  style: const TextStyle(fontSize: 14, height: 1),
                ),
              ),
            ),
        ],
      );
    } else if (hasIcon) {
      leadingWidget = Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Text(
          page.icon!,
          style: const TextStyle(fontSize: 28, height: 1),
        ),
      );
    } else {
      leadingWidget = Icon(
        page.isFavorite ? Icons.star : Icons.description,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: leadingWidget,
        title: Row(
          children: [
            Expanded(
              child: Text(
                page.title.isEmpty ? 'Untitled' : page.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (page.isFavorite)
              Icon(
                Icons.star,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Updated ${page.updatedAt.toLocal().toString().substring(0, 10)}',
              style: AppTypography.caption,
            ),
            _PageMetadataBadges(pageId: page.id),
          ],
        ),
        onTap: () => _openNote(context, page),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, entity.Page page) {
    final hasIcon = page.icon != null && page.icon!.isNotEmpty;
    final hasCover = page.coverImage != null && page.coverImage!.isNotEmpty;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _openNote(context, page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasCover)
              _PageCoverThumbnail(
                cover: page.coverImage!,
                width: double.infinity,
                height: 72,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (hasIcon)
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Text(
                              page.icon!,
                              style: const TextStyle(fontSize: 20, height: 1),
                            ),
                          )
                        else if (!hasCover)
                          Icon(
                            Icons.description,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        const Spacer(),
                        if (page.isFavorite)
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      page.title.isEmpty ? 'Untitled' : page.title,
                      style: AppTypography.body
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _PageMetadataBadges(pageId: page.id),
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
          ],
        ),
      ),
    );
  }

  void _openNote(BuildContext context, entity.Page page) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.medium) {
      ref.read(activePageIdProvider.notifier).state = page.id;
    } else {
      context.pushNamed(Routes.editorName, pathParameters: {'pageId': page.id});
    }
  }
}

class _PageCoverThumbnail extends ConsumerWidget {
  final String cover;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _PageCoverThumbnail({
    required this.cover,
    this.width = double.infinity,
    this.height = 70,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cover.startsWith('http://') || cover.startsWith('https://')) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          cover,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }

    final attachmentAsync = ref.watch(attachmentProvider(cover));
    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) return const SizedBox.shrink();
        final pathAsync = ref.watch(attachmentPathProvider(attachment));
        return pathAsync.when(
          data: (localPath) {
            if (localPath == null || localPath.isEmpty) {
              return const SizedBox.shrink();
            }
            return ClipRRect(
              borderRadius: borderRadius,
              child: kIsWeb
                  ? Image.network(
                      localPath,
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      io.File(localPath),
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
            );
          },
          loading: () => SizedBox(width: width, height: height),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => SizedBox(width: width, height: height),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PageMetadataBadges extends ConsumerWidget {
  final String pageId;

  const _PageMetadataBadges({required this.pageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(pageTagsFutureProvider(pageId));
    final collectionsAsync = ref.watch(pageCollectionsFutureProvider(pageId));

    final tags = tagsAsync.valueOrNull ?? const [];
    final collections = collectionsAsync.valueOrNull ?? const [];

    if (tags.isEmpty && collections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        children: [
          ...collections.map(
            (c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 10,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    c.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...tags.map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '#${t.name}',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
