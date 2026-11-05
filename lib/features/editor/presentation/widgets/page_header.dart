import 'dart:io' as io;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../../media/presentation/providers/attachment_provider.dart';
import '../../../media/presentation/providers/media_picker_provider.dart';
import '../../../pages/domain/entities/page.dart' as entity;
import 'editable_page_title.dart';

class PageHeader extends ConsumerWidget {
  final entity.Page page;
  final bool focusTitle;
  final Future<Result<void>> Function(String title) onTitleChanged;
  final Future<Result<void>> Function(String icon) onIconChanged;
  final Future<Result<void>> Function(String? coverImage)? onCoverChanged;

  const PageHeader({
    super.key,
    required this.page,
    required this.onTitleChanged,
    required this.onIconChanged,
    this.onCoverChanged,
    this.focusTitle = false,
  });

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SizedBox(
        height: 300,
        child: EmojiPicker(
          onEmojiSelected: (_, emoji) async {
            final result = await onIconChanged(emoji.emoji);
            if (ctx.mounted && result is Success<void>) Navigator.pop(ctx);
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
    );
  }

  Future<void> _pickCover(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ref.read(mediaPickerProvider);
      final attachment = await picker.pickCoverImage(pageId: page.id);
      if (attachment != null) {
        await onCoverChanged?.call(attachment.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set cover image: $e')),
        );
      }
    }
  }

  Widget _buildCoverImage(BuildContext context, WidgetRef ref, String cover) {
    if (cover.startsWith('http://') || cover.startsWith('https://')) {
      return Image.network(
        cover,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 160,
        errorBuilder: (_, __, ___) => const Center(
          child: Text('Could not load image from network'),
        ),
      );
    }

    final attachmentAsync = ref.watch(attachmentProvider(cover));
    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          return const Center(child: Text('Cover image not found'));
        }
        final pathAsync = ref.watch(attachmentPathProvider(attachment));
        return pathAsync.when(
          data: (localPath) {
            if (localPath == null || localPath.isEmpty) {
              return const Center(child: Text('Cover image file not found'));
            }
            if (kIsWeb) {
              return Image.network(
                localPath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 160,
              );
            }
            return Image.file(
              io.File(localPath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 160,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('Could not render cover image'),
              ),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (_, __) =>
              const Center(child: Text('Error loading cover file')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (_, __) => const Center(child: Text('Error loading cover')),
    );
  }

  Widget _buildCoverSection(BuildContext context, WidgetRef ref) {
    final cover = page.coverImage!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Container(
              height: 160,
              width: double.infinity,
              color: Colors.grey.withValues(alpha: 0.15),
              child: _buildCoverImage(context, ref, cover),
            ),
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
                      onPressed: () => _pickCover(context, ref),
                      icon: const Icon(Icons.image_outlined, size: 14),
                      label: const Text(
                        'Change cover',
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
                      onPressed: () => onCoverChanged?.call(null),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final hasIcon = page.icon != null && page.icon!.isNotEmpty;
    final hasCover = page.coverImage != null && page.coverImage!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasCover) _buildCoverSection(context, ref),
          if (hasIcon)
            GestureDetector(
              onTap: () => _showEmojiPicker(context),
              onLongPress: () => onIconChanged(''),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  page.icon!,
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
                      onPressed: () => _pickCover(context, ref),
                      icon: const Icon(Icons.image_outlined, size: 16),
                      label: const Text('Add Cover'),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          EditablePageTitle(
            page: page,
            autofocus: focusTitle,
            onTitleChanged: onTitleChanged,
          ),
        ],
      ),
    );
  }
}
