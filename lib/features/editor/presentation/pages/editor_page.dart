import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/editor_state_provider.dart';
import '../widgets/block_editor_widget.dart';
import 'package:ketion/features/tags/presentation/widgets/tag_picker_sheet.dart';
import 'package:ketion/features/collections/presentation/widgets/collection_picker_sheet.dart';
import 'package:ketion/features/reminders/presentation/widgets/reminder_picker_sheet.dart';
import 'package:ketion/features/tags/domain/entities/tag.dart';
import 'package:ketion/features/collections/domain/entities/collection.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:ketion/features/import_export/presentation/providers/import_export_providers.dart';

class EditorPage extends ConsumerWidget {
  final String pageId;

  const EditorPage({
    super.key,
    required this.pageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(editorStateProvider(pageId));
    final pageAsync = ref.watch(pageProvider(pageId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: [
          pageAsync.when(
            data: (page) {
              if (page == null) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (page.isTemplate)
                    TextButton.icon(
                      icon: const Icon(Icons.file_copy, color: Colors.white),
                      label: const Text('Use Template',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        final createUseCase =
                            ref.read(createPageUseCaseProvider);
                        final result = await createUseCase(
                          title: page.title,
                          isTemplate: false,
                          icon: page.icon,
                          coverImage: page.coverImage,
                          parentPageId: page.parentPageId,
                        );
                        final newPage = result.valueOrNull;
                        if (newPage == null) return;

                        final blocks =
                            ref.read(editorStateProvider(pageId)).valueOrNull ??
                                [];
                        final updateBlockUseCase =
                            ref.read(updateBlockUseCaseProvider);

                        // Map old block ID to new block ID for parent-child relationships
                        final idMap = <String, String>{};
                        for (final b in blocks) {
                          idMap[b.id] = const Uuid().v7();
                        }

                        for (final b in blocks) {
                          final newBlockId = idMap[b.id]!;
                          final newParentId = b.parentBlockId != null
                              ? idMap[b.parentBlockId]
                              : null;

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
                      },
                    ),
                  IconButton(
                    icon:
                        Icon(page.isFavorite ? Icons.star : Icons.star_border),
                    onPressed: () {
                      final updatedPage =
                          page.copyWith(isFavorite: !page.isFavorite);
                      ref
                          .read(updatePageUseCaseProvider)(updatedPage)
                          .then((_) {
                        ref.invalidate(pageProvider(pageId));
                      });
                    },
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
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
          IconButton(
            icon: const Icon(Icons.label_outline),
            onPressed: () {
              showModalBottomSheet<Tag>(
                context: context,
                builder: (context) => const TagPickerSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            onPressed: () {
              showModalBottomSheet<Collection>(
                context: context,
                builder: (context) => const CollectionPickerSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.alarm_add),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (context) => ReminderPickerSheet(pageId: pageId),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value.startsWith('export_')) {
                final ext = value.split('_')[1];
                final page = pageAsync.valueOrNull;
                final blocks = blocksAsync.valueOrNull;
                if (page != null && blocks != null) {
                  final useCase = ref.read(exportUseCaseProvider);
                  await useCase.exportAndShare(page, blocks, ext);
                }
              }
            },
            itemBuilder: (context) => [
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
            ],
          ),
        ],
      ),
      body: BlockEditorWidget(
        pageId: pageId,
      ),
    );
  }
}
