import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../providers/editor_state_provider.dart';
import 'package:ketion/features/tags/presentation/widgets/tag_picker_sheet.dart';
import 'package:ketion/features/collections/presentation/widgets/collection_picker_sheet.dart';
import 'package:ketion/features/reminders/presentation/widgets/reminder_picker_sheet.dart';
import 'package:ketion/features/tags/domain/entities/tag.dart';
import 'package:ketion/features/collections/domain/entities/collection.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/features/import_export/presentation/providers/import_export_providers.dart';

class EditorTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String pageId;

  const EditorTopBar({super.key, required this.pageId});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(pageProvider(pageId));
    final blocksAsync = ref.watch(editorStateProvider(pageId));

    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: () {
            ref.read(editorStateProvider(pageId).notifier).undo();
          },
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          onPressed: () {
            ref.read(editorStateProvider(pageId).notifier).redo();
          },
        ),
        pageAsync.when(
          data: (page) {
            if (page == null) return const SizedBox.shrink();
            return Semantics(
              label: 'More menu',
              button: true,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (value) async {
                switch (value) {
                  case 'favorite':
                    final updatedPage = page.copyWith(isFavorite: !page.isFavorite);
                    await ref.read(updatePageUseCaseProvider)(updatedPage);
                    ref.invalidate(pageProvider(pageId));
                    break;
                  case 'use_template':
                    final createUseCase = ref.read(createPageUseCaseProvider);
                    final result = await createUseCase(
                      title: page.title,
                      isTemplate: false,
                      icon: page.icon,
                      coverImage: page.coverImage,
                      parentPageId: page.parentPageId,
                    );
                    final newPage = result.valueOrNull;
                    if (newPage == null) return;

                    final blocks = ref.read(editorStateProvider(pageId)).valueOrNull ?? [];
                    final updateBlockUseCase = ref.read(updateBlockUseCaseProvider);

                    final idMap = <String, String>{};
                    for (final b in blocks) {
                      idMap[b.id] = const Uuid().v7();
                    }

                    for (final b in blocks) {
                      final newBlockId = idMap[b.id]!;
                      final newParentId = b.parentBlockId != null ? idMap[b.parentBlockId] : null;

                      final newBlock = b.copyWith(
                        id: newBlockId,
                        pageId: newPage.id,
                        parentBlockId: newParentId,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      await updateBlockUseCase(newBlock);
                    }

                    // ignore: unused_result
                    ref.invalidate(recentPagesProvider);
                    if (context.mounted) {
                      context.pushReplacement('/editor/${newPage.id}');
                    }
                    break;
                  case 'tags':
                    await showModalBottomSheet<Tag>(
                      context: context,
                      builder: (context) => const TagPickerSheet(),
                    );
                    break;
                  case 'collections':
                    await showModalBottomSheet<Collection>(
                      context: context,
                      builder: (context) => const CollectionPickerSheet(),
                    );
                    break;
                  case 'reminder':
                    await showModalBottomSheet<void>(
                      context: context,
                      builder: (context) => ReminderPickerSheet(pageId: pageId),
                    );
                    break;
                  case 'export_md':
                  case 'export_html':
                  case 'export_pdf':
                    final ext = value.split('_')[1];
                    final blocks = blocksAsync.valueOrNull;
                    if (blocks != null) {
                      final useCase = ref.read(exportUseCaseProvider);
                      await useCase.exportAndShare(page, blocks, ext);
                    }
                    break;
                  case 'move_to_trash':
                    final deleteUseCase = ref.read(deletePageUseCaseProvider);
                    await deleteUseCase(pageId);
                    ref.invalidate(recentPagesProvider);
                    ref.invalidate(favoritePagesProvider);
                    if (context.mounted) {
                      context.pop();
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                if (page.isTemplate)
                  const PopupMenuItem(
                    value: 'use_template',
                    child: Text('Use Template'),
                  ),
                PopupMenuItem(
                  value: 'favorite',
                  child: Text(page.isFavorite ? 'Unfavorite' : 'Favorite'),
                ),
                const PopupMenuItem(
                  value: 'tags',
                  child: Text('Tags'),
                ),
                const PopupMenuItem(
                  value: 'collections',
                  child: Text('Collections'),
                ),
                const PopupMenuItem(
                  value: 'reminder',
                  child: Text('Reminder'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'export_md',
                  child: Text('Export as Markdown'),
                ),
                const PopupMenuItem(
                  value: 'export_html',
                  child: Text('Export as HTML'),
                ),
                const PopupMenuItem(
                  value: 'export_pdf',
                  child: Text('Export as PDF'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'move_to_trash',
                  child: Text('Move to Trash', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
