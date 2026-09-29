import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../blocks/domain/entities/block.dart';
import '../providers/editor_state_provider.dart';
import 'block_wrapper.dart';
import 'blocks/text_block_widget.dart';
import 'blocks/list_block_widget.dart';
import 'blocks/image_block_widget.dart';
import 'blocks/video_block_widget.dart';
import 'blocks/audio_block_widget.dart';
import 'blocks/pdf_block_widget.dart';
import 'blocks/file_block_widget.dart';
import 'floating_toolbar.dart';
import '../../../media/presentation/providers/media_picker_provider.dart';
import '../../domain/models/block_data_models.dart';
import '../../domain/models/visible_block.dart';
import '../../../media/data/repositories/attachment_repository_impl.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../../core/theme/editor_layout_config.dart';
import '../../../../core/utils/result.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import 'page_header.dart';

class BlockEditorWidget extends ConsumerStatefulWidget {
  final String pageId;
  final bool focusTitle;
  final Future<Result<void>> Function(String title) onTitleChanged;
  final Future<Result<void>> Function(String icon) onIconChanged;

  const BlockEditorWidget({
    super.key,
    required this.pageId,
    required this.onTitleChanged,
    required this.onIconChanged,
    this.focusTitle = false,
  });

  @override
  ConsumerState<BlockEditorWidget> createState() => _BlockEditorWidgetState();
}

