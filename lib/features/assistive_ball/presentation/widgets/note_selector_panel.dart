import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import '../../../pages/presentation/widgets/page_cover_image.dart';
import 'assistive_ball_header_button.dart';

class NoteSelectorPanel extends ConsumerWidget {
  final VoidCallback onClose;
  final ValueChanged<String> onSelect;

  const NoteSelectorPanel({
    super.key,
    required this.onClose,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pagesAsync = ref.watch(allPagesProvider);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: isDark ? const Color(0xFF222428) : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222428) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark
                  ? const Color(0xFF2D3035)
                  : theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select a Note',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AssistiveBallHeaderButton(
                    icon: Icons.close,
                    tooltip: 'Close Note Selector',
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: pagesAsync.when(
                data: (pages) {
                  if (pages.isEmpty) {
                    return Center(
                      child: Text(
                        'No notes available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      final page = pages[index];

                      final hasCover =
                          page.coverImage != null && page.coverImage!.isNotEmpty;

                      return ListTile(
                        dense: true,
                        leading: hasCover
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: PageCoverImage(
                                    pageId: page.id,
                                    coverImage: page.coverImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : const Icon(Icons.description_outlined, size: 20),
                        title: Text(
                          page.title.isEmpty ? 'Untitled' : page.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        onTap: () => onSelect(page.id),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'Unable to load notes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
