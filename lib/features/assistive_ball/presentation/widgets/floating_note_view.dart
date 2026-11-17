import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/logger.dart';
import '../../../blocks/domain/entities/block.dart';
import '../../../blocks/presentation/providers/block_providers.dart';
import '../../../editor/domain/models/block_data_models.dart';
import '../../../pages/domain/entities/page.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import '../../../pages/presentation/widgets/page_cover_image.dart';
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
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _contentFocusNode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _titleFocusNode = FocusNode(
      onKeyEvent: (node, event) =>
          _handleBackspaceOrDelete(_titleController, event),
    );
    _contentFocusNode = FocusNode(
      onKeyEvent: (node, event) =>
          _handleBackspaceOrDelete(_contentController, event),
    );
  }

  KeyEventResult _handleBackspaceOrDelete(
    TextEditingController controller,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isBackspace = event.logicalKey == LogicalKeyboardKey.backspace;
    final isDelete = event.logicalKey == LogicalKeyboardKey.delete;

    if (!isBackspace && !isDelete) {
      return KeyEventResult.ignored;
    }

    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) {
      return KeyEventResult.ignored;
    }

    void syncEditingValue(String newText, int newOffset) {
      final newValue = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
        composing: TextRange.empty,
      );
      controller.value = newValue;
      SystemChannels.textInput.invokeMethod<void>(
        'TextInput.setEditingState',
        newValue.toJSON(),
      );
    }

    // Range selection: delete entire highlighted segment
    if (!selection.isCollapsed) {
      final start = math.min(selection.start, selection.end);
      final end = math.max(selection.start, selection.end);
      if (start >= 0 && end <= text.length && start != end) {
        final newText = text.replaceRange(start, end, '');
        syncEditingValue(newText, start);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final cursor = selection.baseOffset;

    if (isBackspace) {
      if (cursor <= 0) {
        return KeyEventResult.handled;
      }

      // Word deletion on Ctrl + Backspace
      final isCtrl = HardwareKeyboard.instance.isControlPressed;
      if (isCtrl) {
        int newCursor = cursor - 1;
        while (newCursor > 0 && text[newCursor - 1].trim().isEmpty) {
          newCursor--;
        }
        while (newCursor > 0 && text[newCursor - 1].trim().isNotEmpty) {
          newCursor--;
        }
        final newText = text.replaceRange(newCursor, cursor, '');
        syncEditingValue(newText, newCursor);
        return KeyEventResult.handled;
      }

      // Single character deletion (supporting UTF-16 surrogate pairs safely)
      final charLength = (cursor >= 2 &&
              text.codeUnitAt(cursor - 1) >= 0xDC00 &&
              text.codeUnitAt(cursor - 1) <= 0xDFFF &&
              text.codeUnitAt(cursor - 2) >= 0xD800 &&
              text.codeUnitAt(cursor - 2) <= 0xDBFF)
          ? 2
          : 1;

      final deleteStart = (cursor - charLength).clamp(0, text.length);
      final newText = text.replaceRange(deleteStart, cursor, '');
      syncEditingValue(newText, deleteStart);
      return KeyEventResult.handled;
    } else if (isDelete) {
      if (cursor >= text.length) {
        return KeyEventResult.handled;
      }

      final charLength = (cursor + 1 < text.length &&
              text.codeUnitAt(cursor) >= 0xD800 &&
              text.codeUnitAt(cursor) <= 0xDBFF &&
              text.codeUnitAt(cursor + 1) >= 0xDC00 &&
              text.codeUnitAt(cursor + 1) <= 0xDFFF)
          ? 2
          : 1;

      final deleteEnd = (cursor + charLength).clamp(0, text.length);
      final newText = text.replaceRange(cursor, deleteEnd, '');
      syncEditingValue(newText, cursor);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _resetQuickNoteFields() {
    _titleController.clear();
    _contentController.clear();
  }

  Future<void> _saveQuickNote() async {
    final title = _titleController.text.trim();
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
                if (page.coverImage != null && page.coverImage!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: PageCoverImage(
                        pageId: page.id,
                        coverImage: page.coverImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: 14.0,
        right: 14.0,
        top: 14.0,
        bottom: math.max(14.0, viewInsets.bottom > 0 ? 8.0 : 14.0),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            TextField(
              key: const ValueKey('quick_note_title_input'),
              controller: _titleController,
              focusNode: _titleFocusNode,
              autocorrect: false,
              enableSuggestions: false,
              spellCheckConfiguration:
                  const SpellCheckConfiguration.disabled(),
              keyboardType: TextInputType.text,
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
                key: const ValueKey('quick_note_content_input'),
                controller: _contentController,
                focusNode: _contentFocusNode,
                autocorrect: false,
                enableSuggestions: false,
                spellCheckConfiguration:
                    const SpellCheckConfiguration.disabled(),
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
            const SizedBox(height: 4),
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
      ),
    );
  }
}
