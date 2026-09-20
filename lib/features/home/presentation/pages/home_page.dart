import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/theme/app_spacing.dart';
import 'package:ketion/core/theme/app_typography.dart';
import 'package:ketion/core/theme/breakpoints.dart';
import 'package:ketion/features/home/presentation/providers/home_providers.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as entity;
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/core/presentation/widgets/skeleton_loader.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              floating: true,
              title: Text('Good morning'),
              centerTitle: false,
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildRemindersSection(context),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildRecentlyViewedSection(context, ref),
                  // Additional sections like Pinned can go here
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: MediaQuery.of(context).size.width < AppBreakpoints.medium
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Wire up actual new note logic and route push
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildRemindersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today\'s Reminders', style: AppTypography.title),
        const SizedBox(height: AppSpacing.lg),
        // Mock data for now
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Review Phase 1.1 architecture'),
            subtitle: Text('Due Today at 5:00 PM'),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyViewedSection(BuildContext context, WidgetRef ref) {
    final recentPagesAsync = ref.watch(recentPagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recently Viewed', style: AppTypography.title),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 160,
          child: recentPagesAsync.when(
            data: (pages) {
              if (pages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: AppSpacing.sm),
                      const Text('No recent pages.', style: AppTypography.body),
                    ],
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pages.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.lg),
                itemBuilder: (context, index) {
                  return _buildRecentCard(context, ref, pages[index]);
                },
              );
            },
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.lg),
              itemBuilder: (context, index) => SkeletonLoader(
                width: 140,
                height: 160,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            error: (e, st) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Failed to load', style: AppTypography.body),
                  TextButton(
                    onPressed: () => ref.invalidate(recentPagesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCard(BuildContext context, WidgetRef ref, entity.Page page) {
    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: () {
            // Navigation handled by the AppShell/Router logic.
            // On mobile -> push editor route
            // On desktop/tablet -> update active page provider
            final width = MediaQuery.of(context).size.width;
            if (width >= AppBreakpoints.medium) {
              ref.read(activePageIdProvider.notifier).state = page.id;
            } else {
              // TODO: use go_router push
            }
          },
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
      ),
    );
  }
}
