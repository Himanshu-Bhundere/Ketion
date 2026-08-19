import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/editor_state_provider.dart';
import '../widgets/block_editor_widget.dart';

class EditorPage extends ConsumerWidget {
  final String pageId;

  const EditorPage({
    super.key,
    required this.pageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(editorStateProvider(pageId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Page settings / info
            },
          ),
        ],
      ),
      body: blocksAsync.when(
        data: (blocks) {
          return BlockEditorWidget(
            pageId: pageId,
            blocks: blocks,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
