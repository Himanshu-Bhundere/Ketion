import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../blocks/domain/entities/block.dart';
import '../providers/editor_state_provider.dart';
import 'block_wrapper.dart';
import 'blocks/text_block_widget.dart';
import 'blocks/list_block_widget.dart';
import 'blocks/image_block_widget.dart';
import 'blocks/file_block_widget.dart';

class BlockEditorWidget extends ConsumerStatefulWidget {
  final String pageId;
  final List<Block> blocks;

  const BlockEditorWidget({
    super.key,
    required this.pageId,
    required this.blocks,
  });

  @override
  ConsumerState<BlockEditorWidget> createState() => _BlockEditorWidgetState();
}

class _BlockEditorWidgetState extends ConsumerState<BlockEditorWidget> {
  final ScrollController _scrollController = ScrollController();

  void _handleBlockUpdate(Block block) {
    ref.read(editorStateProvider(widget.pageId).notifier).updateBlock(block);
  }

  void _handleInsertBlock(Block existingBlock) {
    ref.read(editorStateProvider(widget.pageId).notifier).insertBlockAfter(existingBlock);
  }

  void _handleDeleteBlock(String blockId) {
    ref.read(editorStateProvider(widget.pageId).notifier).deleteBlock(blockId);
  }

  void _onReorder(int oldIndex, int newIndex) {
    ref.read(editorStateProvider(widget.pageId).notifier).reorderBlocks(oldIndex, newIndex);
  }

  Widget _buildBlockWidget(Block block, int index) {
    // Factory method for rendering different block types
    Widget content;
    switch (block.type) {
      case 'list':
        content = ListBlockWidget(
          block: block,
          onUpdate: _handleBlockUpdate,
          onSplit: () => _handleInsertBlock(block),
          onMergePrevious: () {
            if (index > 0) {
              _handleDeleteBlock(block.id);
            }
          },
        );
        break;
      case 'image':
        content = ImageBlockWidget(
          block: block,
          onUpdate: _handleBlockUpdate,
        );
        break;
      case 'file':
        content = FileBlockWidget(
          block: block,
          onUpdate: _handleBlockUpdate,
        );
        break;
      case 'text':
      default:
        content = TextBlockWidget(
          block: block,
          onUpdate: _handleBlockUpdate,
          onSplit: () => _handleInsertBlock(block),
          onMergePrevious: () {
            if (index > 0) {
              _handleDeleteBlock(block.id);
            }
          },
        );
    }

    return BlockWrapper(
      key: ValueKey(block.id),
      blockId: block.id,
      index: index,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
      ),
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        itemCount: widget.blocks.length,
        itemBuilder: (context, index) {
          final block = widget.blocks[index];
          return _buildBlockWidget(block, index);
        },
        onReorder: _onReorder,
        buildDefaultDragHandles: false, // We'll build custom drag handles in BlockWrapper
      ),
    );
  }
}
