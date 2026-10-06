import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ketion/features/import_export/domain/models/document_model.dart';
import 'package:ketion/features/import_export/domain/services/export_repository.dart';

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

          // Document Title
          widgets.add(
            pw.Header(
              level: 0,
              child: pw.Text(
                document.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 16));

          for (final node in document.nodes) {
            node.map(
              paragraph: (p) {
                final text = _extractPlainText(p.spans);
                if (text.isNotEmpty) {
                  widgets.add(
                    pw.Paragraph(
                      text: text,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  );
                }
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
                final text = _extractPlainText(l.spans);
                // Skip empty list nodes so they do not produce stray bullet points
                if (text.trim().isEmpty) {
                  return;
                }

                pw.Widget bullet;
                if (l.listType == 'checklist') {
                  bullet = pw.Container(
                    width: 10,
                    height: 10,
                    margin: const pw.EdgeInsets.only(right: 6, top: 2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                      color: l.checked ? PdfColors.black : PdfColors.white,
                    ),
                  );
                } else if (l.listType == 'toggle') {
                  bullet = pw.Container(
                    margin: const pw.EdgeInsets.only(right: 6, top: 2),
                    child: pw.Text(
                      '>',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  );
                } else {
                  bullet = pw.Container(
                    width: 4,
                    height: 4,
                    margin: const pw.EdgeInsets.only(right: 8, top: 5),
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
                        child: pw.Text(
                          text,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
                widgets.add(pw.SizedBox(height: 4));
              },
              image: (img) {
                if (img.isAvailable && img.imageBytes != null && img.imageBytes!.isNotEmpty) {
                  try {
                    final provider = pw.MemoryImage(img.imageBytes!);
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
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                      );
                    }
                    widgets.add(pw.SizedBox(height: 12));
                  } catch (e) {
                    widgets.add(_buildUnavailableAttachmentCard('Image', img.caption ?? img.fileName));
                  }
                } else {
                  widgets.add(_buildUnavailableAttachmentCard('Image', img.caption ?? img.fileName));
                }
              },
              file: (f) {
                if (!f.isAvailable) {
                  widgets.add(_buildUnavailableAttachmentCard(f.fileTypeLabel, f.caption ?? f.fileName));
                } else {
                  widgets.add(_buildAttachmentCard(f));
                }
                widgets.add(pw.SizedBox(height: 6));
              },
              callout: (c) {
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 6),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (c.icon.isNotEmpty && c.icon.runes.every((r) => r <= 255))
                          pw.Text(c.icon, style: const pw.TextStyle(fontSize: 14))
                        else
                          pw.Container(
                            width: 16,
                            height: 16,
                            margin: const pw.EdgeInsets.only(top: 1),
                            decoration: const pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: PdfColors.blue700,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'i',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                            _extractPlainText(c.spans),
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              table: (t) {
                if (t.rows.isEmpty) return;
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                      children: t.rows.asMap().entries.map((entry) {
                        final rowIndex = entry.key;
                        final row = entry.value;
                        final isHeader = rowIndex == 0;
                        return pw.TableRow(
                          decoration: isHeader
                              ? const pw.BoxDecoration(color: PdfColors.grey200)
                              : null,
                          children: row.map((cellText) {
                            return pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                cellText,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: isHeader
                                      ? pw.FontWeight.bold
                                      : pw.FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              code: (c) {
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 4),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      c.code,
                      style: const pw.TextStyle(
                        fontSize: 9,
                      ),
                    ),
                  ),
                );
                widgets.add(pw.SizedBox(height: 6));
              },
              divider: (d) {
                widgets.add(pw.Divider(color: PdfColors.grey400));
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

  pw.Widget _buildAttachmentCard(DocFile f) {
    final displayName = (f.fileName != null && f.fileName!.isNotEmpty)
        ? f.fileName!
        : ((f.caption != null && f.caption!.isNotEmpty)
            ? f.caption!
            : 'Attached ${f.fileTypeLabel}');

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              f.fileTypeLabel.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  displayName,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: PdfColors.grey900,
                  ),
                ),
                if (f.fileSize != null && f.fileSize! > 0)
                  pw.Text(
                    _formatFileSize(f.fileSize!),
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildUnavailableAttachmentCard(String type, String? label) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey400, style: pw.BorderStyle.dashed),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            '[!]',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              label != null && label.isNotEmpty
                  ? 'Attachment unavailable: $label ($type)'
                  : 'Attachment unavailable ($type)',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _extractPlainText(List<DocumentTextSpan> spans) {
    return spans.map((e) => e.text).join('');
  }
}
