import 'package:flutter/material.dart';
import '../../../../core/utils/result.dart';
import 'block_editor_widget.dart';
import 'super_editor_host.dart';

class KetionEditorHost extends StatelessWidget {
  final String pageId;
  final bool focusTitle;
  final Future<Result<void>> Function(String) onTitleChanged;
  final Future<Result<void>> Function(String) onIconChanged;

  const KetionEditorHost({
    super.key,
    required this.pageId,
    required this.onTitleChanged,
    required this.onIconChanged,
    this.focusTitle = false,
  });

  // Development-only migration switch.
  static const bool useSuperEditor = true;

  @override
  Widget build(BuildContext context) {
    if (useSuperEditor) {
      return SuperEditorHost(
        pageId: pageId,
        focusTitle: focusTitle,
        onTitleChanged: onTitleChanged,
        onIconChanged: onIconChanged,
      );
    } else {
      return BlockEditorWidget(
        pageId: pageId,
        focusTitle: focusTitle,
        onTitleChanged: onTitleChanged,
        onIconChanged: onIconChanged,
      );
    }
  }
}
