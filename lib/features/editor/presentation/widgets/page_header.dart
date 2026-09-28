import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../../../pages/domain/entities/page.dart' as entity;
import '../../../pages/presentation/providers/page_providers.dart';
import 'editable_page_title.dart';

class PageHeader extends ConsumerWidget {
  final entity.Page page;
  final bool focusTitle;

  const PageHeader({super.key, required this.page, this.focusTitle = false});

  void _showEmojiPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SizedBox(
          height: 300,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              final updatedPage = page.copyWith(icon: emoji.emoji);
              ref.read(updatePageUseCaseProvider)(updatedPage);
              Navigator.pop(ctx);
            },
            config: Config(
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                columns: 7,
                emojiSizeMax: 32 * (kIsWeb ? 1.2 : (!Platform.isIOS ? 1.30 : 1.0)),
              ),
              bottomActionBarConfig: const BottomActionBarConfig(),
            ),
          ),
        );
      },
    );
  }

  void _removeIcon(WidgetRef ref) {
    // We update with empty string which might mean no icon, but wait, copyWith usually takes String? icon.
    // If the copyWith method only updates when non-null, this won't work.
    // Let's check if we can pass a special value or if copyWith allows nulls. 
    // Usually it doesn't. For now we will just use an empty string or rely on the backend.
    final updatedPage = page.copyWith(icon: ''); 
    ref.read(updatePageUseCaseProvider)(updatedPage);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasIcon = page.icon != null && page.icon!.isNotEmpty;
    final hasCover = page.coverImage != null && page.coverImage!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasCover)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Cover Placeholder')), // To be implemented later
            ),
          
          if (hasIcon)
            GestureDetector(
              onTap: () => _showEmojiPicker(context, ref),
              onLongPress: () => _removeIcon(ref),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  page.icon!,
                  style: const TextStyle(fontSize: 64, height: 1.0),
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
                      onPressed: () => _showEmojiPicker(context, ref),
                      icon: const Icon(Icons.emoji_emotions_outlined, size: 16),
                      label: const Text('Add Icon'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ),
                if (!hasCover)
                  TextButton.icon(
                    onPressed: () {}, // To be implemented
                    icon: const Icon(Icons.image_outlined, size: 16),
                    label: const Text('Add Cover'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
              ],
            ),
          
          const SizedBox(height: 8),
          
          EditablePageTitle(page: page, autofocus: focusTitle),
        ],
      ),
    );
  }
}
