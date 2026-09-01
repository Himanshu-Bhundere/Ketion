import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../blocks/domain/entities/block.dart';
import '../../../../media/presentation/providers/attachment_provider.dart';
import '../../../domain/models/block_data_models.dart';

class ImageBlockWidget extends ConsumerStatefulWidget {
  final Block block;
  final ValueChanged<Block> onUpdate;

  const ImageBlockWidget({
    super.key,
    required this.block,
    required this.onUpdate,
  });

  @override
  ConsumerState<ImageBlockWidget> createState() => _ImageBlockWidgetState();
}

class _ImageBlockWidgetState extends ConsumerState<ImageBlockWidget> {
  late ImageBlockData _blockData;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    try {
      final Map<String, dynamic> json =
          jsonDecode(widget.block.data) as Map<String, dynamic>;
      json['runtimeType'] = 'image';
      _blockData = BlockDataModel.fromJson(json) as ImageBlockData;
    } catch (e) {
      _blockData =
          const BlockDataModel.image(attachmentId: '') as ImageBlockData;
    }
  }

  @override
  void didUpdateWidget(covariant ImageBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.data != widget.block.data) {
      _parseData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blockData.attachmentId.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Invalid image block')),
      );
    }

    final attachmentAsync =
        ref.watch(attachmentProvider(_blockData.attachmentId));

    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text('Image not found in database')),
          );
        }

        final pathAsync = ref.watch(attachmentPathProvider(attachment));

        return pathAsync.when(
          data: (localPath) {
            if (localPath == null) {
              return const SizedBox(
                height: 100,
                child: Center(child: Text('Image file not found')),
              );
            }

            final imageFile = File(localPath);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                  ),
                ),
                if (_blockData.caption != null &&
                    _blockData.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _blockData.caption!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => SizedBox(
            height: 100,
            child: Center(child: Text('Error loading image path: $e')),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => SizedBox(
        height: 100,
        child: Center(child: Text('Error loading image metadata: $e')),
      ),
    );
  }
}
