import 'dart:convert';
import 'dart:io';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/domain/models/block_data_models.dart';
import 'package:ketion/features/import_export/domain/models/document_model.dart';
import 'package:ketion/features/import_export/domain/services/export_repository.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportUseCase {
  final List<ExportRepository> _exporters;

  ExportUseCase(this._exporters);

  /// Exports a page to the selected format and shares it.
  Future<void> exportAndShare(Page page, List<Block> blocks, String extension) async {
    final exporter = _exporters.firstWhere((e) => e.fileExtension == extension);
    
    final document = _mapToDocument(page, blocks);
    final bytes = await exporter.exportDocument(document);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${page.title.replaceAll(' ', '_')}.$extension');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: page.title,
    ),);
  }

  ExportDocument _mapToDocument(Page page, List<Block> blocks) {
    final nodes = <DocumentNode>[];

    for (final block in blocks) {
      final blockDataModel = BlockDataModel.fromJson(jsonDecode(block.data) as Map<String, dynamic>);
      blockDataModel.map(
        text: (TextBlockData textBlock) {
          if (textBlock.headingLevel > 0) {
            nodes.add(DocumentNode.heading(
              level: textBlock.headingLevel,
              spans: _mapSpans(textBlock.spans),
            ),);
          } else {
            nodes.add(DocumentNode.paragraph(
              spans: _mapSpans(textBlock.spans),
            ),);
          }
        },
        list: (ListBlockData listBlock) {
          nodes.add(DocumentNode.list(
            listType: listBlock.listType,
            checked: listBlock.checked,
            spans: _mapSpans(listBlock.spans),
          ),);
        },
        image: (ImageBlockData imgBlock) {
          nodes.add(DocumentNode.image(
            attachmentId: imgBlock.attachmentId,
            caption: imgBlock.caption,
          ),);
        },
        video: (VideoBlockData videoBlock) {
          nodes.add(DocumentNode.file(
            attachmentId: videoBlock.attachmentId,
            caption: videoBlock.caption,
          ),);
        },
        audio: (AudioBlockData audioBlock) {
          nodes.add(DocumentNode.file(
            attachmentId: audioBlock.attachmentId,
            caption: audioBlock.caption,
          ),);
        },
        pdf: (PdfBlockData pdfBlock) {
          nodes.add(DocumentNode.file(
            attachmentId: pdfBlock.attachmentId,
            caption: pdfBlock.caption,
          ),);
        },
        file: (FileBlockData fileBlock) {
          nodes.add(DocumentNode.file(
            attachmentId: fileBlock.attachmentId,
            caption: fileBlock.caption,
          ),);
        },
        unknown: (UnknownBlockData _) {
          // Skip or handle unknown
        },
      );
    }

    return ExportDocument(
      title: page.title,
      nodes: nodes,
      createdAt: page.createdAt,
      updatedAt: page.updatedAt,
    );
  }

  List<DocumentTextSpan> _mapSpans(List<TextSpanData> spans) {
    return spans.map((s) => DocumentTextSpan(
      text: s.text,
      bold: s.bold,
      italic: s.italic,
      underline: s.underline,
      strikethrough: s.strikethrough,
      code: s.code,
      link: s.link,
      pageLink: s.pageLinkTitle,
    ),).toList();
  }
}
