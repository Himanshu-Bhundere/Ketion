import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:super_editor/super_editor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/media_nodes.dart';
import '../../../media/presentation/providers/attachment_provider.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import 'ketion_edit_requests.dart';

abstract class KetionAttachmentComponentViewModel extends SingleColumnLayoutComponentViewModel {
  final String? attachmentId;
  KetionAttachmentComponentViewModel({
    required super.nodeId,
    super.maxWidth,
    required super.padding,
    required super.createdAt,
    this.attachmentId,
  });
}

class KetionVideoComponentViewModel extends KetionAttachmentComponentViewModel {
  KetionVideoComponentViewModel({required super.nodeId, super.maxWidth, required super.padding, required super.createdAt, super.attachmentId});
  @override KetionVideoComponentViewModel copy() => KetionVideoComponentViewModel(nodeId: nodeId, maxWidth: maxWidth, padding: padding, createdAt: createdAt, attachmentId: attachmentId);
}

class KetionAudioComponentViewModel extends KetionAttachmentComponentViewModel {
  KetionAudioComponentViewModel({required super.nodeId, super.maxWidth, required super.padding, required super.createdAt, super.attachmentId});
  @override KetionAudioComponentViewModel copy() => KetionAudioComponentViewModel(nodeId: nodeId, maxWidth: maxWidth, padding: padding, createdAt: createdAt, attachmentId: attachmentId);
}

class KetionPdfComponentViewModel extends KetionAttachmentComponentViewModel {
  KetionPdfComponentViewModel({required super.nodeId, super.maxWidth, required super.padding, required super.createdAt, super.attachmentId});
  @override KetionPdfComponentViewModel copy() => KetionPdfComponentViewModel(nodeId: nodeId, maxWidth: maxWidth, padding: padding, createdAt: createdAt, attachmentId: attachmentId);
}

class KetionFileComponentViewModel extends KetionAttachmentComponentViewModel {
  KetionFileComponentViewModel({required super.nodeId, super.maxWidth, required super.padding, required super.createdAt, super.attachmentId});
  @override KetionFileComponentViewModel copy() => KetionFileComponentViewModel(nodeId: nodeId, maxWidth: maxWidth, padding: padding, createdAt: createdAt, attachmentId: attachmentId);
}

class KetionBookmarkComponentViewModel extends SingleColumnLayoutComponentViewModel {
  final String? url;
  KetionBookmarkComponentViewModel({required super.nodeId, super.maxWidth, required super.padding, required super.createdAt, this.url});
  @override KetionBookmarkComponentViewModel copy() => KetionBookmarkComponentViewModel(nodeId: nodeId, maxWidth: maxWidth, padding: padding, createdAt: createdAt, url: url);
}

class KetionPageLinkComponentViewModel extends SingleColumnLayoutComponentViewModel {
  final String? pageId;
  KetionPageLinkComponentViewModel({required super.nodeId, super.maxWidth, required super.padding, required super.createdAt, this.pageId});
  @override KetionPageLinkComponentViewModel copy() => KetionPageLinkComponentViewModel(nodeId: nodeId, maxWidth: maxWidth, padding: padding, createdAt: createdAt, pageId: pageId);
}

class KetionWebLinkComponentViewModel extends SingleColumnLayoutComponentViewModel {
  final String? url;
  KetionWebLinkComponentViewModel({required super.nodeId, super.maxWidth, required super.padding, required super.createdAt, this.url});
  @override KetionWebLinkComponentViewModel copy() => KetionWebLinkComponentViewModel(nodeId: nodeId, maxWidth: maxWidth, padding: padding, createdAt: createdAt, url: url);
}

class KetionReminderComponentViewModel extends SingleColumnLayoutComponentViewModel {
  final String title;
  final String dueAt;
  final bool completed;
  final void Function(String title, String dueAt, bool completed)? onReminderChanged;

  KetionReminderComponentViewModel({
    required super.nodeId,
    super.maxWidth,
    required super.padding,
    required super.createdAt,
    required this.title,
    required this.dueAt,
    required this.completed,
    this.onReminderChanged,
  });

  @override
  KetionReminderComponentViewModel copy() {
    return KetionReminderComponentViewModel(
      nodeId: nodeId,
      maxWidth: maxWidth,
      padding: padding,
      createdAt: createdAt,
      title: title,
      dueAt: dueAt,
      completed: completed,
      onReminderChanged: onReminderChanged,
    );
  }
}

