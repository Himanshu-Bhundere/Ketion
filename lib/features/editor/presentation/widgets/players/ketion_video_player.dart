import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import '../../../../media/domain/entities/attachment_upload_status.dart';
import '../../../../media/presentation/providers/attachment_provider.dart';
import '../../../../media/data/repositories/attachment_repository_impl.dart';
import '../../../../media/data/services/attachment_export_service.dart';
import '../../../../media/data/services/attachment_sync_service_impl.dart';
import 'ketion_in_frame_player.dart';

class KetionVideoPlayerComponent extends ConsumerWidget {
  final String attachmentId;
  final String? nodeId;
  final Editor? editor;

  const KetionVideoPlayerComponent({
    super.key,
    required this.attachmentId,
    this.nodeId,
    this.editor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachmentId.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Invalid video block')),
      );
    }

    final attachmentAsync = ref.watch(attachmentProvider(attachmentId));
    final progress = ref.watch(attachmentUploadProgressProvider(attachmentId));

    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text('Video not found in database')),
          );
        }

        final pathAsync = ref.watch(attachmentPathProvider(attachment));

        return pathAsync.when(
          data: (localPath) {
            if (localPath == null) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Video file not available locally')),
              );
            }

            return Stack(
              children: [
                KetionInFramePlayer(filePath: localPath),
                // Top-right contextual menu button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      tooltip: 'Video options',
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
                                      ? 'Video saved successfully'
                                      : 'Failed to save video',
                                ),
                              ),
                            );
                          }
                        } else if (value == 'delete') {
                          if (editor != null && nodeId != null) {
                            editor!.execute([
                              DeleteNodeRequest(nodeId: nodeId!),
                            ]);
                          }
                          await ref
                              .read(attachmentRepositoryProvider)
                              .deleteAttachment(attachmentId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Video deleted from note')),
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
                // Upload progress overlay
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
                                  'Uploading video... ${(progress * 100).toInt()}%',
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
                if (progress == null &&
                    (attachment.uploadStatus == AttachmentUploadStatus.failed ||
                        attachment.uploadStatus == AttachmentUploadStatus.cancelled))
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Video upload failed or cancelled',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(attachmentSyncServiceProvider)
                                  .uploadAttachment(attachment);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => SizedBox(
            height: 100,
            child: Center(child: Text('Error loading video path: $e')),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => SizedBox(
        height: 100,
        child: Center(child: Text('Error loading video metadata: $e')),
      ),
    );
  }
}
