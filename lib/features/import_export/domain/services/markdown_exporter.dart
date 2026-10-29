import 'dart:convert';
import 'dart:typed_data';
import 'package:ketion/features/import_export/domain/models/document_model.dart';
import 'package:ketion/features/import_export/domain/services/export_repository.dart';

class MarkdownExporter implements ExportRepository {
  @override
  String get fileExtension => 'md';

  @override
  Future<Uint8List> exportDocument(ExportDocument document) async {
    final buffer = StringBuffer();
    buffer.writeln('# ${document.title}');
    buffer.writeln();

    for (final node in document.nodes) {
      node.map(
        paragraph: (p) {
          final indent = '  ' * p.depth;
          buffer.writeln('$indent${_spansToMarkdown(p.spans)}');
          buffer.writeln();
        },
        heading: (h) {
          final prefix = List.filled(h.level.clamp(1, 6), '#').join('');
          buffer.writeln('$prefix ${_spansToMarkdown(h.spans)}');
          buffer.writeln();
        },
        list: (l) {
          final indent = '  ' * l.depth;
          final String prefix;
          if (l.listType == 'checklist') {
            prefix = '- [${l.checked ? 'x' : ' '}]';
          } else if (l.listType == 'numbered') {
            prefix = '1.';
          } else if (l.listType == 'toggle' || l.listType == 'toggle_expanded') {
            prefix = l.listType == 'toggle_expanded' ? '- ▾' : '- ▸';
          } else {
            prefix = '-';
          }
          buffer.writeln('$indent$prefix ${_spansToMarkdown(l.spans)}');
        },
        image: (img) {
          final indent = '  ' * img.depth;
          buffer.writeln('$indent![${img.caption ?? ''}](${img.attachmentId})');
          buffer.writeln();
        },
        file: (f) {
          final indent = '  ' * f.depth;
          buffer.writeln('$indent[${f.caption ?? 'File'}](${f.attachmentId})');
          buffer.writeln();
        },
        code: (c) {
          final indent = '  ' * c.depth;
          buffer.writeln('$indent```${c.language}');
          for (final line in c.code.split('\n')) {
            buffer.writeln('$indent$line');
          }
          buffer.writeln('$indent```');
          buffer.writeln();
        },
        divider: (d) {
          buffer.writeln('---');
          buffer.writeln();
        },
        callout: (c) {
          final indent = '  ' * c.depth;
          buffer.writeln('$indent> ${c.icon} ${_spansToMarkdown(c.spans)}');
          buffer.writeln();
        },
        table: (t) {
          for (int r = 0; r < t.rows.length; r++) {
            final row = t.rows[r];
            buffer.writeln('| ${row.join(' | ')} |');
            if (r == 0) {
              final cols = t.columnCount > 0 ? t.columnCount : row.length;
              final headerDivider = List.filled(cols, '---');
              buffer.writeln('| ${headerDivider.join(' | ')} |');
            }
          }
          buffer.writeln();
        },
      );
    }

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  String _spansToMarkdown(List<DocumentTextSpan> spans) {
    return spans.map((span) {
      var text = span.text;
      if (span.bold) text = '**$text**';
      if (span.italic) text = '_${text}_';
      if (span.strikethrough) text = '~~$text~~';
      if (span.code) text = '`$text`';
      if (span.pageLink != null) {
        text = '[[${span.text}]]';
      } else if (span.link != null) {
        text = '[$text](${span.link})';
      }
      return text;
    }).join('');
  }
}
