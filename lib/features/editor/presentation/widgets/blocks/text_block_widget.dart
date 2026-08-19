import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../../../blocks/domain/entities/block.dart';
import '../../../domain/models/block_data_models.dart';
import '../../../../attachments/presentation/providers/attachment_providers.dart';
import '../slash_command_menu.dart';

class TextBlockWidget extends ConsumerStatefulWidget {
  final Block block;
  final ValueChanged<Block> onUpdate;
  final VoidCallback onSplit;
  final VoidCallback onMergePrevious;

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
      json['runtimeType'] = 'text';
      _blockData = BlockDataModel.fromJson(json) as TextBlockData;
    } catch (e) {
      _blockData = const BlockDataModel.text(spans: []) as TextBlockData;
    }
  }

  String _getPlainText() {
    if (_blockData.spans.isEmpty) return '';
    return _blockData.spans.map((s) => s.text).join('');
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _debounce?.cancel();
      _saveChanges();
    }
  }

  void _saveChanges() {
    final text = _controller.text;
    if (text == _getPlainText()) return;

    // Simple span creation for now
    final newSpans = [TextSpanData(text: text)];
    final newData = _blockData.copyWith(spans: newSpans);
    
    final json = newData.toJson();
    json.remove('runtimeType');
    
    final updatedBlock = widget.block.copyWith(
      data: jsonEncode(json),
    );
    
    widget.onUpdate(updatedBlock);
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
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return TextField(
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
      onSubmitted: (_) => widget.onSplit(),
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      onChanged: (value) {
        if (value.trim() == '/') {
          _showSlashMenu();
        } else {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            _saveChanges();
          });
        }
      },
    );
  }

  void _showSlashMenu() {
    // Hide keyboard
    _focusNode.unfocus();

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SlashCommandMenu(
          options: [
            SlashCommandOption(
              title: 'Image',
              subtitle: 'Upload an image',
              icon: Icons.image,
              onSelected: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            SlashCommandOption(
              title: 'File',
              subtitle: 'Upload a file',
              icon: Icons.insert_drive_file,
              onSelected: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // Re-focus and clear '/' if they didn't pick anything
      if (_controller.text.trim() == '/') {
        _controller.text = '';
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      await _saveAttachment(File(xFile.path), 'image/jpeg', 'image');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      await _saveAttachment(File(result.files.single.path!), 'application/octet-stream', 'file');
    }
  }

  Future<void> _saveAttachment(File file, String mimeType, String targetType) async {
    final useCase = ref.read(saveAttachmentUseCaseProvider);
    final result = await useCase.call(file: file, mimeType: mimeType);
    
    result.fold(
      (attachment) {
        // Change this block to an image or file block
        String data;
        if (targetType == 'image') {
          data = jsonEncode(BlockDataModel.image(attachmentId: attachment.id).toJson()..remove('runtimeType'));
        } else {
          data = jsonEncode(BlockDataModel.file(attachmentId: attachment.id).toJson()..remove('runtimeType'));
        }
        
        final updatedBlock = widget.block.copyWith(
          type: targetType,
          data: data,
        );
        widget.onUpdate(updatedBlock);
      },
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
      },
    );
  }
}
