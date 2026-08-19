import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../../blocks/domain/entities/block.dart';
import '../../../domain/models/block_data_models.dart';

class ListBlockWidget extends StatefulWidget {
  final Block block;
  final ValueChanged<Block> onUpdate;
  final VoidCallback onSplit;
  final VoidCallback onMergePrevious;

  const ListBlockWidget({
    super.key,
    required this.block,
    required this.onUpdate,
    required this.onSplit,
    required this.onMergePrevious,
  });

  @override
  State<ListBlockWidget> createState() => _ListBlockWidgetState();
}

class _ListBlockWidgetState extends State<ListBlockWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late ListBlockData _blockData;

  @override
  void initState() {
    super.initState();
    _parseData();
    _controller = TextEditingController(text: _getPlainText());
    _focusNode = FocusNode();
    
    _focusNode.addListener(_onFocusChange);
  }

  void _parseData() {
    try {
      final Map<String, dynamic> json = jsonDecode(widget.block.data) as Map<String, dynamic>;
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
    if (!_focusNode.hasFocus) {
      _saveChanges();
    }
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
          child: Text('1.', style: TextStyle(fontSize: 16)), // Hardcoded for now
        );
        break;
      case 'checklist':
        leadingWidget = Checkbox(
          value: _blockData.checked,
          onChanged: _toggleChecked,
        );
        break;
      default:
        leadingWidget = const SizedBox(width: 16);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leadingWidget,
        Expanded(
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
              decoration: _blockData.checked ? TextDecoration.lineThrough : null,
              color: _blockData.checked ? Colors.grey : null,
            ),
            onSubmitted: (_) {
              _saveChanges();
              widget.onSplit();
            },
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            onChanged: (value) {
              if (value.isEmpty) {
                // If text is empty and user hits backspace, might want to convert to text block
              }
            },
          ),
        ),
      ],
    );
  }
}
