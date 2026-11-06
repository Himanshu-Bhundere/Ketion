import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../../media/presentation/providers/media_picker_provider.dart';
import '../../../pages/domain/entities/page.dart' as entity;
import '../../../pages/presentation/providers/page_providers.dart';
import '../../../pages/presentation/widgets/page_cover_image.dart';
import 'editable_page_title.dart';

class PageHeader extends ConsumerStatefulWidget {
  final entity.Page page;
  final bool focusTitle;
  final Future<Result<void>> Function(String title) onTitleChanged;
  final Future<Result<void>> Function(String icon) onIconChanged;
  final Future<Result<void>> Function(String? coverImage)? onCoverChanged;
  final Future<Result<void>> Function(double offset)? onCoverPositionChanged;

  const PageHeader({
    super.key,
    required this.page,
    required this.onTitleChanged,
    required this.onIconChanged,
    this.onCoverChanged,
    this.onCoverPositionChanged,
    this.focusTitle = false,
  });

  @override
  ConsumerState<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends ConsumerState<PageHeader> {
  bool _isRepositioning = false;
  double? _draftOffset;

  void _showEmojiPicker(BuildContext context) {
    final hasIcon = widget.page.icon != null && widget.page.icon!.isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIcon)
              ListTile(
                dense: true,
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Remove icon',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await widget.onIconChanged('');
                },
              ),
            SizedBox(
              height: 300,
              child: EmojiPicker(
                onEmojiSelected: (_, emoji) async {
                  final result = await widget.onIconChanged(emoji.emoji);
                  if (ctx.mounted && result is Success<void>) {
                    Navigator.pop(ctx);
                  }
                },
                config: const Config(
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 32 * (kIsWeb ? 1.2 : 1.15),
                  ),
                  bottomActionBarConfig: BottomActionBarConfig(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCover(BuildContext context) async {
    try {
      final picker = ref.read(mediaPickerProvider);
      final attachment = await picker.pickCoverImage(pageId: widget.page.id);
      if (attachment != null) {
        await widget.onCoverChanged?.call(attachment.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set cover image: $e')),
        );
      }
    }
  }

  Future<void> _saveCoverPosition(double offset) async {
    try {
      Result<void> result;
      if (widget.onCoverPositionChanged != null) {
        result = await widget.onCoverPositionChanged!(offset);
      } else {
        result = await ref
            .read(pageRepositoryProvider)
            .updateCoverPosition(widget.page.id, offset);
      }
      if (result is Error) {
        throw Exception(result.failure.toString());
      }
      if (mounted) {
        setState(() {
          _isRepositioning = false;
          _draftOffset = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save cover position: $e')),
        );
      }
    }
  }

  Widget _buildCoverSection(BuildContext context) {
    final cover = widget.page.coverImage!;
    final coverHeight = MediaQuery.sizeOf(context).width < 600 ? 180.0 : 240.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            PageCoverImage(
              pageId: widget.page.id,
              coverImage: cover,
              height: coverHeight,
              width: double.infinity,
              isRepositioning: _isRepositioning,
              draftOffset: _draftOffset,
              onDraftOffsetChanged: (newOffset) {
                setState(() => _draftOffset = newOffset);
              },
              showRepositionControls: _isRepositioning,
              onSaveOffset: _saveCoverPosition,
              onCancelReposition: () {
                setState(() {
                  _isRepositioning = false;
                  _draftOffset = null;
                });
              },
            ),
            if (!_isRepositioning)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _pickCover(context),
                        icon: const Icon(Icons.image_outlined, size: 14),
                        label: const Text(
                          'Change cover',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            _isRepositioning = true;
                            _draftOffset = null;
                          });
                        },
                        icon: const Icon(Icons.swap_vert, size: 14),
                        label: const Text(
                          'Reposition',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                        tooltip: 'Remove cover',
                        onPressed: () => widget.onCoverChanged?.call(null),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasIcon = widget.page.icon != null && widget.page.icon!.isNotEmpty;
    final hasCover =
        widget.page.coverImage != null && widget.page.coverImage!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasCover) _buildCoverSection(context),
          if (hasIcon)
            GestureDetector(
              onTap: () => _showEmojiPicker(context),
              onLongPress: () => widget.onIconChanged(''),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  widget.page.icon!,
                  style: const TextStyle(fontSize: 64, height: 1),
                ),
              ),
            ),
          if (!hasIcon || !hasCover)
            Row(
              children: [
                if (!hasIcon)
                  Semantics(
                    label: 'Add Icon',
                    button: true,
                    child: TextButton.icon(
                      onPressed: () => _showEmojiPicker(context),
                      icon: const Icon(Icons.emoji_emotions_outlined, size: 16),
                      label: const Text('Add Icon'),
                    ),
                  ),
                if (!hasCover)
                  Semantics(
                    label: 'Add Cover',
                    button: true,
                    child: TextButton.icon(
                      onPressed: () => _pickCover(context),
                      icon: const Icon(Icons.image_outlined, size: 16),
                      label: const Text('Add Cover'),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          EditablePageTitle(
            page: widget.page,
            autofocus: widget.focusTitle,
            onTitleChanged: widget.onTitleChanged,
          ),
        ],
      ),
    );
  }
}
