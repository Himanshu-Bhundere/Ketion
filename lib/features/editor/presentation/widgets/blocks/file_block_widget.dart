import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../blocks/domain/entities/block.dart';
import '../../../../attachments/presentation/providers/attachment_future_provider.dart';
import '../../../domain/models/block_data_models.dart';

class FileBlockWidget extends ConsumerStatefulWidget {
  final Block block;
  final ValueChanged<Block> onUpdate;

  const FileBlockWidget({
    super.key,
    required this.block,
    required this.onUpdate,
  });

  @override
  ConsumerState<FileBlockWidget> createState() => _FileBlockWidgetState();
}

class _FileBlockWidgetState extends ConsumerState<FileBlockWidget> {
  late FileBlockData _blockData;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    try {
      final Map<String, dynamic> json = jsonDecode(widget.block.data) as Map<String, dynamic>;
      json['runtimeType'] = 'file';
      _blockData = BlockDataModel.fromJson(json) as FileBlockData;
    } catch (e) {
      _blockData = const BlockDataModel.file(attachmentId: '') as FileBlockData;
    }
  }

  @override
  void didUpdateWidget(covariant FileBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.data != widget.block.data) {
      _parseData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blockData.attachmentId.isEmpty) {
      return const ListTile(
        leading: Icon(Icons.error),
        title: Text('Invalid file block'),
      );
    }

    final attachmentAsync = ref.watch(attachmentFutureProvider(_blockData.attachmentId));

    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null || attachment.localPath == null) {
          return const ListTile(
            leading: Icon(Icons.broken_image),
            title: Text('File not found'),
          );
        }
        
        final fileName = attachment.localPath!.split('/').last.split('\\').last;
        final fileSize = (attachment.fileSize ?? 0) / 1024 / 1024;
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file, size: 36),
            title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${fileSize.toStringAsFixed(2)} MB'),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                // Open file
              },
            ),
          ),
        );
      },
      loading: () => const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Loading file...'),
      ),
      error: (e, st) => ListTile(
        leading: const Icon(Icons.error),
        title: Text('Error loading file: $e'),
      ),
    );
  }
}
