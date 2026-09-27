import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../blocks/domain/entities/block.dart';
import '../../../../media/presentation/providers/attachment_provider.dart';
import '../../../domain/models/block_data_models.dart';
import '../../../../../core/utils/attachment_launcher.dart';

class PdfBlockWidget extends ConsumerStatefulWidget {
  final Block block;
  final ValueChanged<Block> onUpdate;

  const PdfBlockWidget({
    super.key,
    required this.block,
    required this.onUpdate,
  });

  @override
  ConsumerState<PdfBlockWidget> createState() => _PdfBlockWidgetState();
}

class _PdfBlockWidgetState extends ConsumerState<PdfBlockWidget> {
  late PdfBlockData _blockData;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    try {
      final Map<String, dynamic> json =
          jsonDecode(widget.block.data) as Map<String, dynamic>;
      json['runtimeType'] = 'pdf';
      _blockData = BlockDataModel.fromJson(json) as PdfBlockData;
    } catch (e) {
      _blockData = const BlockDataModel.pdf(attachmentId: '') as PdfBlockData;
    }
  }

  @override
  void didUpdateWidget(covariant PdfBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.data != widget.block.data) {
      _parseData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blockData.attachmentId.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Invalid PDF block')),
      );
    }

    final attachmentAsync =
        ref.watch(attachmentProvider(_blockData.attachmentId));

    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('PDF not found in database')),
          );
        }

        final pathAsync = ref.watch(attachmentPathProvider(attachment));

        return pathAsync.when(
          data: (localPath) {
            if (localPath == null) {
              return const SizedBox(
                height: 80,
                child: Center(child: Text('PDF file not available locally')),
              );
            }

            final fileName =
                attachment.localPath?.split('/').last ?? 'Document.pdf';
            final fileSize = attachment.fileSize / 1024 / 1024;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: InkWell(
                onTap: () {
                  ref.read(attachmentLauncherProvider).launch(localPath);
                },
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _blockData.caption?.isNotEmpty == true
                                  ? _blockData.caption!
                                  : fileName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${fileSize.toStringAsFixed(2)} MB • PDF',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 20),
                        onPressed: () {
                          ref
                              .read(attachmentLauncherProvider)
                              .launch(localPath);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => SizedBox(
            height: 80,
            child: Center(child: Text('Error loading PDF path: $e')),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => SizedBox(
        height: 80,
        child: Center(child: Text('Error loading PDF metadata: $e')),
      ),
    );
  }
}
