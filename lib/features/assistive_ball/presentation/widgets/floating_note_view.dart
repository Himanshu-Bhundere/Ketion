import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/result.dart';
import '../../../blocks/domain/entities/block.dart';
import '../../../blocks/presentation/providers/block_providers.dart';
import '../../../pages/domain/entities/page.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import '../providers/assistive_ball_provider.dart';

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
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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

      if (pageResult is Success<void> && content.isNotEmpty) {
        final blockRepo = ref.read(blockRepositoryProvider);
        await blockRepo.createBlock(
          Block(
            id: const Uuid().v4(),
            pageId: pageId,
            type: 'text',
            position: 1000.0,
            data: '{"text":${_jsonEncode(content)}}',
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      ref.invalidate(recentPagesProvider);
      ref.invalidate(favoritePagesProvider);

      if (mounted) {
        ref.read(assistiveBallProvider.notifier).closeFloatingNote();
      }
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _jsonEncode(String text) {
    return '"${text.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
  }

  @override
  Widget build(BuildContext context) {
    final ballState = ref.watch(assistiveBallProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final width = ballState.floatingNoteWidth.clamp(
      280.0,
      widget.parentConstraints.maxWidth - 32,
    );
    final height = ballState.floatingNoteHeight.clamp(
      240.0,
      widget.parentConstraints.maxHeight - 48,
    );

    final left = (ballState.floatingNoteNormalizedX *
            (widget.parentConstraints.maxWidth - width))
        .clamp(16.0, widget.parentConstraints.maxWidth - width - 16.0);
    final top = (ballState.floatingNoteNormalizedY *
            (widget.parentConstraints.maxHeight - height))
        .clamp(24.0, widget.parentConstraints.maxHeight - height - 24.0);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Material(
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
              // Draggable Header Bar
              GestureDetector(
                onPanUpdate: (details) {
                  final newX = (left + details.delta.dx) /
                      (widget.parentConstraints.maxWidth - width);
                  final newY = (top + details.delta.dy) /
                      (widget.parentConstraints.maxHeight - height);
                  ref
                      .read(assistiveBallProvider.notifier)
                      .updateFloatingNotePosition(newX, newY);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: isDark
                      ? const Color(0xFF2D3035)
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Icon(
                        Icons.drag_indicator,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ballState.activePageId != null
                              ? 'Note Preview'
                              : 'Quick Capture',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ballState.activePageId != null)
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 18),
                          tooltip: 'Open in Editor',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final pageId = ballState.activePageId!;
                            ref
                                .read(assistiveBallProvider.notifier)
                                .closeFloatingNote();
                            context.pushNamed(
                              Routes.editorName,
                              pathParameters: {'pageId': pageId},
                            );
                          },
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.minimize, size: 18),
                        tooltip: 'Minimize',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ref
                              .read(assistiveBallProvider.notifier)
                              .minimizeFloatingNote();
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Close',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ref
                              .read(assistiveBallProvider.notifier)
                              .closeFloatingNote();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body (Scrollable)
              Expanded(
                child: ballState.activePageId != null
                    ? _buildActiveNoteViewer(ballState.activePageId!, theme)
                    : _buildQuickCaptureForm(theme),
              ),

              // Bottom Resize Bar
              Container(
                height: 20,
                color: Colors.transparent,
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    ref
                        .read(assistiveBallProvider.notifier)
                        .updateFloatingNoteSize(
                          width + details.delta.dx,
                          height + details.delta.dy,
                        );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: Icon(
                      Icons.south_east,
                      size: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: blocks.map((b) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _extractBlockText(b.data),
                            style: theme.textTheme.bodyMedium,
                          ),
                        );
                      }).toList(),
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

  String _extractBlockText(String data) {
    try {
      if (data.contains('"text":')) {
        final match = RegExp(r'"text":\s*"([^"]*)"').firstMatch(data);
        if (match != null) {
          return match.group(1)?.replaceAll(r'\n', '\n') ?? '';
        }
      }
      return data;
    } catch (_) {
      return data;
    }
  }

  Widget _buildQuickCaptureForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
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
