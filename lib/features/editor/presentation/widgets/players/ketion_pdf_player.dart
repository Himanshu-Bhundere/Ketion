import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import '../../../../media/presentation/providers/attachment_provider.dart';
import '../../../../../core/utils/attachment_launcher.dart';

class KetionPdfPlayerComponent extends ConsumerStatefulWidget {
  final String attachmentId;

  const KetionPdfPlayerComponent({
    super.key,
    required this.attachmentId,
  });

  @override
  ConsumerState<KetionPdfPlayerComponent> createState() => _KetionPdfPlayerComponentState();
}

class _KetionPdfPlayerComponentState extends ConsumerState<KetionPdfPlayerComponent> {
  PdfController? _pdfController;

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  void _initController(String path) {
    if (_pdfController != null) return;
    _pdfController = PdfController(
      document: PdfDocument.openFile(path),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachmentId.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Invalid PDF block')),
      );
    }

    final attachmentAsync = ref.watch(attachmentProvider(widget.attachmentId));

    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text('PDF not found in database')),
          );
        }

        final pathAsync = ref.watch(attachmentPathProvider(attachment));

        return pathAsync.when(
          data: (localPath) {
            if (localPath == null) {
              return const SizedBox(
                height: 100,
                child: Center(child: Text('PDF file not available locally')),
              );
            }

            _initController(localPath);
            
            final fileName = attachment.localPath?.split('/').last ?? 'Document.pdf';
            final fileSize = attachment.fileSize / 1024 / 1024;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                    child: PdfView(
                      controller: _pdfController!,
                      scrollDirection: Axis.vertical,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fileName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${fileSize.toStringAsFixed(2)} MB',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () {
                          ref.read(attachmentLauncherProvider).launch(localPath);
                        },
                        tooltip: 'Open in external viewer',
                      ),
                    ],
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
            child: Center(child: Text('Error loading PDF path: $e')),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => SizedBox(
        height: 100,
        child: Center(child: Text('Error loading PDF metadata: $e')),
      ),
    );
  }
}
