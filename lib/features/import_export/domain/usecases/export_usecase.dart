import 'dart:convert';
import 'dart:io' as io;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/domain/models/block_data_models.dart';
import 'package:ketion/features/import_export/domain/models/document_model.dart';
import 'package:ketion/features/import_export/domain/services/export_repository.dart';
import 'package:ketion/features/media/domain/entities/attachment.dart';
import 'package:ketion/features/media/domain/repositories/attachment_repository.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';
import 'package:share_plus/share_plus.dart';

class ExportUseCase {
  final List<ExportRepository> _exporters;
  final AttachmentRepository? _attachmentRepository;

  ExportUseCase(this._exporters, [this._attachmentRepository]);

  /// Exports a page to the selected format and shares it.
  Future<void> exportAndShare(
    Page page,
    List<Block> blocks,
    String extension,
  ) async {
    final exporter = _exporters.firstWhere((e) => e.fileExtension == extension);

    final document = await _mapToDocument(page, blocks);
    final bytes = await exporter.exportDocument(document);

    final sanitizedTitle = page.title.trim().isEmpty
        ? 'Untitled'
        : page.title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(' ', '_');
    final fileName = '$sanitizedTitle.$extension';

    if (!kIsWeb && io.Platform.isWindows) {
      final typeGroup = XTypeGroup(
        label: extension.toUpperCase(),
        extensions: [extension],
      );
      final fileSaveLocation = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [typeGroup],
      );
      if (fileSaveLocation == null) {
        return;
      }
      final file = io.File(fileSaveLocation.path);
      await file.writeAsBytes(bytes);
      return;
    }

