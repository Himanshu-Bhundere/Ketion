import 'dart:convert';
import 'dart:typed_data';
import 'package:ketion/features/import_export/domain/models/document_model.dart';
import 'package:ketion/features/import_export/domain/services/export_repository.dart';

class HtmlExporter implements ExportRepository {
  @override
  String get fileExtension => 'html';

  @override
  Future<Uint8List> exportDocument(ExportDocument document) async {
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="utf-8">');
    buffer.writeln('<title>${_escapeHtml(document.title)}</title>');
    buffer.writeln('<style>');
    buffer.writeln(
      'body { font-family: sans-serif; max-width: 800px; margin: 0 auto; padding: 2rem; }',
    );
    buffer.writeln('img { max-width: 100%; height: auto; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<h1>${_escapeHtml(document.title)}</h1>');

    bool inList = false;

    for (int i = 0; i < document.nodes.length; i++) {
      final node = document.nodes[i];

      // Handle closing list if we were in one and current node is not a list
      if (inList && node is! DocList) {
        buffer.writeln('</ul>');
        inList = false;
      }

      node.map(
        paragraph: (p) {
          buffer.writeln('<p>${_spansToHtml(p.spans)}</p>');
        },
        heading: (h) {
          final level = h.level.clamp(1, 6);
          buffer.writeln('<h$level>${_spansToHtml(h.spans)}</h$level>');
        },
        list: (l) {
          if (!inList) {
            buffer.writeln('<ul>');
            inList = true;
          }
          String prefix = '';
          if (l.listType == 'checklist') {
            prefix =
                '<input type="checkbox" ${l.checked ? 'checked' : ''} disabled> ';
          }
          buffer.writeln('<li>$prefix${_spansToHtml(l.spans)}</li>');
        },
        image: (img) {
          buffer.writeln('<figure>');
          buffer.writeln(
            '<img src="${_escapeHtml(img.attachmentId)}" alt="${_escapeHtml(img.caption ?? '')}">',
          );
          if (img.caption != null && img.caption!.isNotEmpty) {
            buffer.writeln(
              '<figcaption>${_escapeHtml(img.caption!)}</figcaption>',
            );
          }
          buffer.writeln('</figure>');
        },
        file: (f) {
          buffer.writeln(
            '<p><a href="${_escapeHtml(f.attachmentId)}">${_escapeHtml(f.caption ?? 'File')}</a></p>',
          );
        },
      );
    }

    if (inList) {
      buffer.writeln('</ul>');
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  String _spansToHtml(List<DocumentTextSpan> spans) {
    return spans.map((span) {
      var text = _escapeHtml(span.text);
      if (span.bold) text = '<strong>$text</strong>';
      if (span.italic) text = '<em>$text</em>';
      if (span.strikethrough) text = '<del>$text</del>';
      if (span.code) text = '<code>$text</code>';
      if (span.pageLink != null) {
        text =
            '<a href="#">[[${_escapeHtml(span.text)}]]</a>'; // Or link to ketion://
      } else if (span.link != null) {
        text = '<a href="${_escapeHtml(span.link!)}">$text</a>';
      }
      return text;
    }).join('');
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