class KetionVideoComponentBuilder implements ComponentBuilder {
  const KetionVideoComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! KetionVideoNode) return null;
    return KetionVideoComponentViewModel(nodeId: node.id, attachmentId: node.attachmentId, maxWidth: double.infinity, padding: EdgeInsets.zero, createdAt: null);
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! KetionVideoComponentViewModel) return null;
    return KetionAttachmentFileCard(
      key: componentContext.componentKey,
      attachmentId: componentViewModel.attachmentId,
      icon: Icons.videocam,
      label: 'Video',
    );
  }
}

class KetionAudioComponentBuilder implements ComponentBuilder {
  const KetionAudioComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! KetionAudioNode) return null;
    return KetionAudioComponentViewModel(nodeId: node.id, attachmentId: node.attachmentId, maxWidth: double.infinity, padding: EdgeInsets.zero, createdAt: null);
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! KetionAudioComponentViewModel) return null;
    return KetionAttachmentFileCard(
      key: componentContext.componentKey,
      attachmentId: componentViewModel.attachmentId,
      icon: Icons.audiotrack,
      label: 'Audio',
    );
  }
}

class KetionPdfComponentBuilder implements ComponentBuilder {
  const KetionPdfComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! KetionPdfNode) return null;
    return KetionPdfComponentViewModel(nodeId: node.id, attachmentId: node.attachmentId, maxWidth: double.infinity, padding: EdgeInsets.zero, createdAt: null);
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! KetionPdfComponentViewModel) return null;
    return KetionAttachmentFileCard(
      key: componentContext.componentKey,
      attachmentId: componentViewModel.attachmentId,
      icon: Icons.picture_as_pdf,
      label: 'PDF',
    );
  }
}

class KetionFileComponentBuilder implements ComponentBuilder {
  const KetionFileComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! KetionFileNode) return null;
    return KetionFileComponentViewModel(nodeId: node.id, attachmentId: node.attachmentId, maxWidth: double.infinity, padding: EdgeInsets.zero, createdAt: null);
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! KetionFileComponentViewModel) return null;
    return KetionAttachmentFileCard(
      key: componentContext.componentKey,
      attachmentId: componentViewModel.attachmentId,
      icon: Icons.insert_drive_file,
      label: 'File',
    );
  }
}

class KetionBookmarkComponentBuilder implements ComponentBuilder {
  const KetionBookmarkComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! KetionBookmarkNode) return null;
    return KetionBookmarkComponentViewModel(nodeId: node.id, maxWidth: double.infinity, padding: EdgeInsets.zero, url: node.url, createdAt: null);
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! KetionBookmarkComponentViewModel) return null;
    return _LinkCard(icon: Icons.bookmark_border, label: 'Bookmark', url: componentViewModel.url ?? '');
  }
}

class KetionPageLinkComponentBuilder implements ComponentBuilder {
  const KetionPageLinkComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! KetionPageLinkNode) return null;
    return KetionPageLinkComponentViewModel(nodeId: node.id, pageId: node.pageId, maxWidth: double.infinity, padding: EdgeInsets.zero, createdAt: null);
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! KetionPageLinkComponentViewModel) return null;
    return _PageLinkCard(pageId: componentViewModel.pageId ?? '');
  }
}

class KetionWebLinkComponentBuilder implements ComponentBuilder {
  const KetionWebLinkComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! KetionWebLinkNode) return null;
    return KetionWebLinkComponentViewModel(nodeId: node.id, maxWidth: double.infinity, padding: EdgeInsets.zero, url: node.url, createdAt: null);
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! KetionWebLinkComponentViewModel) return null;
    return _LinkCard(icon: Icons.public, label: 'Web Bookmark', url: componentViewModel.url ?? '');
  }
}

class KetionReminderComponentBuilder implements ComponentBuilder {
  const KetionReminderComponentBuilder(this.editor);

  final Editor editor;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! KetionReminderNode) return null;
    return KetionReminderComponentViewModel(
      nodeId: node.id, 
      title: node.title,
      dueAt: node.dueAt, 
      completed: node.completed,
      maxWidth: double.infinity, 
      padding: EdgeInsets.zero, 
      createdAt: null,
      onReminderChanged: (String newTitle, String newDueAt, bool newCompleted) {
        editor.execute([
          UpdateReminderRequest(
            nodeId: node.id,
            title: newTitle,
            dueAt: newDueAt,
            completed: newCompleted,
          ),
        ]);
      },
    );
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! KetionReminderComponentViewModel) return null;
    return _ReminderCard(viewModel: componentViewModel, context: componentContext);
  }
}

class KetionAttachmentFileCard extends ConsumerStatefulWidget {
  const KetionAttachmentFileCard({
    super.key,
    required this.attachmentId,
    required this.icon,
    required this.label,
  });

