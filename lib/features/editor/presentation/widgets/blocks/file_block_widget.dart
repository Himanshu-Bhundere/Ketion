import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../blocks/domain/entities/block.dart';
import '../../../../media/presentation/providers/attachment_provider.dart';
import '../../../domain/models/block_data_models.dart';
import '../../../../../core/utils/attachment_launcher.dart';

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
      final Map<String, dynamic> json =
          jsonDecode(widget.block.data) as Map<String, dynamic>;
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

    final attachmentAsync =
        ref.watch(attachmentProvider(_blockData.attachmentId));

    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          return const ListTile(
            leading: Icon(Icons.broken_image),
            title: Text('File not found in database'),
          );
        }

        final pathAsync = ref.watch(attachmentPathProvider(attachment));

        return pathAsync.when(
          data: (localPath) {
            if (localPath == null) {
              return const ListTile(
                leading: Icon(Icons.broken_image),
                title: Text('File not found'),
              );
            }

            final fileName = attachment.fileName;
            final fileSize = (attachment.size) / 1024 / 1024;

            IconData iconData = Icons.insert_drive_file;
            if (attachment.mimeType.startsWith('video/')) {
              iconData = Icons.video_file;
            } else if (attachment.mimeType.startsWith('audio/')) {
              iconData = Icons.audio_file;
            } else if (attachment.mimeType == 'application/pdf') {
              iconData = Icons.picture_as_pdf;
            }

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListTile(
                leading: Icon(iconData, size: 36),
                title: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${fileSize.toStringAsFixed(2)} MB'),
                onTap: () {
                  ref.read(attachmentLauncherProvider).launch(localPath);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () {
                    ref.read(attachmentLauncherProvider).launch(localPath);
                  },
                ),
              ),
            );
          },
          loading: () => const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Loading file path...'),
          ),
          error: (e, st) => ListTile(
            leading: const Icon(Icons.error),
            title: Text('Error loading file path: $e'),
          ),
        );
      },
      loading: () => const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Loading file metadata...'),
      ),
      error: (e, st) => ListTile(
        leading: const Icon(Icons.error),
        title: Text('Error loading file metadata: $e'),
      ),
    );
  }
}