class _BlockEditorWidgetState extends ConsumerState<BlockEditorWidget> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  double _scrollDelta = 0.0;

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBlockDragUpdate(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final localPosition = renderBox.globalToLocal(globalPosition);
    final height = renderBox.size.height;
    
    const edgeThreshold = 60.0;
    const scrollAmount = 10.0;
    
    if (localPosition.dy < edgeThreshold) {
      _startAutoScroll(-scrollAmount);
    } else if (localPosition.dy > height - edgeThreshold) {
      _startAutoScroll(scrollAmount);
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll(double delta) {
    if (_autoScrollTimer != null && _autoScrollTimer!.isActive) {
      _scrollDelta = delta;
      return;
    }
    
    _scrollDelta = delta;
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_scrollController.hasClients) return;
      
      final currentScroll = _scrollController.offset;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final minScroll = _scrollController.position.minScrollExtent;
      
      final newScroll = (currentScroll + _scrollDelta).clamp(minScroll, maxScroll);
      if (newScroll != currentScroll) {
        _scrollController.jumpTo(newScroll);
      } else {
        _stopAutoScroll();
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _handleBlockUpdate(Block block) {
    ref.read(editorStateProvider(widget.pageId).notifier).updateBlock(block);
  }

  void _handleInsertBlock(Block existingBlock, {String type = 'text'}) {
    ref
        .read(editorStateProvider(widget.pageId).notifier)
        .insertBlockAfter(existingBlock, type: type);
  }

  Future<void> _handleSplitBlock(Block block, String before, String after) {
    return ref
        .read(editorStateProvider(widget.pageId).notifier)
        .splitTextBlock(block, before, after);
  }

  Future<void> _handleMergeBlockWithPrevious(Block block, String textToMerge) {
    return ref
        .read(editorStateProvider(widget.pageId).notifier)
        .mergeBlockWithPrevious(block, textToMerge);
  }

  Widget _buildBlockWidget(VisibleBlock visibleBlock, int index) {
    final block = visibleBlock.block;

    Widget content;
    switch (block.type) {
      case 'list':
        content = ListBlockWidget(
          block: block,
          onUpdate: _handleBlockUpdate,
          onSplit: (before, after) => ref.read(editorStateProvider(widget.pageId).notifier).splitListBlock(block, before, after),
          onMergePrevious: (text) => _handleMergeBlockWithPrevious(block, text),
        );
        break;
      case 'image':
        content = ImageBlockWidget(
          block: block,
          onUpdate: _handleBlockUpdate,
        );
        break;
      case 'video':
        content = VideoBlockWidget(
          block: block,
          onUpdate: _handleBlockUpdate,
        );
        break;
      case 'audio':
        content = AudioBlockWidget(
          block: block,
          onUpdate: _handleBlockUpdate,
        );
        break;
      case 'pdf':
        content = PdfBlockWidget(
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
          onSplit: (before, after) => _handleSplitBlock(block, before, after),
          onMergePrevious: (text) => _handleMergeBlockWithPrevious(block, text),
        );
    }

    return BlockWrapper(
      key: ValueKey(block.id),
      blockId: block.id,
      index: index,
      depth: visibleBlock.depth,
      pageId: widget.pageId,
      onInsert: (type) => _handleInsertBlock(block, type: type),
      onDragUpdate: _handleBlockDragUpdate,
      onDragEnd: _stopAutoScroll,
      child: content,
    );
  }

  Future<void> _addMedia(String type) async {
    final focusedId = ref.read(focusedBlockIdProvider);
    if (focusedId == null) return;

    final blocks = ref.read(visibleBlocksProvider(widget.pageId));
    final visibleBlock = blocks.firstWhere(
      (b) => b.block.id == focusedId,
      orElse: () => blocks.first,
    );
    final block = visibleBlock.block;

    final mediaPicker = ref.read(mediaPickerProvider);

    Future<bool> handleSizeCheck(int sizeInBytes) async {
      final sizeMB = sizeInBytes / (1024 * 1024);
      if (sizeMB > 200) {
        return await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Very Large File'),
                content: Text(
                  'This file is ${sizeMB.toStringAsFixed(1)} MB. Syncing might take a long time and use a lot of storage. Are you sure?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Import Anyway'),
                  ),
                ],
              ),
            ) ??
            false;
      } else if (sizeMB > 50) {
        return await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Large File'),
                content: Text(
                  'This file is ${sizeMB.toStringAsFixed(1)} MB. Do you want to proceed?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Proceed'),
                  ),
                ],
              ),
            ) ??
            false;
      }
      return true;
    }

    final attachment = type == 'image'
        ? await mediaPicker.pickImage(
            pageId: block.pageId,
            blockId: block.id,
            onCheckSize: handleSizeCheck,
          )
        : await mediaPicker.pickFile(
            pageId: block.pageId,
            blockId: block.id,
            onCheckSize: handleSizeCheck,
          );

    if (attachment != null) {
      // Determine block type from media type
      String resolvedType = type;
      if (type != 'image') {
        if (attachment.mimeType.startsWith('video/')) {
          resolvedType = 'video';
        } else if (attachment.mimeType.startsWith('audio/')) {
          resolvedType = 'audio';
        } else if (attachment.mimeType == 'application/pdf') {
          resolvedType = 'pdf';
        } else {
          resolvedType = 'file';
        }
      }

      final BlockDataModel model;
      switch (resolvedType) {
        case 'image':
          model = BlockDataModel.image(attachmentId: attachment.id);
          break;
        case 'video':
          model = BlockDataModel.video(attachmentId: attachment.id);
          break;
        case 'audio':
          model = BlockDataModel.audio(attachmentId: attachment.id);
          break;
        case 'pdf':
          model = BlockDataModel.pdf(attachmentId: attachment.id);
          break;
        default:
          model = BlockDataModel.file(attachmentId: attachment.id);
      }

      final data = jsonEncode(model.toJson()..remove('runtimeType'));
      _handleBlockUpdate(block.copyWith(type: resolvedType, data: data));
    }
  }

  void _convertFocusedToHeading() {
    final focusedId = ref.read(focusedBlockIdProvider);
    if (focusedId == null) return;

    final blocks = ref.read(visibleBlocksProvider(widget.pageId));
    final block = blocks
        .firstWhere((b) => b.block.id == focusedId, orElse: () => blocks.first)
        .block;

    if (block.type == 'text') {
      try {
        final Map<String, dynamic> json =
            jsonDecode(block.data) as Map<String, dynamic>;
        json['headingLevel'] = 1;
        _handleBlockUpdate(block.copyWith(data: jsonEncode(json)));
      } catch (_) {}
    }
  }

  void _convertFocusedToList() {
    final focusedId = ref.read(focusedBlockIdProvider);
    if (focusedId == null) return;

    final blocks = ref.read(visibleBlocksProvider(widget.pageId));
    final block = blocks
        .firstWhere((b) => b.block.id == focusedId, orElse: () => blocks.first)
        .block;

    if (block.type == 'text') {
      try {
        final Map<String, dynamic> json =
            jsonDecode(block.data) as Map<String, dynamic>;
        final listData = BlockDataModel.list(
          spans: (json['spans'] as List?)
                  ?.map((e) => TextSpanData.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
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

  /// Handle paste from clipboard — intercept image data and insert as image block.
  Future<void> _handlePaste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;

    final reader = await clipboard.read();

    // Check for image data on the clipboard
    for (final format in [Formats.png, Formats.jpeg]) {
      if (reader.canProvide(format)) {
        reader.getFile(format, (clipFile) async {
          final ext = format == Formats.png ? '.png' : '.jpg';
          if (kIsWeb) {
            final stream = clipFile.getStream();
            final bytes = <int>[];
            await for (final chunk in stream.cast<List<int>>()) {
              bytes.addAll(chunk);
            }
            final platformFile = PlatformFile(
              name: 'paste$ext',
              size: bytes.length,
              bytes: Uint8List.fromList(bytes),
            );
            await _importFileAsBlock(platformFile, 'image/${ext.substring(1)}');
          } else {
            final tempDir = io.Directory.systemTemp;
            final tempFile = io.File(
              '${tempDir.path}/paste_${DateTime.now().millisecondsSinceEpoch}$ext',
            );
            final stream = clipFile.getStream();
            final sink = tempFile.openWrite();
            await stream.cast<List<int>>().pipe(sink);

            final platformFile = PlatformFile(
              name: 'paste$ext',
              size: await tempFile.length(),
              path: tempFile.path,
            );
            await _importFileAsBlock(platformFile, 'image/${ext.substring(1)}');

            // Clean up temp file
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          }
        });
        return;
      }
    }
  }

  /// Handle drop of files — import them as media blocks.
  Future<void> _handleDrop(List<String> paths) async {
    if (kIsWeb) {
      return; // Drop from paths might need web specific handling via bytes
    }
    for (final path in paths) {
      final file = io.File(path);
      if (!await file.exists()) continue;

      final ext = path.split('.').last.toLowerCase();
      String mimeType = 'application/octet-stream';

      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
        mimeType = 'image/$ext';
      } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
        mimeType = 'video/$ext';
      } else if (['mp3', 'wav', 'm4a', 'ogg', 'flac', 'aac'].contains(ext)) {
        mimeType = 'audio/$ext';
      } else if (ext == 'pdf') {
        mimeType = 'application/pdf';
      }

      final platformFile = PlatformFile(
        name: path.split('/').last,
        size: await file.length(),
        path: path,
      );
      await _importFileAsBlock(platformFile, mimeType);
    }
  }

  /// Core helper: import a [PlatformFile] into the note as a new media block.
  Future<void> _importFileAsBlock(PlatformFile file, String mimeType) async {
    final focusedId = ref.read(focusedBlockIdProvider);
    final blocks = ref.read(visibleBlocksProvider(widget.pageId));
    final visibleBlock = focusedId != null
        ? blocks.firstWhere(
            (b) => b.block.id == focusedId,
            orElse: () => blocks.last,
          )
        : blocks.last;
    final block = visibleBlock.block;

    // We reuse the pickFile path but pass the file directly via the repository
    final attachmentRepo = ref.read(
      attachmentRepositoryProvider,
    );
    try {
      final attachment = await attachmentRepo.saveAttachment(
        pageId: block.pageId,
        blockId: block.id,
        sourceFile: file,
        mimeType: mimeType,
      );

      String resolvedType = 'file';
      if (mimeType.startsWith('image/')) {
        resolvedType = 'image';
      } else if (mimeType.startsWith('video/')) {
        resolvedType = 'video';
      } else if (mimeType.startsWith('audio/')) {
        resolvedType = 'audio';
      } else if (mimeType == 'application/pdf') {
        resolvedType = 'pdf';
      }

      final BlockDataModel model;
      switch (resolvedType) {
        case 'image':
          model = BlockDataModel.image(attachmentId: attachment.id);
          break;
        case 'video':
          model = BlockDataModel.video(attachmentId: attachment.id);
          break;
        case 'audio':
          model = BlockDataModel.audio(attachmentId: attachment.id);
          break;
        case 'pdf':
          model = BlockDataModel.pdf(attachmentId: attachment.id);
          break;
        default:
          model = BlockDataModel.file(attachmentId: attachment.id);
      }

      final data = jsonEncode(model.toJson()..remove('runtimeType'));

      // Insert a new block after the focused one
      await ref
          .read(editorStateProvider(widget.pageId).notifier)
          .insertBlockAfter(block);
      final updatedBlocks = ref.read(visibleBlocksProvider(widget.pageId));
      final newBlock = updatedBlocks.firstWhere(
        (b) => b.block.position > block.position,
        orElse: () => updatedBlocks.last,
      );
      _handleBlockUpdate(
        newBlock.block.copyWith(type: resolvedType, data: data),
      );
    } catch (_) {
      // Import failed silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final visibleBlocks = ref.watch(visibleBlocksProvider(widget.pageId));
    
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.value;
    final screenWidth = MediaQuery.of(context).size.width;
    final layoutConfig = settings != null
        ? EditorLayoutConfig.fromAppearance(settings.editorAppearance, screenWidth: screenWidth)
        : EditorLayoutConfig(
            contentWidth: 800,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 600 ? 16.0 : 24.0, 
              vertical: 24.0,
            ),
            lineSpacing: 1.5,
          );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          // ref.read(editorStateProvider(widget.pageId).notifier).undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          // ref.read(editorStateProvider(widget.pageId).notifier).undo();
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () {
          // ref.read(editorStateProvider(widget.pageId).notifier).redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            () {
          // ref.read(editorStateProvider(widget.pageId).notifier).redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): () {
          _handlePaste();
        },
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): () {
          _handlePaste();
        },
      },
      child: Focus(
        autofocus: true,
        child: DropRegion(
          formats: Formats.standardFormats,
          onDropOver: (event) {
            if (event.session.items.isNotEmpty) {
              return DropOperation.copy;
            }
            return DropOperation.none;
          },
          onPerformDrop: (event) async {
            for (final item in event.session.items) {
              final reader = item.dataReader;
              if (reader == null) continue;
              if (reader.canProvide(Formats.fileUri)) {
                reader.getValue<Uri>(Formats.fileUri, (uri) async {
                  if (uri != null) {
                    await _handleDrop([uri.toFilePath()]);
                  }
                });
              }
            }
          },
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: layoutConfig.contentWidth),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.only(
                          left: layoutConfig.padding.left,
                          right: layoutConfig.padding.right,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final pageAsync = ref.watch(pageProvider(widget.pageId));
                              final page = pageAsync.valueOrNull;
                              if (page == null) return const SizedBox.shrink();
                              return PageHeader(
                                page: page,
                                focusTitle: widget.focusTitle,
                                onTitleChanged: widget.onTitleChanged,
                                onIconChanged: widget.onIconChanged,
                              );
                            },
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.only(
                          left: layoutConfig.padding.left,
                          right: layoutConfig.padding.right,
                          bottom: isKeyboardVisible ? 80.0 : layoutConfig.padding.bottom,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildBlockWidget(visibleBlocks[index], index);
                            },
                            childCount: visibleBlocks.length,
                          ),
                        ),
                      ),
                    ],
                  ),
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
      ),
    );
  }
}
