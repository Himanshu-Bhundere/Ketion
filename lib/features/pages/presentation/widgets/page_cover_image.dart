import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/presentation/providers/attachment_provider.dart';
import '../providers/page_providers.dart';

/// Central shared cover image component for workspace and editor surfaces across platforms.
class PageCoverImage extends ConsumerStatefulWidget {
  /// Default normalized aspect ratio used by both workspace and editor.
  static const double defaultAspectRatio = 3.5;

  final String pageId;
  final String coverImage;
  final double? initialOffset;
  final double aspectRatio;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final bool isRepositioning;
  final double? draftOffset;
  final ValueChanged<double>? onDraftOffsetChanged;
  final bool showRepositionControls;
  final Future<void> Function(double offset)? onSaveOffset;
  final VoidCallback? onCancelReposition;

  const PageCoverImage({
    super.key,
    required this.pageId,
    required this.coverImage,
    this.initialOffset,
    this.aspectRatio = defaultAspectRatio,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.isRepositioning = false,
    this.draftOffset,
    this.onDraftOffsetChanged,
    this.showRepositionControls = false,
    this.onSaveOffset,
    this.onCancelReposition,
  });

  @override
  ConsumerState<PageCoverImage> createState() => _PageCoverImageState();
}

class _PageCoverImageState extends ConsumerState<PageCoverImage> {
  double _localDraft = 0.5;

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      color: Colors.grey.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: const Text(
        'Could not load cover image',
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Container(
      color: Colors.grey.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator.adaptive(strokeWidth: 2),
      ),
    );
  }

  Widget _buildRawImage(
    BuildContext context,
    Alignment alignment,
  ) {
    final cover = widget.coverImage;

    // 1. Direct network image
    if (cover.startsWith('http://') || cover.startsWith('https://')) {
      return Image.network(
        cover,
        fit: widget.fit,
        alignment: alignment,
        width: widget.width ?? double.infinity,
        height: widget.height,
        errorBuilder: (_, __, ___) => _buildErrorWidget(context),
      );
    }

    // 2. Direct local file path
    if (!kIsWeb && io.File(cover).existsSync()) {
      return Image.file(
        io.File(cover),
        fit: widget.fit,
        alignment: alignment,
        width: widget.width ?? double.infinity,
        height: widget.height,
        errorBuilder: (_, __, ___) => _buildErrorWidget(context),
      );
    }

    // 3. Attachment resolution through Riverpod providers
    final attachmentAsync = ref.watch(attachmentProvider(cover));
    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          return _buildErrorWidget(context);
        }
        final pathAsync = ref.watch(attachmentPathProvider(attachment));
        return pathAsync.when(
          data: (localPath) {
            if (localPath == null || localPath.isEmpty) {
              return _buildErrorWidget(context);
            }
            if (kIsWeb) {
              return Image.network(
                localPath,
                fit: widget.fit,
                alignment: alignment,
                width: widget.width ?? double.infinity,
                height: widget.height,
                errorBuilder: (_, __, ___) => _buildErrorWidget(context),
              );
            }
            return Image.file(
              io.File(localPath),
              fit: widget.fit,
              alignment: alignment,
              width: widget.width ?? double.infinity,
              height: widget.height,
              errorBuilder: (_, __, ___) => _buildErrorWidget(context),
            );
          },
          loading: () => _buildLoadingWidget(context),
          error: (_, __) => _buildErrorWidget(context),
        );
      },
      loading: () => _buildLoadingWidget(context),
      error: (_, __) => _buildErrorWidget(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storedOffsetAsync = ref.watch(pageCoverOffsetProvider(widget.pageId));
    final storedOffset =
        storedOffsetAsync.valueOrNull ?? widget.initialOffset ?? 0.5;

    final effectiveDraft = widget.draftOffset ?? _localDraft;
    final offset = (widget.isRepositioning
            ? effectiveDraft
            : (widget.draftOffset ?? storedOffset))
        .clamp(0.0, 1.0);

    final alignment = Alignment(
      0,
      offset * 2 - 1,
    );

    Widget imageContent = _buildRawImage(context, alignment);

    if (widget.isRepositioning) {
      imageContent = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) {
          final box = context.findRenderObject() as RenderBox?;
          final renderHeight =
              (box != null && box.hasSize && box.size.height > 0)
                  ? box.size.height
                  : 160.0;
          // Dragging up moves the visible window down (showing lower parts of image => increasing offset)
          // Dragging down moves window up (showing upper parts => decreasing offset)
          final newOffset =
              (offset - (details.primaryDelta ?? 0) / renderHeight)
                  .clamp(0.0, 1.0);
          setState(() => _localDraft = newOffset);
          widget.onDraftOffsetChanged?.call(newOffset);
        },
        child: imageContent,
      );
    }

    Widget content = imageContent;

    if (widget.showRepositionControls && widget.isRepositioning) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_vert, color: Colors.white70, size: 18),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: offset,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          setState(() => _localDraft = val);
                          widget.onDraftOffsetChanged?.call(val);
                        },
                      ),
                    ),
                  ),
                  if (widget.onSaveOffset != null)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => widget.onSaveOffset!(offset),
                      child: const Text('Save', style: TextStyle(fontSize: 12)),
                    ),
                  if (widget.onCancelReposition != null)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: widget.onCancelReposition,
                      child:
                          const Text('Cancel', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (widget.height == null && widget.aspectRatio > 0) {
      content = AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: content,
      );
    } else if (widget.width != null || widget.height != null) {
      content = SizedBox(
        width: widget.width,
        height: widget.height,
        child: content,
      );
    }

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }
}
