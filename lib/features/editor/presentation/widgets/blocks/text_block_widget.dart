import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../pages/domain/entities/page.dart' as page_entity;
import '../../../../pages/presentation/widgets/page_picker_sheet.dart';
import '../../../../blocks/domain/entities/block.dart';
import '../../../domain/models/block_data_models.dart';
import '../../../../media/presentation/providers/media_picker_provider.dart';
import '../slash_command_menu.dart';
import '../slash_command_controller.dart';
import '../../providers/editor_state_provider.dart';

class TextBlockWidget extends ConsumerStatefulWidget {
  final Block block;
  final ValueChanged<Block> onUpdate;
  final Future<void> Function(String before, String after) onSplit;
  final Future<void> Function(String textToMerge) onMergePrevious;

  const TextBlockWidget({
    super.key,
    required this.block,
    required this.onUpdate,
    required this.onSplit,
    required this.onMergePrevious,
  });

  @override
  ConsumerState<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends ConsumerState<TextBlockWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late TextBlockData _blockData;
  Timer? _debounce;
  final Map<String, String> _pageLinks = {}; // Title -> PageId
  
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();
  late SlashCommandController _slashController;

  @override
  void initState() {
    super.initState();
    _parseData();
    _controller = TextEditingController(text: _getPlainText());
    _focusNode = FocusNode();
    _slashController = SlashCommandController(
      textController: _controller,
      layerLink: _layerLink,
      anchorKey: _anchorKey,
      context: () => context,
      optionsBuilder: (query) => _slashOptionsFor(query),
    );

    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(pendingBlockFocusProvider);
      if (pending != null && pending.id == widget.block.id) {
        _focusNode.requestFocus();
        if (pending.action == 'start') {
          _controller.selection = const TextSelection.collapsed(offset: 0);
        } else if (pending.action == 'end') {
          _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        } else if (pending.action.startsWith('offset:')) {
          final offset = int.tryParse(pending.action.substring(7)) ?? 0;
          _controller.selection = TextSelection.collapsed(offset: offset.clamp(0, _controller.text.length));
        }
        ref.read(pendingBlockFocusProvider.notifier).state = null;
      }
    });
  }

  void _parseData() {
    try {
      final Map<String, dynamic> json =
          jsonDecode(widget.block.data) as Map<String, dynamic>;
      json['runtimeType'] = 'text';
      _blockData = BlockDataModel.fromJson(json) as TextBlockData;

      for (final span in _blockData.spans) {
        if (span.pageLink != null && span.pageLinkTitle != null) {
          _pageLinks[span.pageLinkTitle!] = span.pageLink!;
        }
      }
    } catch (e) {
      _blockData = const BlockDataModel.text(spans: []) as TextBlockData;
    }
  }

  String _getPlainText() {
    if (_blockData.spans.isEmpty) return '';
    return _blockData.spans.map((s) {
      if (s.pageLink != null) {
        return '[[${s.pageLinkTitle ?? "Untitled"}]]';
      }
      return s.text;
    }).join('');
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      ref.read(focusedBlockIdProvider.notifier).state = widget.block.id;
    } else {
      _slashController.close();
      _debounce?.cancel();
      _saveChanges();
    }
  }

  void _saveChanges() {
    final text = _controller.text;
    if (text == _getPlainText()) return;

    final List<TextSpanData> newSpans = [];
    final regex = RegExp(r'\[\[(.*?)\]\]');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        newSpans
            .add(TextSpanData(text: text.substring(lastMatchEnd, match.start)));
      }
      final title = match.group(1)!;
      final pageId = _pageLinks[title];
      if (pageId != null) {
        newSpans.add(
          TextSpanData(text: '', pageLink: pageId, pageLinkTitle: title),
        );
      } else {
        newSpans.add(TextSpanData(text: match.group(0)!));
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      newSpans.add(TextSpanData(text: text.substring(lastMatchEnd)));
    }

    final newData = _blockData.copyWith(
      spans: newSpans.isEmpty ? [TextSpanData(text: text)] : newSpans,
    );

    final json = newData.toJson();
    json.remove('runtimeType');

    final updatedBlock = widget.block.copyWith(
      data: jsonEncode(json),
    );

    widget.onUpdate(updatedBlock);
  }

  List<SlashCommandOption> _slashOptionsFor(String query) {
    final allOptions = [
      SlashCommandOption(
        title: 'Heading 1',
        subtitle: 'Large section heading',
        icon: Icons.title,
        onSelected: () => _convertToHeading(1),
      ),
      SlashCommandOption(
        title: 'Heading 2',
        subtitle: 'Medium section heading',
        icon: Icons.title,
        onSelected: () => _convertToHeading(2),
      ),
      SlashCommandOption(
        title: 'Heading 3',
        subtitle: 'Small section heading',
        icon: Icons.title,
        onSelected: () => _convertToHeading(3),
      ),
      SlashCommandOption(
        title: 'Checklist',
        subtitle: 'Track tasks with a to-do list',
        icon: Icons.check_box_outlined,
        onSelected: () => _convertToList('checklist'),
      ),
      SlashCommandOption(
        title: 'Bulleted List',
        subtitle: 'Create a simple bulleted list',
        icon: Icons.format_list_bulleted,
        onSelected: () => _convertToList('bullet'),
      ),
      SlashCommandOption(
        title: 'Numbered List',
        subtitle: 'Create a list with numbering',
        icon: Icons.format_list_numbered,
        onSelected: () => _convertToList('numbered'),
      ),
      SlashCommandOption(
        title: 'Image',
        subtitle: 'Upload an image',
        icon: Icons.image,
        onSelected: _pickImage,
      ),
      SlashCommandOption(
        title: 'File',
        subtitle: 'Upload a file',
        icon: Icons.insert_drive_file,
        onSelected: _pickFile,
      ),
    ];
    
    final normalizedQuery = query.toLowerCase();
    return allOptions.where((option) {
      return normalizedQuery.isEmpty ||
          option.title.toLowerCase().contains(normalizedQuery) ||
          option.subtitle.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  void _handleEnter() {
    final selection = _controller.selection;
    final cursor = selection.isValid ? selection.start : _controller.text.length;
    final before = _controller.text.substring(0, cursor);
    final after = _controller.text.substring(selection.end);
    _controller.value = TextEditingValue(
      text: before,
      selection: TextSelection.collapsed(offset: before.length),
    );
    unawaited(widget.onSplit(before, after));
  }

  /// Android IMEs can insert a newline without dispatching a KeyDownEvent.
  bool _handleImeNewline(String value) {
    final newline = value.indexOf('\n');
    if (newline == -1) return false;
    if (_slashController.isOpen) {
      _slashController.selectCurrent();
      return true;
    }
    final before = value.substring(0, newline);
    final after = value.substring(newline + 1);
    _controller.value = TextEditingValue(
      text: before,
      selection: TextSelection.collapsed(offset: before.length),
    );
    unawaited(widget.onSplit(before, after));
    return true;
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_slashController.handleKeyEvent(event)) return KeyEventResult.handled;
    if (!_slashController.isOpen) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _focusNode.unfocus();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        final selection = _controller.selection;
        if (selection.isValid && selection.start == 0 && selection.end == 0) {
          final editor = ref.read(editorStateProvider(widget.block.pageId).notifier);
          editor.focusPreviousBlock(widget.block.id);
          return KeyEventResult.handled;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final selection = _controller.selection;
        final len = _controller.text.length;
        if (selection.isValid && selection.start == len && selection.end == len) {
          final editor = ref.read(editorStateProvider(widget.block.pageId).notifier);
          editor.focusNextBlock(widget.block.id);
          return KeyEventResult.handled;
        }
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _handleEnter();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controller.selection.isCollapsed) {
        final offset = _controller.selection.baseOffset;
        if (_controller.text.isEmpty || offset == 0) {
          unawaited(widget.onMergePrevious(_controller.text));
          return KeyEventResult.handled;
        }
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final editor = ref.read(editorStateProvider(widget.block.pageId).notifier);
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if (isShiftPressed) {
        unawaited(editor.outdentBlock(widget.block.id));
      } else {
        unawaited(editor.indentBlock(widget.block.id));
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(covariant TextBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.data != widget.block.data) {
      _parseData();
      final text = _getPlainText();
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  @override
  void dispose() {
    _slashController.dispose();
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BlockFocusIntent?>(pendingBlockFocusProvider, (previous, pending) {
      if (pending != null && pending.id == widget.block.id) {
        _focusNode.requestFocus();
        if (pending.action == 'start') {
          _controller.selection = const TextSelection.collapsed(offset: 0);
        } else if (pending.action == 'end') {
          _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        } else if (pending.action.startsWith('offset:')) {
          final offset = int.tryParse(pending.action.substring(7)) ?? 0;
          _controller.selection = TextSelection.collapsed(offset: offset.clamp(0, _controller.text.length));
        }
        Future.microtask(() => ref.read(pendingBlockFocusProvider.notifier).state = null);
      }
    });

    double fontSize = 16.0;
    FontWeight fontWeight = FontWeight.normal;

    if (_blockData.headingLevel == 1) {
      fontSize = 32.0;
      fontWeight = FontWeight.bold;
    } else if (_blockData.headingLevel == 2) {
      fontSize = 24.0;
      fontWeight = FontWeight.bold;
    } else if (_blockData.headingLevel == 3) {
      fontSize = 20.0;
      fontWeight = FontWeight.bold;
    }

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: CompositedTransformTarget(
        key: _anchorKey,
        link: _layerLink,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
          textInputAction: TextInputAction.newline,
          keyboardType: TextInputType.multiline,
          onChanged: (value) {
            if (_handleImeNewline(value)) return;
            _slashController.check(value);
            
            if (value.endsWith('[[')) {
              _showPagePicker();
            } else if (value.startsWith('# ')) {
              _convertToHeading(1);
            } else if (value.startsWith('## ')) {
              _convertToHeading(2);
            } else if (value.startsWith('### ')) {
              _convertToHeading(3);
            } else if (value.startsWith('- ') || value.startsWith('* ')) {
              _convertToList('bullet');
            } else if (value.startsWith('[] ')) {
              _convertToList('checklist');
            } else if (RegExp(r'^\d+\.\s').hasMatch(value)) {
              _convertToList('numbered');
            } else {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                _saveChanges();
              });
            }
          },
        ),
      ),
    );
  }

  void _showPagePicker() {
    _focusNode.unfocus();
    showModalBottomSheet<page_entity.Page>(
      context: context,
      builder: (context) => const PagePickerSheet(),
    ).then((selectedPage) {
      if (selectedPage != null) {
        _pageLinks[selectedPage.title] = selectedPage.id;
        final text = _controller.text;
        final newText =
            '${text.substring(0, text.length - 2)}[[${selectedPage.title}]]';
        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(offset: newText.length);
        _saveChanges();
      } else {
        // Did not select, clear [[ if it was the last thing typed
        if (_controller.text.endsWith('[[')) {
          _controller.text =
              _controller.text.substring(0, _controller.text.length - 2);
          _controller.selection =
              TextSelection.collapsed(offset: _controller.text.length);
        }
      }
      _focusNode.requestFocus();
    });
  }


  Future<void> _pickImage() async {
    final mediaPicker = ref.read(mediaPickerProvider);
    final attachment = await mediaPicker.pickImage(
      pageId: widget.block.pageId,
      blockId: widget.block.id,
    );
    if (attachment != null) {
      _insertMediaBlock(attachment.id, 'image');
    }
  }

  Future<void> _pickFile() async {
    final mediaPicker = ref.read(mediaPickerProvider);
    final attachment = await mediaPicker.pickFile(
      pageId: widget.block.pageId,
      blockId: widget.block.id,
    );
    if (attachment != null) {
      _insertMediaBlock(attachment.id, 'file');
    }
  }

  void _insertMediaBlock(String attachmentId, String targetType) {
    String data;
    if (targetType == 'image') {
      data = jsonEncode(
        BlockDataModel.image(attachmentId: attachmentId).toJson()
          ..remove('runtimeType'),
      );
    } else {
      data = jsonEncode(
        BlockDataModel.file(attachmentId: attachmentId).toJson()
          ..remove('runtimeType'),
      );
    }

    final updatedBlock = widget.block.copyWith(
      type: targetType,
      data: data,
    );
    widget.onUpdate(updatedBlock);
  }

  void _convertToHeading(int level) {
    _blockData = _blockData.copyWith(headingLevel: level);

    final text = _controller.text;
    if (level == 1 && text.startsWith('# ')) {
      _controller.text = text.substring(2);
    } else if (level == 2 && text.startsWith('## ')) {
      _controller.text = text.substring(3);
    } else if (level == 3 && text.startsWith('### ')) {
      _controller.text = text.substring(4);
    } else if (text.trim() == '/') {
      _controller.text = '';
    }

    _saveChanges();
    setState(() {});
  }

  void _convertToList(String listType) {
    final text = _controller.text;
    String newText = text;

    if (listType == 'bullet' &&
        (text.startsWith('- ') || text.startsWith('* '))) {
      newText = text.substring(2);
    } else if (listType == 'checklist' && text.startsWith('[] ')) {
      newText = text.substring(3);
    } else if (listType == 'numbered' && RegExp(r'^\d+\.\s').hasMatch(text)) {
      newText = text.replaceFirst(RegExp(r'^\d+\.\s'), '');
    } else if (text.trim() == '/') {
      newText = '';
    }

    final listData = BlockDataModel.list(
      spans: [TextSpanData(text: newText)],
      listType: listType,
    );

    final updatedBlock = widget.block.copyWith(
      type: 'list',
      data: jsonEncode(listData.toJson()..remove('runtimeType')),
    );

    widget.onUpdate(updatedBlock);
  }
}
