import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ketion/features/import_export/domain/models/document_model.dart';
import 'package:ketion/features/import_export/domain/services/export_repository.dart';
import 'package:ketion/features/editor/domain/services/list_numbering_service.dart';

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
                _sanitizeTextForPdf(document.title),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 16));

          // Derive parent key for each flattened node using the most recent node at the preceding depth
          final numberingEntries = <ListNumberingEntry>[];
          for (int i = 0; i < document.nodes.length; i++) {
            final node = document.nodes[i];
            final nodeDepth = node.depth;
            String? parentKey;
            String? listType;

            node.map(
              paragraph: (_) {},
              heading: (_) {},
              list: (l) {
                listType = l.listType;
                parentKey = l.parentKey;
              },
              image: (_) {},
              file: (_) {},
              callout: (_) {},
              table: (_) {},
              code: (_) {},
              divider: (_) {},
            );

            // Backward-compatible fallback: infer parent if parentKey was not explicitly provided
            if (parentKey == null && nodeDepth > 0) {
              for (int j = i - 1; j >= 0; j--) {
                final prevDepth = document.nodes[j].depth;
                if (prevDepth == nodeDepth - 1) {
                  parentKey = 'export-node-$j';
                  break;
                } else if (prevDepth < nodeDepth - 1) {
                  break;
                }
              }
            }

            numberingEntries.add(
              ListNumberingEntry(
                key: 'export-node-$i',
                listType: listType,
                depth: nodeDepth,
                parentKey: parentKey,
              ),
            );
          }

          final computedOrdinals =
              ListNumberingService.computeOrdinals(numberingEntries);

          final activeToggleDepths = <int>[];

          for (int i = 0; i < document.nodes.length; i++) {
            final node = document.nodes[i];
            final nodeDepth = node.depth;

            // Leave any toggle whose subtree has ended.
            while (activeToggleDepths.isNotEmpty &&
                activeToggleDepths.last >= nodeDepth) {
              activeToggleDepths.removeLast();
            }

            final isNestedUnderToggle = activeToggleDepths.isNotEmpty &&
                nodeDepth > activeToggleDepths.last;

            var isToggleHeader = false;
            node.map(
              paragraph: (_) {},
              heading: (_) {},
              list: (l) {
                isToggleHeader =
                    l.listType == 'toggle' || l.listType == 'toggle_expanded';
              },
              image: (_) {},
              file: (_) {},
              callout: (_) {},
              table: (_) {},
              code: (_) {},
              divider: (_) {},
            );

            pw.Widget? renderedWidget;

            node.map(
              paragraph: (p) {
                final hasContent = p.spans.any((s) => s.text.isNotEmpty);
                if (hasContent) {
                  renderedWidget = pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: _spansToPdfWidget(p.spans, fontSize: 11),
                  );
                }
              },
              heading: (h) {
                final fontSize = (24.0 - (h.level * 2)).clamp(10.0, 24.0);
                renderedWidget = pw.Header(
                  level: h.level,
                  child: _spansToPdfWidget(
                    h.spans,
                    fontSize: fontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                );
              },
              list: (l) {
                final text = _extractPlainText(l.spans);
                // Skip empty list nodes so they do not produce stray bullet points or markers,
                // but preserve toggle items so their structure remains intact.
                if (text.trim().isEmpty &&
                    l.listType != 'toggle' &&
                    l.listType != 'toggle_expanded') {
                  return;
                }

                pw.Widget bullet;
                if (l.listType == 'checklist') {
                  bullet = pw.Container(
                    width: 10,
                    height: 10,
                    margin: const pw.EdgeInsets.only(right: 6, top: 2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey800, width: 1),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(2)),
                      color: l.checked ? PdfColors.grey900 : PdfColors.white,
                    ),
                    child: l.checked
                        ? pw.Center(
                            child: pw.CustomPaint(
                              size: const PdfPoint(6, 6),
                              painter: (PdfGraphics canvas, PdfPoint size) {
                                canvas.setColor(PdfColors.white);
                                canvas.setLineWidth(1.2);
                                canvas.moveTo(1, 3);
                                canvas.lineTo(2.5, 1);
                                canvas.lineTo(5, 5);
                                canvas.strokePath();
                              },
                            ),
                          )
                        : null,
                  );
                } else if (l.listType == 'toggle' ||
                    l.listType == 'toggle_expanded') {
                  final isExpanded = l.listType == 'toggle_expanded';

                  bullet = pw.Container(
                    width: 8,
                    height: 8,
                    margin: const pw.EdgeInsets.only(right: 6, top: 3),
                    child: pw.CustomPaint(
                      size: const PdfPoint(8, 8),
                      painter: (PdfGraphics canvas, PdfPoint size) {
                        canvas.setColor(PdfColors.grey800);

                        if (isExpanded) {
                          canvas.moveTo(1, 2);
                          canvas.lineTo(4, 7);
                          canvas.lineTo(7, 2);
                        } else {
                          canvas.moveTo(2, 1);
                          canvas.lineTo(7, 4);
                          canvas.lineTo(2, 7);
                        }

                        canvas.closePath();
                        canvas.fillPath();
                      },
                    ),
                  );
                } else if (l.listType == 'numbered') {
                  final num = computedOrdinals['export-node-$i'] ?? 1;
                  bullet = pw.Container(
                    margin: const pw.EdgeInsets.only(right: 6, top: 1),
                    child: pw.Text(
                      '$num.',
                      style: const pw.TextStyle(fontSize: 11),
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

                renderedWidget = pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        bullet,
                        pw.Expanded(
                          child: _spansToPdfWidget(
                            l.spans,
                            fontSize: 11,
                            baseDecoration: l.listType == 'checklist' && l.checked
                                ? pw.TextDecoration.lineThrough
                                : pw.TextDecoration.none,
                            defaultColor: l.listType == 'checklist' && l.checked
                                ? PdfColors.grey700
                                : null,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                  ],
                );
              },
              image: (img) {
                if (img.isAvailable &&
                    img.imageBytes != null &&
                    img.imageBytes!.isNotEmpty) {
                  try {
                    final provider = pw.MemoryImage(img.imageBytes!);
                    renderedWidget = pw.Column(
                      children: [
                        pw.Center(
                          child: pw.Image(provider),
                        ),
                        if (img.caption != null && img.caption!.isNotEmpty)
                          pw.Center(
                            child: pw.Text(
                              img.caption!,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ),
                        pw.SizedBox(height: 12),
                      ],
                    );
                  } catch (e) {
                    renderedWidget = _buildUnavailableAttachmentCard(
                      'Image',
                      img.caption ?? img.fileName,
                    );
                  }
                } else {
                  renderedWidget = _buildUnavailableAttachmentCard(
                    'Image',
                    img.caption ?? img.fileName,
                  );
                }
              },
              file: (f) {
                renderedWidget = pw.Column(
                  children: [
                    if (!f.isAvailable)
                      _buildUnavailableAttachmentCard(
                        f.fileTypeLabel,
                        f.caption ?? f.fileName,
                      )
                    else
                      _buildAttachmentCard(f),
                    pw.SizedBox(height: 6),
                  ],
                );
              },
              callout: (c) {
                renderedWidget = pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 6),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (c.icon.isNotEmpty &&
                          c.icon.runes.every((r) => r <= 255))
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
                );
              },
              table: (t) {
                if (t.rows.isEmpty) return;
                renderedWidget = pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey400,
                      width: 0.5,
                    ),
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
                );
              },
              code: (c) {
                renderedWidget = pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      margin: const pw.EdgeInsets.symmetric(vertical: 4),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        c.code,
                        style: const pw.TextStyle(
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                  ],
                );
              },
              divider: (d) {
                renderedWidget = pw.Column(
                  children: [
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 8),
                  ],
                );
              },
            );

            if (renderedWidget != null) {
              final groupedWidget = isNestedUnderToggle
                  ? pw.Container(
                      padding: const pw.EdgeInsets.only(left: 6),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(
                            color: PdfColors.grey300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: renderedWidget!,
                    )
                  : renderedWidget!;

              widgets.add(
                pw.Padding(
                  padding: pw.EdgeInsets.only(
                    left: nodeDepth.clamp(0, 20) * 24.0,
                    bottom: 6,
                  ),
                  child: groupedWidget,
                ),
              );
            }

            if (isToggleHeader) {
              activeToggleDepths.add(nodeDepth);
            }
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
        border: pw.Border.all(
          color: PdfColors.grey400,
          style: pw.BorderStyle.dashed,
        ),
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

  pw.Widget _spansToPdfWidget(
    List<DocumentTextSpan> spans, {
    double fontSize = 11,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    pw.TextDecoration? baseDecoration,
    PdfColor? defaultColor,
  }) {
    if (spans.isEmpty) {
      return pw.Text(' ', style: pw.TextStyle(fontSize: fontSize));
    }

    final children = <pw.InlineSpan>[];
    for (final span in spans) {
      final safeText = _sanitizeTextForPdf(span.text);
      if (safeText.isEmpty) continue;

      pw.TextDecoration decoration = baseDecoration ?? pw.TextDecoration.none;
      if (span.strikethrough) {
        decoration = pw.TextDecoration.lineThrough;
      } else if (span.underline) {
        decoration = pw.TextDecoration.underline;
      }

      final spanWeight = span.bold ? pw.FontWeight.bold : fontWeight;

      children.add(
        pw.TextSpan(
          text: safeText,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: spanWeight,
            fontStyle: span.italic ? pw.FontStyle.italic : pw.FontStyle.normal,
            decoration: decoration,
            color: span.link != null
                ? PdfColors.blue700
                : (span.code ? PdfColors.grey900 : defaultColor),
            background: span.code
                ? const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                  )
                : null,
          ),
        ),
      );
    }

    if (children.isEmpty) {
      return pw.Text(' ', style: pw.TextStyle(fontSize: fontSize));
    }

    return pw.RichText(
      text: pw.TextSpan(children: children),
    );
  }

  String _sanitizeTextForPdf(String text) {
    if (text.isEmpty) return text;
    if (text.runes.every((r) => r <= 255)) {
      return text;
    }

    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune <= 255) {
        buffer.writeCharCode(rune);
      } else {
        switch (rune) {
          case 0x23F0: // ⏰
            buffer.write('[Due] ');
          case 0x1F4A1: // 💡
            buffer.write('[Tip] ');
          case 0x1F4CC: // 📌
            buffer.write('[Note] ');
          case 0x26A0: // ⚠️
            buffer.write('[!] ');
          case 0x2705: // ✅
            buffer.write('[x] ');
          case 0x2022: // •
            buffer.write('* ');
          case 0x2013 || 0x2014: // – or —
            buffer.write('-');
          case 0x201C || 0x201D: // “ or ”
            buffer.write('"');
          case 0x2018 || 0x2019: // ‘ or ’
            buffer.write("'");
          default:
            continue;
        }
      }
    }
    return buffer.toString();
  }
}
