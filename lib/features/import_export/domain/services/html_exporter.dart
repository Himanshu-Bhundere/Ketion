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
      'body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; max-width: 800px; margin: 0 auto; padding: 2rem; color: #222; }',
    );
    buffer.writeln('img { max-width: 100%; height: auto; }');
    buffer.writeln(
      '.ketion-toggle { margin: 6px 0; padding-left: 8px; border-left: 2px solid #e0e0e0; }',
    );
    buffer.writeln(
      '.ketion-toggle summary { cursor: pointer; font-weight: 600; margin-bottom: 4px; }',
    );
    buffer.writeln('.checklist-item { list-style-type: none; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<h1>${_escapeHtml(document.title)}</h1>');

    String? currentListType; // 'bullet', 'numbered', 'checklist'
    final openToggleDepths = <int>[];

    void closeListIfNeeded() {
      if (currentListType != null) {
        buffer.writeln('</${currentListType == 'numbered' ? 'ol' : 'ul'}>');
        currentListType = null;
      }
    }

    void closeTogglesToDepth(int targetDepth) {
      while (openToggleDepths.isNotEmpty &&
          openToggleDepths.last >= targetDepth) {
        openToggleDepths.removeLast();
        buffer.writeln('</details>');
      }
    }

    for (int i = 0; i < document.nodes.length; i++) {
      final node = document.nodes[i];
      final depth = node.depth;

      // Close open toggles whose subtree has completed.
      closeTogglesToDepth(depth);

      if (node is DocList) {
        final isToggle = node.listType == 'toggle' ||
            node.listType == 'toggle_expanded';
        if (isToggle) {
          closeListIfNeeded();
          final isExpanded = node.listType == 'toggle_expanded';
          openToggleDepths.add(depth);
          buffer.writeln(
            '<details class="ketion-toggle"${isExpanded ? ' open' : ''} style="margin-left: ${depth * 20}px;">',
          );
          buffer.writeln('<summary>${_spansToHtml(node.spans)}</summary>');
          continue;
        }

        final listTag = node.listType == 'numbered'
            ? 'numbered'
            : (node.listType == 'checklist' ? 'checklist' : 'bullet');
        if (currentListType != listTag) {
          closeListIfNeeded();
          currentListType = listTag;
          buffer.writeln('<${listTag == 'numbered' ? 'ol' : 'ul'}>');
        }

        String prefix = '';
        String itemClass = '';
        if (node.listType == 'checklist') {
          prefix =
              '<input type="checkbox" ${node.checked ? 'checked' : ''} disabled> ';
          itemClass = ' class="checklist-item"';
        }
        final textStyle = (node.listType == 'checklist' && node.checked)
            ? ' style="text-decoration: line-through; color: #888;"'
            : '';
        buffer.writeln(
          '<li$itemClass$textStyle>$prefix${_spansToHtml(node.spans)}</li>',
        );
        continue;
      }

      // Non-list nodes close active lists.
      closeListIfNeeded();

      node.map(
        paragraph: (p) {
          final indentStyle =
              p.depth > 0 ? ' style="margin-left: ${p.depth * 20}px;"' : '';
          buffer.writeln('<p$indentStyle>${_spansToHtml(p.spans)}</p>');
        },
        heading: (h) {
          final level = h.level.clamp(1, 6);
          final indentStyle =
              h.depth > 0 ? ' style="margin-left: ${h.depth * 20}px;"' : '';
          buffer.writeln(
            '<h$level$indentStyle>${_spansToHtml(h.spans)}</h$level>',
          );
        },
        list: (_) {},
        image: (img) {
          final indentStyle =
              img.depth > 0 ? ' style="margin-left: ${img.depth * 20}px;"' : '';
          buffer.writeln('<figure$indentStyle>');
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
          final indentStyle =
              f.depth > 0 ? ' style="margin-left: ${f.depth * 20}px;"' : '';
          buffer.writeln(
            '<p$indentStyle><a href="${_escapeHtml(f.attachmentId)}">${_escapeHtml(f.caption ?? 'File')}</a></p>',
          );
        },
        code: (c) {
          final indentStyle =
              c.depth > 0 ? ' style="margin-left: ${c.depth * 20}px;"' : '';
          buffer.writeln(
            '<pre$indentStyle><code class="${_escapeHtml(c.language)}">${_escapeHtml(c.code)}</code></pre>',
          );
        },
        divider: (d) {
          buffer.writeln('<hr/>');
        },
        callout: (c) {
          final indentStyle =
              c.depth > 0 ? 'margin-left: ${c.depth * 20}px; ' : '';
          buffer.writeln(
            '<div class="callout" style="${indentStyle}border: 1px solid #e0e0e0; background: #f9f9f9; padding: 12px; border-radius: 6px; margin: 8px 0;"><span>${_escapeHtml(c.icon)}</span> ${_spansToHtml(c.spans)}</div>',
          );
        },
        table: (t) {
          final indentStyle =
              t.depth > 0 ? 'margin-left: ${t.depth * 20}px; ' : '';
          buffer.writeln(
            '<table border="1" style="${indentStyle}border-collapse: collapse; width: 100%; margin: 8px 0;">',
          );
          for (final row in t.rows) {
            buffer.writeln('<tr>');
            for (final cell in row) {
              buffer.writeln(
                '<td style="padding: 8px; border: 1px solid #ddd;">${_escapeHtml(cell)}</td>',
              );
            }
            buffer.writeln('</tr>');
          }
          buffer.writeln('</table>');
        },
      );
    }

    closeListIfNeeded();
    closeTogglesToDepth(0);

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
