import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import '../../../media/presentation/providers/attachment_provider.dart';

/// Ketion's custom ImageComponentBuilder to handle image attachments.
/// It uses Riverpod to fetch the local path of the attachment if `imageUrl` is an attachment ID.
class KetionImageComponentBuilder implements ComponentBuilder {
  const KetionImageComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
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

class KetionImageComponentViewModel extends SingleColumnLayoutComponentViewModel {
  KetionImageComponentViewModel({
    required super.nodeId,
    super.maxWidth,
    required super.padding,
    required super.createdAt,
    required this.imageUrl,
    required this.selectionColor,
    this.metadata = const {},
  });

  final String imageUrl;
  final Color selectionColor;
  final Map<String, dynamic> metadata;

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
  ConsumerState<KetionImageComponent> createState() => _KetionImageComponentState();
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

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: kIsWeb
                    ? Image.network(localPath, fit: BoxFit.contain)
                    : Image.file(io.File(localPath), fit: BoxFit.contain),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => _buildPlaceholder(context, 'Error loading image path.'),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(url, fit: BoxFit.contain),
      ),
    );
  }
}
