import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/result.dart';
import '../../../pages/domain/entities/page.dart' as entity;
import 'editable_page_title.dart';

class PageHeader extends StatelessWidget {
  final entity.Page page;
  final bool focusTitle;
  final Future<Result<void>> Function(String title) onTitleChanged;
  final Future<Result<void>> Function(String icon) onIconChanged;

  const PageHeader({
    super.key,
    required this.page,
    required this.onTitleChanged,
    required this.onIconChanged,
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

  @override
  Widget build(BuildContext context) {
    final hasIcon = page.icon != null && page.icon!.isNotEmpty;
    final hasCover = page.coverImage != null && page.coverImage!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
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
              child: const Center(child: Text('Cover Placeholder')),
            ),
          if (hasIcon)
            GestureDetector(
              onTap: () => _showEmojiPicker(context),
              onLongPress: () => onIconChanged(''),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(page.icon!, style: const TextStyle(fontSize: 64, height: 1)),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('Add Cover (coming soon)', style: TextStyle(color: Colors.grey)),
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
