import 'dart:convert';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/logger.dart';
import '../../../blocks/domain/entities/block.dart';
import '../../../blocks/presentation/providers/block_providers.dart';
import '../../../editor/domain/models/block_data_models.dart';
import '../../../pages/domain/entities/page.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import '../providers/assistive_ball_provider.dart';
import 'assistive_ball_header_button.dart';
import 'rich_block_preview.dart';

class FloatingNoteView extends ConsumerStatefulWidget {
  final BoxConstraints parentConstraints;

  const FloatingNoteView({
    super.key,
    required this.parentConstraints,
  });

  @override
  ConsumerState<FloatingNoteView> createState() => _FloatingNoteViewState();
}

class _FloatingNoteViewState extends ConsumerState<FloatingNoteView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _quickTitle = '';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _resetQuickNoteFields() {
    _titleController.clear();
    _contentController.clear();
    _quickTitle = '';
  }

  Future<void> _saveQuickNote() async {
    final title = _quickTitle.trim().isNotEmpty
        ? _quickTitle.trim()
        : _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      ref.read(assistiveBallProvider.notifier).closeFloatingNote();
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().toUtc();
      final pageId = const Uuid().v4();
      final page = Page(
        id: pageId,
        title: title.isEmpty ? 'Quick Note' : title,
        createdAt: now,
        updatedAt: now,
      );

      final pageRepo = ref.read(pageRepositoryProvider);
      final pageResult = await pageRepo.createPage(page);

      if (pageResult.isError) {
        appLogger.e(
          'Failed to create quick note page: ${pageResult.errorOrNull?.message}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save quick note page')),
          );
        }
        return;
      }

      if (content.isNotEmpty) {
        final blockRepo = ref.read(blockRepositoryProvider);
        final blockResult = await blockRepo.createBlock(
          Block(
            id: const Uuid().v4(),
            pageId: pageId,
            type: 'text',
            position: 1000.0,
            data: jsonEncode(
              BlockDataModel.text(
                spans: [
                  TextSpanData(text: content),
                ],
              ).toJson()
                ..remove('runtimeType'),
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );

        if (blockResult.isError) {
          appLogger.e(
            'Failed to create quick note block: ${blockResult.errorOrNull?.message}',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save quick note content'),
              ),
            );
          }
          return;
        }
      }

      // Refresh homepage and recent-note consumers.
      ref.invalidate(recentPagesProvider);

      // Refresh the Note Selector, which reads allPagesProvider.
      ref.invalidate(allPagesProvider);

      // Refresh favorite-note consumers.
      ref.invalidate(favoritePagesProvider);

      if (mounted) {
        _resetQuickNoteFields();
        ref.read(assistiveBallProvider.notifier).closeFloatingNote();
      }
    } catch (e, st) {
      appLogger.e('Unexpected error saving quick note', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ballState = ref.watch(assistiveBallProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: isDark ? const Color(0xFF222428) : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            // Attached Note Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark
                  ? const Color(0xFF2D3035)
                  : theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  if (ballState.activePageId != null) ...[
                    AssistiveBallHeaderButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Back to Note Selector',
                      onPressed: () {
                        ref
                            .read(assistiveBallProvider.notifier)
                            .returnToNoteSelector();
                      },
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note Preview',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.edit_note,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quick Note',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AssistiveBallHeaderButton(
                      icon: Icons.close,
                      tooltip: 'Close Quick Note',
                      onPressed: () {
                        ref
                            .read(assistiveBallProvider.notifier)
                            .closeFloatingNote();
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Content Body (Scrollable)
            Expanded(
              child: ballState.activePageId != null
                  ? _buildActiveNoteViewer(ballState.activePageId!, theme)
                  : _buildQuickCaptureForm(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveNoteViewer(String pageId, ThemeData theme) {
    final pageAsync = ref.watch(pageProvider(pageId));
    final blocksAsync = ref.watch(pageBlocksProvider(pageId));

    return pageAsync.when(
      data: (page) {
        if (page == null) {
          return const Center(child: Text('Note not found'));
        }

        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (page.icon != null && page.icon!.isNotEmpty)
                  Text(page.icon!, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  page.title.isEmpty ? 'Untitled' : page.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                blocksAsync.when(
                  data: (blocks) {
                    if (blocks.isEmpty) {
                      return Text(
                        'Empty note',
                        style: TextStyle(color: theme.hintColor),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(blocks.length, (index) {
                        final block = blocks[index];

                        int ordinal = 1;

                        if (block.type == 'list') {
                          final data = _decodeBlockData(block.data);
                          if (data['listType'] == 'numbered') {
                            for (int i = index - 1; i >= 0; i--) {
                              final previous = blocks[i];

                              if (previous.type != 'list') break;

                              final previousData =
                                  _decodeBlockData(previous.data);

                              if (previousData['listType'] != 'numbered') {
                                break;
                              }

                              ordinal++;
                            }
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: RichBlockPreview(
                            key: ValueKey(block.id),
                            block: block,
                            listOrdinal: ordinal,
                          ),
                        );
                      }),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Text('Error loading content: $err'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Map<String, dynamic> _decodeBlockData(String data) {
    try {
      final decoded = jsonDecode(data);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (error, stackTrace) {
      appLogger.e('Failed to decode preview block', error, stackTrace);
    }

    return {};
  }

  Widget _buildQuickCaptureForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            onChanged: (value) {
              _quickTitle = value;
            },
            decoration: const InputDecoration(
              hintText: 'Note title...',
              border: InputBorder.none,
              isDense: true,
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 12),
          Expanded(
            child: TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Type your thoughts here...',
                border: InputBorder.none,
              ),
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : _saveQuickNote,
                child: Text(_isSaving ? 'Saving...' : 'Save Note'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
