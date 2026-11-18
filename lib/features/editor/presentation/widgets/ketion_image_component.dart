import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import 'package:ketion/core/theme/media_dimensions.dart';
import '../../../media/presentation/providers/attachment_provider.dart';
import '../../../media/data/repositories/attachment_repository_impl.dart';
import '../../../media/data/services/attachment_export_service.dart';
import '../../../media/data/services/attachment_sync_service_impl.dart';

/// Ketion's custom ImageComponentBuilder to handle image attachments.
/// It uses Riverpod to fetch the local path of the attachment if `imageUrl` is an attachment ID.
class KetionImageComponentBuilder implements ComponentBuilder {
  final Editor? editor;
  const KetionImageComponentBuilder([this.editor]);

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! ImageNode) {
      return null;
    }

    return KetionImageComponentViewModel(
      nodeId: node.id,
      maxWidth: double.infinity,
      padding: EdgeInsets.zero,
      imageUrl: node.imageUrl,
      selectionColor: const Color(0x00000000),
      metadata: node.metadata,
      createdAt: null,
      editor: editor,
    );
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! KetionImageComponentViewModel) {
      return null;
    }

    return KetionImageComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel,
    );
  }
}

class KetionImageComponentViewModel
    extends SingleColumnLayoutComponentViewModel {
  KetionImageComponentViewModel({
    required super.nodeId,
    super.maxWidth,
    required super.padding,
    required super.createdAt,
    required this.imageUrl,
    required this.selectionColor,
    this.metadata = const {},
    this.editor,
  });

  final String imageUrl;
  final Color selectionColor;
  final Map<String, dynamic> metadata;
  final Editor? editor;

  @override
  KetionImageComponentViewModel copy() {
    return KetionImageComponentViewModel(
      nodeId: nodeId,
      maxWidth: maxWidth,
      padding: padding,
      createdAt: createdAt,
      imageUrl: imageUrl,
      selectionColor: selectionColor,
      metadata: metadata,
      editor: editor,
    );
  }
}

class KetionImageComponent extends ConsumerStatefulWidget {
  const KetionImageComponent({
    super.key,
    required this.viewModel,
    this.showDebugPaint = false,
  });

  final KetionImageComponentViewModel viewModel;
  final bool showDebugPaint;

  @override
  ConsumerState<KetionImageComponent> createState() =>
      _KetionImageComponentState();
}

class _KetionImageComponentState extends ConsumerState<KetionImageComponent> {
  @override
  Widget build(BuildContext context) {
    final attachmentId = widget.viewModel.imageUrl;

    if (attachmentId.isEmpty) {
      return _buildPlaceholder(context, 'Empty image. Tap to select.');
    }

    // Try to load it as an attachment ID
    final attachmentAsync = ref.watch(attachmentProvider(attachmentId));

    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          // Fallback if not an attachment ID (maybe a direct URL from old data)
          if (attachmentId.startsWith('http')) {
            return _buildNetworkImage(attachmentId);
          }
          return _buildPlaceholder(context, 'Image not found.');
        }

        final pathAsync = ref.watch(attachmentPathProvider(attachment));
        return pathAsync.when(
          data: (localPath) {
            if (localPath == null) {
              return _buildPlaceholder(context, 'Image file not found.');
            }

            final progress = ref.watch(attachmentUploadProgressProvider(attachmentId));

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: MediaDimensions.width,
                  ),
                  child: AspectRatio(
                    aspectRatio: MediaDimensions.aspectRatio,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              MediaDimensions.borderRadius,
                            ),
                            child: ColoredBox(
                              color: Colors.black12,
                              child: kIsWeb
                                  ? Image.network(
                                      localPath,
                                      fit: BoxFit.contain,
                                    )
                                  : Image.file(
                                      io.File(localPath),
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                        ),
                        // Upload progress indicator overlay
                        if (progress != null)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Uploading... ${(progress * 100).toInt()}%',
                                          style: const TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                        const SizedBox(height: 4),
                                        LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.white24,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                    onPressed: () {
                                      ref.read(attachmentSyncServiceProvider).cancelSync(attachmentId);
                                    },
                                    tooltip: 'Cancel upload',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Top-right contextual menu button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                              tooltip: 'Image options',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onSelected: (value) async {
                                if (value == 'save') {
                                  final success = await ref
                                      .read(attachmentExportServiceProvider)
                                      .saveAttachmentToDevice(localPath);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Image saved successfully'
                                              : 'Failed to save image',
                                        ),
                                      ),
                                    );
                                  }
                                } else if (value == 'delete') {
                                  if (widget.viewModel.editor != null) {
                                    widget.viewModel.editor!.execute([
                                      DeleteNodeRequest(nodeId: widget.viewModel.nodeId),
                                    ]);
                                  }
                                  await ref
                                      .read(attachmentRepositoryProvider)
                                      .deleteAttachment(attachmentId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Image deleted from note')),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'save',
                                  child: Row(
                                    children: [
                                      Icon(Icons.download, size: 20),
                                      SizedBox(width: 8),
                                      Text('Save to device'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text('Delete from note', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) =>
              _buildPlaceholder(context, 'Error loading image path.'),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => _buildPlaceholder(context, 'Error loading image.'),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String text) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, size: 32, color: Colors.grey),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: MediaDimensions.width,
          ),
          child: AspectRatio(
            aspectRatio: MediaDimensions.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                MediaDimensions.borderRadius,
              ),
              child: ColoredBox(
                color: Colors.black12,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
