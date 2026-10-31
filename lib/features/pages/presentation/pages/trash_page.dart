import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/theme/app_spacing.dart';
import 'package:ketion/core/theme/app_typography.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as entity;
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  Future<void> _restorePage(
    BuildContext context,
    WidgetRef ref,
    entity.Page page,
  ) async {
    final repo = ref.read(pageRepositoryProvider);
    final result = await repo.restorePage(page.id);
    result.fold(
      (_) {
        ref.invalidate(deletedPagesProvider);
        ref.invalidate(recentPagesProvider);
        ref.invalidate(favoritePagesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Restored "${page.title.isEmpty ? 'Untitled' : page.title}"',
              ),
            ),
          );
        }
      },
      (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to restore: $error')),
          );
        }
      },
    );
  }

  Future<void> _permanentlyDeletePage(
    BuildContext context,
    WidgetRef ref,
    entity.Page page,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
          'Are you sure you want to permanently delete "${page.title.isEmpty ? 'Untitled' : page.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(pageRepositoryProvider);
      final result = await repo.permanentlyDeletePage(page.id);
      result.fold(
        (_) {
          ref.invalidate(deletedPagesProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note permanently deleted')),
            );
          }
        },
        (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete: $error')),
            );
          }
        },
      );
    }
  }

  Future<void> _emptyTrash(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'All notes in Trash will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(pageRepositoryProvider);
      final result = await repo.emptyTrash();
      result.fold(
        (_) {
          ref.invalidate(deletedPagesProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trash emptied')),
            );
          }
        },
        (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to empty trash: $error')),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedPagesAsync = ref.watch(deletedPagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          deletedPagesAsync.maybeWhen(
            data: (pages) => pages.isNotEmpty
                ? TextButton.icon(
                    onPressed: () => _emptyTrash(context, ref),
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Empty Trash'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: deletedPagesAsync.when(
        data: (pages) {
          if (pages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Trash is empty', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Notes deleted from your workspace appear here.',
                    style: AppTypography.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: pages.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final page = pages[index];
              final deleteDate = page.deletedAt ?? page.updatedAt;
              final dateStr =
                  '${deleteDate.toLocal().year}-${deleteDate.toLocal().month.toString().padLeft(2, '0')}-${deleteDate.toLocal().day.toString().padLeft(2, '0')}';

              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(page.title.isEmpty ? 'Untitled' : page.title),
                  subtitle: Text('Deleted $dateStr'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Restore Note',
                        icon: const Icon(Icons.restore),
                        onPressed: () => _restorePage(context, ref, page),
                      ),
                      IconButton(
                        tooltip: 'Delete Permanently',
                        icon: const Icon(Icons.delete_forever),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () =>
                            _permanentlyDeletePage(context, ref, page),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load trash: $err'),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => ref.invalidate(deletedPagesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

