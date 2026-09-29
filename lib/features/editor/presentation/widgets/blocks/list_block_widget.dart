import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../blocks/domain/entities/block.dart';
import '../../../domain/models/block_data_models.dart';
import '../../../../media/presentation/providers/media_picker_provider.dart';
import '../../providers/editor_state_provider.dart';
import '../slash_command_controller.dart';
import '../slash_command_menu.dart';

class ListBlockWidget extends ConsumerStatefulWidget {
  final Block block;
  final ValueChanged<Block> onUpdate;
  final Future<void> Function(String before, String after) onSplit;
  final Future<void> Function(String textToMerge) onMergePrevious;

  const ListBlockWidget({
    super.key,
    required this.block,
    required this.onUpdate,
    required this.onSplit,
    required this.onMergePrevious,
  });

  @override
  ConsumerState<ListBlockWidget> createState() => _ListBlockWidgetState();
}

class _ListBlockWidgetState extends ConsumerState<ListBlockWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late ListBlockData _blockData;
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
      optionsBuilder: _slashOptionsFor,
    );

    _focusNode.addListener(_onFocusChange);
  }

  void _parseData() {
    try {
      final Map<String, dynamic> json =
          jsonDecode(widget.block.data) as Map<String, dynamic>;
      json['runtimeType'] = 'list';
      _blockData = BlockDataModel.fromJson(json) as ListBlockData;
    } catch (e) {
      _blockData = const BlockDataModel.list(spans: []) as ListBlockData;
    }
  }

  String _getPlainText() {
    if (_blockData.spans.isEmpty) return '';
    return _blockData.spans.map((s) => s.text).join('');
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      ref.read(focusedBlockIdProvider.notifier).state = widget.block.id;
    } else {
      _slashController.close();
      _saveChanges();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_slashController.handleKeyEvent(event)) return KeyEventResult.handled;
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _handleEnter();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      final selection = _controller.selection;
      if (selection.isValid && selection.start == 0 && selection.end == 0) {
        widget.onMergePrevious(_controller.text);
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final editor = ref.read(editorStateProvider(widget.block.pageId).notifier);
      if (HardwareKeyboard.instance.isShiftPressed) {
        editor.outdentBlock(widget.block.id);
      } else {
        editor.indentBlock(widget.block.id);
      }
      return KeyEventResult.handled;
    }
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
    return KeyEventResult.ignored;
  }

  void _saveChanges() {
    final text = _controller.text;

    // Simple span creation for now
    final newSpans = [TextSpanData(text: text)];
    final newData = _blockData.copyWith(spans: newSpans);

    final json = newData.toJson();
    json.remove('runtimeType');

    final updatedBlock = widget.block.copyWith(
      data: jsonEncode(json),
    );

    // Check if anything actually changed
    if (widget.block.data != updatedBlock.data) {
      widget.onUpdate(updatedBlock);
    }
  }

  void _toggleChecked(bool? value) {
    final checked = value ?? false;
    final newData = _blockData.copyWith(checked: checked);
    final json = newData.toJson();
    json.remove('runtimeType');

    final updatedBlock = widget.block.copyWith(
      data: jsonEncode(json),
    );
    widget.onUpdate(updatedBlock);
  }

  List<SlashCommandOption> _slashOptionsFor(String query) {
    final options = [
      SlashCommandOption(
        title: 'Heading 1',
        subtitle: 'Large section heading',
        icon: Icons.title,
        category: SlashCommandCategory.basic,
        onSelected: (_) => _convertToHeading(1),
      ),
      SlashCommandOption(
        title: 'Heading 2',
        subtitle: 'Medium section heading',
        icon: Icons.title,
        category: SlashCommandCategory.basic,
        onSelected: (_) => _convertToHeading(2),
      ),
      SlashCommandOption(
        title: 'Heading 3',
        subtitle: 'Small section heading',
        icon: Icons.title,
        category: SlashCommandCategory.basic,
        onSelected: (_) => _convertToHeading(3),
      ),
      SlashCommandOption(
        title: 'Checklist',
        subtitle: 'Track tasks with a to-do list',
        icon: Icons.check_box_outlined,
        category: SlashCommandCategory.list,
        onSelected: (_) => _convertToList('checklist'),
      ),
      SlashCommandOption(
        title: 'Bulleted List',
        subtitle: 'Create a simple bulleted list',
        icon: Icons.format_list_bulleted,
        category: SlashCommandCategory.list,
        onSelected: (_) => _convertToList('bullet'),
      ),
      SlashCommandOption(
        title: 'Numbered List',
        subtitle: 'Create a list with numbering',
        icon: Icons.format_list_numbered,
        category: SlashCommandCategory.list,
        onSelected: (_) => _convertToList('numbered'),
      ),
      SlashCommandOption(
        title: 'Image', subtitle: 'Upload an image', icon: Icons.image,
        category: SlashCommandCategory.media,
        onSelected: (_) => _pickImage(),
      ),
      SlashCommandOption(
        title: 'File', subtitle: 'Upload a file', icon: Icons.insert_drive_file,
        category: SlashCommandCategory.media,
        onSelected: (_) => _pickFile(),
      ),
    ];
    final normalized = query.toLowerCase();
    return options.where((option) => normalized.isEmpty || option.title.toLowerCase().contains(normalized) || option.subtitle.toLowerCase().contains(normalized)).toList();
  }

  void _handleEnter() {
    final selection = _controller.selection;
    final cursor = selection.isValid ? selection.start : _controller.text.length;
    final before = _controller.text.substring(0, cursor);
    final after = _controller.text.substring(selection.end);
    _controller.value = TextEditingValue(text: before, selection: TextSelection.collapsed(offset: before.length));
    unawaited(widget.onSplit(before, after));
  }

  bool _handleImeNewline(String value) {
    final newline = value.indexOf('\n');
    if (newline == -1) return false;
    if (_slashController.isOpen) {
      _slashController.selectCurrent();
      return true;
    }
    final before = value.substring(0, newline);
    final after = value.substring(newline + 1);
    _controller.value = TextEditingValue(text: before, selection: TextSelection.collapsed(offset: before.length));
    unawaited(widget.onSplit(before, after));
    return true;
  }

  void _convertToHeading(int level) {
    final data = BlockDataModel.text(
      spans: [TextSpanData(text: _controller.text)],
      headingLevel: level,
    ).toJson()..remove('runtimeType');
    widget.onUpdate(widget.block.copyWith(type: 'text', data: jsonEncode(data)));
  }

  void _convertToList(String listType) {
    final data = _blockData.copyWith(
      spans: [TextSpanData(text: _controller.text)],
      listType: listType,
    ).toJson()..remove('runtimeType');
    widget.onUpdate(widget.block.copyWith(data: jsonEncode(data)));
  }

  Future<void> _pickImage() async {
    final attachment = await ref.read(mediaPickerProvider).pickImage(
      pageId: widget.block.pageId,
      blockId: widget.block.id,
    );
    if (attachment != null) _insertMediaBlock(attachment.id, 'image');
  }

  Future<void> _pickFile() async {
    final attachment = await ref.read(mediaPickerProvider).pickFile(
      pageId: widget.block.pageId,
      blockId: widget.block.id,
    );
    if (attachment != null) _insertMediaBlock(attachment.id, 'file');
  }

  void _insertMediaBlock(String attachmentId, String type) {
    final data = type == 'image'
        ? BlockDataModel.image(attachmentId: attachmentId).toJson()
        : BlockDataModel.file(attachmentId: attachmentId).toJson();
    data.remove('runtimeType');
    widget.onUpdate(widget.block.copyWith(type: type, data: jsonEncode(data)));
  }

  @override
  void didUpdateWidget(covariant ListBlockWidget oldWidget) {
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
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget leadingWidget;
    switch (_blockData.listType) {
      case 'bullet':
        leadingWidget = const Padding(
          padding: EdgeInsets.only(top: 8.0, right: 8.0),
          child: Icon(Icons.circle, size: 8),
        );
        break;
      case 'numbered':
        leadingWidget = const Padding(
          padding: EdgeInsets.only(top: 4.0, right: 8.0),
          child:
              Text('1.', style: TextStyle(fontSize: 16)), // Hardcoded for now
        );
        break;
      case 'checklist':
        leadingWidget = Semantics(
          checked: _blockData.checked,
          label: 'Checklist item',
          child: Checkbox(
            value: _blockData.checked,
            onChanged: _toggleChecked,
          ),
        );
        break;
      default:
        leadingWidget = const SizedBox(width: 16);
    }

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leadingWidget,
        Expanded(
          child: CompositedTransformTarget(
            key: _anchorKey,
            link: _layerLink,
            child: Focus(
              onKeyEvent: _handleKeyEvent,
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
                fontSize: 16.0,
                decoration:
                    _blockData.checked ? TextDecoration.lineThrough : null,
                color: _blockData.checked ? Colors.grey : null,
              ),
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              onChanged: (value) {
                if (_handleImeNewline(value)) return;
                _slashController.check(value);
                _saveChanges();
              },
            ),
            ),
          ),
        ),
      ],
    );

    return _blockData.listType == 'checklist'
        ? MergeSemantics(child: row)
        : row;
  }
}
