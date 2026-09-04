import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ketion/features/import_export/domain/models/document_model.dart';
import 'package:ketion/features/import_export/domain/services/export_repository.dart';
import 'package:path_provider/path_provider.dart';

class PdfExporter implements ExportRepository {
  @override
  String get fileExtension => 'pdf';

  @override
  Future<Uint8List> exportDocument(ExportDocument document) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];

          // Title
          widgets.add(
            pw.Header(
              level: 0,
              child: pw.Text(
                document.title,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 16));

          for (final node in document.nodes) {
            node.map(
              paragraph: (p) {
                widgets.add(
                  pw.Paragraph(
                    text: _extractPlainText(p.spans),
                  ),
                );
              },
              heading: (h) {
                final fontSize = 24.0 - (h.level * 2);
                widgets.add(
                  pw.Header(
                    level: h.level,
                    child: pw.Text(
                      _extractPlainText(h.spans),
                      style: pw.TextStyle(
                        fontSize: fontSize > 10 ? fontSize : 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              list: (l) {
                pw.Widget bullet;
                if (l.listType == 'checklist') {
                  bullet = pw.Container(
                    width: 10,
                    height: 10,
                    margin: const pw.EdgeInsets.only(right: 5, top: 2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                      color: l.checked ? PdfColors.black : PdfColors.white,
                    ),
                  );
                } else {
                  bullet = pw.Container(
                    width: 4,
                    height: 4,
                    margin: const pw.EdgeInsets.only(right: 8, top: 4),
                    decoration: const pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.black,
                    ),
                  );
                }
                widgets.add(
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      bullet,
                      pw.Expanded(
                        child: pw.Text(_extractPlainText(l.spans)),
                      ),
                    ],
                  ),
                );
                widgets.add(pw.SizedBox(height: 4));
              },
              image: (img) {
                // If the attachmentId is a local file path, we can load it.
                // In our app, attachments might be local paths. We'll try to load it.
                try {
                  final file = File(img.attachmentId);
                  if (file.existsSync()) {
                    final imageBytes = file.readAsBytesSync();
                    final provider = pw.MemoryImage(imageBytes);
                    widgets.add(
                      pw.Center(
                        child: pw.Image(provider),
                      ),
                    );
                    if (img.caption != null && img.caption!.isNotEmpty) {
                      widgets.add(
                        pw.Center(
                          child: pw.Text(
                            img.caption!,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey,
                            ),
                          ),
                        ),
                      );
                    }
                    widgets.add(pw.SizedBox(height: 16));
                  } else {
                    widgets.add(pw.Text('[Image: ${img.caption ?? img.attachmentId}]'));
                  }
                } catch (e) {
                  widgets.add(pw.Text('[Image error: ${img.caption ?? img.attachmentId}]'));
                }
              },
              file: (f) {
                widgets.add(
                  pw.Text('[File: ${f.caption ?? f.attachmentId}]', style: const pw.TextStyle(color: PdfColors.blue)),
                );
                widgets.add(pw.SizedBox(height: 8));
              },
            );
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // A simplified extraction since standard pdf package doesn't support complex RichText 
  // as easily across paragraphs without building nested trees. For MVP, we'll extract plain text 
  // or use basic RichText. For simplicity, let's use plain text first.
  String _extractPlainText(List<DocumentTextSpan> spans) {
    return spans.map((e) => e.text).join('');
  }
}
