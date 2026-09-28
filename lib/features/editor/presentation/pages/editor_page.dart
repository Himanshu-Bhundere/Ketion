import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/block_editor_widget.dart';
import '../widgets/editor_top_bar.dart';

class EditorPage extends ConsumerWidget {
  final String pageId;
  final bool focusTitle;

  const EditorPage({
    super.key,
    required this.pageId,
    this.focusTitle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: EditorTopBar(pageId: pageId),
      body: BlockEditorWidget(
        pageId: pageId,
        focusTitle: focusTitle,
      ),
    );
  }
}