    final xFile = XFile.fromData(
      bytes,
      name: fileName,
      mimeType: _getMimeType(extension),
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        subject: page.title,
      ),
    );
  }

  /// Exports a page to the selected format and returns the raw bytes.
  Future<Uint8List> exportToBytes(
    Page page,
    List<Block> blocks,
    String extension,
  ) async {
    final exporter = _exporters.firstWhere((e) => e.fileExtension == extension);
    final document = await _mapToDocument(page, blocks);
    return exporter.exportDocument(document);
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'md':
        return 'text/markdown';
      case 'json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  Future<ExportDocument> _mapToDocument(Page page, List<Block> blocks) async {
    final nodes = <DocumentNode>[];

    // The visible tree marks descendants of collapsed toggles as intentionally
    // hidden. Do not append unvisited blocks afterward, because that would leak
    // collapsed children into the PDF.
    final visibleTree = BlockTreeService.buildVisibleTree(blocks);

    for (final item in visibleTree.map(
      (visible) => (block: visible.block, depth: visible.depth),
    )) {
      final block = item.block;
      final depth = item.depth;
      final json = Map<String, dynamic>.from(
        jsonDecode(block.data) as Map<String, dynamic>,
      );
      final isToggle = block.type == 'toggle' ||
          json['listType'] == 'toggle' ||
          json['blockType'] == 'toggle' ||
          json['type'] == 'toggle';

      if (isToggle) {
        // Force legacy toggle records through the canonical list/toggle model.
        json['runtimeType'] = 'list';
        json['listType'] = 'toggle';
      } else if (!json.containsKey('runtimeType')) {
        json['runtimeType'] = block.type;
      }
      final blockDataModel = BlockDataModel.fromJson(json);

      await blockDataModel.maybeMap(
        text: (TextBlockData textBlock) async {
          if (textBlock.headingLevel > 0) {
            nodes.add(
              DocumentNode.heading(
                level: textBlock.headingLevel,
                spans: _mapSpans(textBlock.spans),
                depth: depth,
              ),
            );
          } else {
            nodes.add(
              DocumentNode.paragraph(
                spans: _mapSpans(textBlock.spans),
                depth: depth,
              ),
            );
          }
        },
        list: (ListBlockData listBlock) async {
          // Skip empty list nodes so they do not produce stray bullet points,
          // but preserve toggle headers even if empty so toggle hierarchy is maintained.
          final isToggle = listBlock.listType.toLowerCase() == 'toggle';
          final hasContent = listBlock.spans.isNotEmpty &&
              listBlock.spans.any((s) => s.text.trim().isNotEmpty);
          if (!hasContent && !isToggle) {
            return;
          }

          nodes.add(
            DocumentNode.list(
              listType: isToggle
                  ? (listBlock.isExpanded ? 'toggle_expanded' : 'toggle')
                  : listBlock.listType,
              checked: listBlock.checked,
              spans: _mapSpans(listBlock.spans),
              depth: depth,
              parentKey: block.parentBlockId,
            ),
          );
        },
        callout: (CalloutBlockData calloutBlock) async {
          nodes.add(
            DocumentNode.callout(
              icon: calloutBlock.icon,
              color: calloutBlock.color,
              spans: _mapSpans(calloutBlock.spans),
              depth: depth,
            ),
          );
        },
        table: (TableBlockData tableBlock) async {
          final rows = tableBlock.rows.map((r) {
            return r.cells
                .map((c) => c.spans.map((s) => s.text).join(''))
                .toList();
          }).toList();

          nodes.add(
            DocumentNode.table(
              columnCount: tableBlock.columnCount,
              rows: rows,
              depth: depth,
            ),
          );
        },
        divider: (DividerBlockData dividerBlock) async {
          nodes.add(DocumentNode.divider(depth: depth));
        },
        code: (CodeBlockData codeBlock) async {
          nodes.add(
            DocumentNode.code(
              language: codeBlock.language,
              code: codeBlock.code,
              depth: depth,
            ),
          );
        },
        image: (ImageBlockData imgBlock) async {
          final resolved = await _resolveAttachment(
            attachmentId: imgBlock.attachmentId,
            caption: imgBlock.caption,
            defaultTypeLabel: 'Image',
          );

          Uint8List? imageBytes;
          if (resolved.isAvailable && resolved.localFilePath != null) {
            try {
              final file = io.File(resolved.localFilePath!);
              if (await file.exists()) {
                imageBytes = await file.readAsBytes();
              }
            } catch (_) {}
          }

          nodes.add(
            DocumentNode.image(
              attachmentId: imgBlock.attachmentId,
              caption: imgBlock.caption,
              fileName: resolved.fileName,
              imageBytes: imageBytes,
              isAvailable: resolved.isAvailable && imageBytes != null,
              depth: depth,
            ),
          );
        },
        video: (VideoBlockData videoBlock) async {
          final resolved = await _resolveAttachment(
            attachmentId: videoBlock.attachmentId,
            caption: videoBlock.caption,
            defaultTypeLabel: 'Video',
          );
          nodes.add(
            DocumentNode.file(
              attachmentId: videoBlock.attachmentId,
              caption: videoBlock.caption,
              fileName: resolved.fileName,
              fileSize: resolved.fileSize,
              mimeType: resolved.mimeType,
              fileTypeLabel: 'Video',
              isAvailable: resolved.isAvailable,
              depth: depth,
            ),
          );
        },
        audio: (AudioBlockData audioBlock) async {
          final resolved = await _resolveAttachment(
            attachmentId: audioBlock.attachmentId,
            caption: audioBlock.caption,
            defaultTypeLabel: 'Audio',
          );
          nodes.add(
            DocumentNode.file(
              attachmentId: audioBlock.attachmentId,
              caption: audioBlock.caption,
              fileName: resolved.fileName,
              fileSize: resolved.fileSize,
              mimeType: resolved.mimeType,
              fileTypeLabel: 'Audio',
              isAvailable: resolved.isAvailable,
              depth: depth,
            ),
          );
        },
        pdf: (PdfBlockData pdfBlock) async {
          final resolved = await _resolveAttachment(
            attachmentId: pdfBlock.attachmentId,
            caption: pdfBlock.caption,
            defaultTypeLabel: 'PDF Document',
          );
          nodes.add(
            DocumentNode.file(
              attachmentId: pdfBlock.attachmentId,
              caption: pdfBlock.caption,
              fileName: resolved.fileName,
              fileSize: resolved.fileSize,
              mimeType: resolved.mimeType,
              fileTypeLabel: 'PDF Document',
              isAvailable: resolved.isAvailable,
              depth: depth,
            ),
          );
        },
        file: (FileBlockData fileBlock) async {
          final resolved = await _resolveAttachment(
            attachmentId: fileBlock.attachmentId,
            caption: fileBlock.caption,
            defaultTypeLabel: 'File Attachment',
          );
          nodes.add(
            DocumentNode.file(
              attachmentId: fileBlock.attachmentId,
              caption: fileBlock.caption,
              fileName: resolved.fileName,
              fileSize: resolved.fileSize,
              mimeType: resolved.mimeType,
              fileTypeLabel: 'File Attachment',
              isAvailable: resolved.isAvailable,
              depth: depth,
            ),
          );
        },
        bookmark: (BookmarkBlockData bookmarkBlock) async {
          nodes.add(
            DocumentNode.paragraph(
              spans: [
                DocumentTextSpan(
                  text: bookmarkBlock.title ?? bookmarkBlock.url,
                  link: bookmarkBlock.url,
                  bold: true,
                ),
              ],
              depth: depth,
            ),
          );
        },
        webLink: (WebLinkBlockData webLinkBlock) async {
          nodes.add(
            DocumentNode.paragraph(
              spans: [
                DocumentTextSpan(
                  text: webLinkBlock.url,
                  link: webLinkBlock.url,
                ),
              ],
              depth: depth,
            ),
          );
        },
        reminder: (ReminderBlockData reminderBlock) async {
          nodes.add(
            DocumentNode.paragraph(
              spans: [
                DocumentTextSpan(
                  text: '⏰ ${reminderBlock.title} (${reminderBlock.dueAt})',
                ),
              ],
              depth: depth,
            ),
          );
        },
        unknown: (UnknownBlockData _) async {},
        orElse: () async {},
      );
    }

    return ExportDocument(
      title: page.title,
      nodes: nodes,
      createdAt: page.createdAt,
      updatedAt: page.updatedAt,
    );
  }

  Future<_ResolvedAttachment> _resolveAttachment({
    required String attachmentId,
    String? caption,
    required String defaultTypeLabel,
  }) async {
    final repo = _attachmentRepository;
    Attachment? attachment;
    if (repo != null) {
      try {
        attachment = await repo.getAttachment(attachmentId);
      } catch (_) {}
    }

    String? localFilePath;
    bool isAvailable = false;
    int? fileSize = attachment?.fileSize;
    String? mimeType = attachment?.mimeType;

    if (attachment != null && repo != null) {
      try {
        final resolvedPath = await repo.resolveAttachmentPath(attachment);
        if (resolvedPath.isNotEmpty) {
          final file = io.File(resolvedPath);
          if (await file.exists()) {
            isAvailable = true;
            localFilePath = resolvedPath;
            fileSize ??= await file.length();
          }
        }
      } catch (_) {}
    }

    // Direct filesystem path fallback
    if (!isAvailable) {
      try {
        final directFile = io.File(attachmentId);
        if (await directFile.exists()) {
          isAvailable = true;
          localFilePath = attachmentId;
          fileSize ??= await directFile.length();
        }
      } catch (_) {}
    }

    String? resolvedFileName;
    if (caption != null && caption.trim().isNotEmpty) {
      resolvedFileName = caption.trim();
    } else if (localFilePath != null) {
      resolvedFileName = p.basename(localFilePath);
    } else if (attachment?.localPath != null) {
      resolvedFileName = p.basename(attachment!.localPath!);
    }

    return _ResolvedAttachment(
      fileName: resolvedFileName,
      localFilePath: localFilePath,
      fileSize: fileSize,
      mimeType: mimeType,
      isAvailable: isAvailable,
    );
  }

  List<DocumentTextSpan> _mapSpans(List<TextSpanData> spans) {
    return spans
        .map(
          (s) => DocumentTextSpan(
            text: s.text,
            bold: s.bold,
            italic: s.italic,
            underline: s.underline,
            strikethrough: s.strikethrough,
            code: s.code,
            link: s.link,
            pageLink: s.pageLinkTitle,
          ),
        )
        .toList();
  }
}

class _ResolvedAttachment {
  final String? fileName;
  final String? localFilePath;
  final int? fileSize;
  final String? mimeType;
  final bool isAvailable;

  const _ResolvedAttachment({
    this.fileName,
    this.localFilePath,
    this.fileSize,
    this.mimeType,
    required this.isAvailable,
  });
}
