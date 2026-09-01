import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../blocks/domain/entities/block.dart';
import '../providers/editor_state_provider.dart';
import 'block_wrapper.dart';
import 'blocks/text_block_widget.dart';
import 'blocks/list_block_widget.dart';
import 'blocks/image_block_widget.dart';
import 'blocks/file_block_widget.dart';
import 'floating_toolbar.dart';
import '../../../media/presentation/providers/media_picker_provider.dart';
import '../../domain/models/block_data_models.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

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
    ref
        .read(editorStateProvider(widget.pageId).notifier)
        .insertBlockAfter(existingBlock);
  }

  void _handleDeleteBlock(String blockId) {
    ref.read(editorStateProvider(widget.pageId).notifier).deleteBlock(blockId);
  }

  void _onReorder(int oldIndex, int newIndex) {
    ref
        .read(editorStateProvider(widget.pageId).notifier)
        .reorderBlocks(oldIndex, newIndex);
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

  Future<void> _addMedia(String type) async {
    final focusedId = ref.read(focusedBlockIdProvider);
    if (focusedId == null) return;
    
    final block = widget.blocks.firstWhere((b) => b.id == focusedId, orElse: () => widget.blocks.first);
    final mediaPicker = ref.read(mediaPickerProvider);
    
    Future<bool> handleSizeCheck(int sizeInBytes) async {
      final sizeMB = sizeInBytes / (1024 * 1024);
      if (sizeMB > 200) {
        return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Very Large File'),
            content: Text('This file is ${sizeMB.toStringAsFixed(1)} MB. Syncing might take a long time and use a lot of storage. Are you sure?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Import Anyway')),
            ],
          ),
        ) ?? false;
      } else if (sizeMB > 50) {
        return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Large File'),
            content: Text('This file is ${sizeMB.toStringAsFixed(1)} MB. Do you want to proceed?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Proceed')),
            ],
          ),
        ) ?? false;
      }
      return true;
    }

    final attachment = type == 'image' 
        ? await mediaPicker.pickImage(pageId: block.pageId, blockId: block.id, onCheckSize: handleSizeCheck)
        : await mediaPicker.pickFile(pageId: block.pageId, blockId: block.id, onCheckSize: handleSizeCheck);
        
    if (attachment != null) {
      final data = type == 'image' 
          ? jsonEncode(BlockDataModel.image(attachmentId: attachment.id).toJson()..remove('runtimeType'))
          : jsonEncode(BlockDataModel.file(attachmentId: attachment.id).toJson()..remove('runtimeType'));
          
      _handleBlockUpdate(block.copyWith(type: type, data: data));
    }
  }

  void _convertFocusedToHeading() {
    final focusedId = ref.read(focusedBlockIdProvider);
    if (focusedId == null) return;
    
    final block = widget.blocks.firstWhere((b) => b.id == focusedId, orElse: () => widget.blocks.first);
    if (block.type == 'text') {
      try {
        final Map<String, dynamic> json = jsonDecode(block.data) as Map<String, dynamic>;
        json['headingLevel'] = 1;
        _handleBlockUpdate(block.copyWith(data: jsonEncode(json)));
      } catch (_) {}
    }
  }

  void _convertFocusedToList() {
    final focusedId = ref.read(focusedBlockIdProvider);
    if (focusedId == null) return;
    
    final block = widget.blocks.firstWhere((b) => b.id == focusedId, orElse: () => widget.blocks.first);
    if (block.type == 'text') {
      try {
        final Map<String, dynamic> json = jsonDecode(block.data) as Map<String, dynamic>;
        final listData = BlockDataModel.list(
          spans: (json['spans'] as List?)?.map((e) => TextSpanData.fromJson(e as Map<String, dynamic>)).toList() ?? [],
          listType: 'bullet',
        );
        _handleBlockUpdate(
          block.copyWith(
            type: 'list',
            data: jsonEncode(listData.toJson()..remove('runtimeType')),
          ),
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          ref.read(editorStateProvider(widget.pageId).notifier).undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          ref.read(editorStateProvider(widget.pageId).notifier).undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): () {
          ref.read(editorStateProvider(widget.pageId).notifier).redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): () {
          ref.read(editorStateProvider(widget.pageId).notifier).redo();
        },
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
        Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.transparent,
          ),
          child: ReorderableListView.builder(
            scrollController: _scrollController,
            padding: EdgeInsets.only(
              left: 16.0, 
              right: 16.0, 
              top: 24.0, 
              bottom: isKeyboardVisible ? 80.0 : 24.0,
            ),
            itemCount: widget.blocks.length,
            itemBuilder: (context, index) {
              final block = widget.blocks[index];
              return _buildBlockWidget(block, index);
            },
            onReorder: _onReorder,
            buildDefaultDragHandles: false,
          ),
        ),
        if (isKeyboardVisible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingToolbar(
              onAddHeading: _convertFocusedToHeading,
              onAddList: _convertFocusedToList,
              onAddImage: () => _addMedia('image'),
              onAddFile: () => _addMedia('file'),
            ),
          ),
      ],
        ),
      ),
    );
  }
}