  final String? attachmentId;
  final IconData icon;
  final String label;

  @override
  ConsumerState<KetionAttachmentFileCard> createState() => _KetionAttachmentFileCardState();
}

class _KetionAttachmentFileCardState extends ConsumerState<KetionAttachmentFileCard> {
  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final attachmentId = widget.attachmentId;

    if (attachmentId == null || attachmentId.isEmpty) {
      return _buildPlaceholder(context, 'Empty attachment.');
    }

    final attachmentAsync = ref.watch(attachmentProvider(attachmentId));

    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          return _buildPlaceholder(context, 'Attachment not found.');
        }

        final pathAsync = ref.watch(attachmentPathProvider(attachment));
        
        return pathAsync.when(
          data: (localPath) {
            final fileName = localPath != null ? localPath.split(RegExp(r'[\\/]')).last : 'Unknown file';
            final fileSize = _formatBytes(attachment.fileSize);
            
            return _buildCard(
              context: context,
              title: fileName,
              subtitle: '$fileSize • ${widget.label}',
              onTap: localPath != null ? () => OpenFile.open(localPath) : null,
            );
          },
          loading: () => _buildCard(
            context: context,
            title: 'Loading...',
            subtitle: widget.label,
            isLoading: true,
          ),
          error: (e, st) => _buildPlaceholder(context, 'Error loading file.'),
        );
      },
      loading: () => _buildCard(
        context: context,
        title: 'Loading...',
        subtitle: widget.label,
        isLoading: true,
      ),
      error: (e, st) => _buildPlaceholder(context, 'Error loading attachment metadata.'),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(widget.icon, size: 24, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildPlaceholder(BuildContext context, String text) {
    return _buildCard(context: context, title: text, subtitle: widget.label);
  }
}

class _MediaPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MediaPlaceholder({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: Colors.grey),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Coming Soon', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LinkCard({required this.icon, required this.label, required this.url});

  Future<void> _launchUrl() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchUrl,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                  ),
                  child: Icon(icon, size: 24, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        url.isEmpty ? 'Empty $label' : url,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageLinkCard extends ConsumerWidget {
  final String pageId;

  const _PageLinkCard({required this.pageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pageId.isEmpty) {
       return const _MediaPlaceholder(icon: Icons.insert_link, label: 'Empty page link');
    }
    
    final pageAsync = ref.watch(pageProvider(pageId));
    
    return pageAsync.when(
      data: (page) {
        final title = page?.title ?? 'Unknown Page';
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Future: Add routing to the page
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                      ),
                      child: Icon(Icons.insert_drive_file_outlined, size: 24, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title.isEmpty ? 'Untitled' : title,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Link to page',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const _MediaPlaceholder(icon: Icons.insert_link, label: 'Loading page...'),
      error: (e, st) => const _MediaPlaceholder(icon: Icons.error_outline, label: 'Error loading page'),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final KetionReminderComponentViewModel viewModel;
  final SingleColumnDocumentComponentContext context;

  const _ReminderCard({
    required this.viewModel,
    required this.context,
  });

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'No date set';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final dateStr = '${months[date.month - 1]} ${date.day}, ${date.year} at $timeStr';
    
    return dateStr;
  }

  @override
  Widget build(BuildContext buildContext) {
    final isDark = Theme.of(buildContext).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final currentDate = DateTime.tryParse(viewModel.dueAt);
            final pickedDate = await showDatePicker(
              context: buildContext,
              initialDate: currentDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            
            if (pickedDate != null) {
              if (!buildContext.mounted) return;
              final pickedTime = await showTimePicker(
                context: buildContext,
                initialTime: currentDate != null 
                    ? TimeOfDay.fromDateTime(currentDate) 
                    : TimeOfDay.now(),
              );
              
              if (pickedTime != null) {
                final finalDateTime = DateTime.utc(
                  pickedDate.year, 
                  pickedDate.month, 
                  pickedDate.day, 
                  pickedTime.hour, 
                  pickedTime.minute,
                );
                viewModel.onReminderChanged?.call(
                  viewModel.title,
                  finalDateTime.toIso8601String(), 
                  viewModel.completed,
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                  ),
                  child: Icon(Icons.access_time, size: 24, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.title.isNotEmpty ? viewModel.title : 'Reminder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(viewModel.dueAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: viewModel.completed,
                  onChanged: (bool? newValue) {
                    if (newValue != null) {
                      viewModel.onReminderChanged?.call(
                        viewModel.title,
                        viewModel.dueAt,
                        newValue,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
