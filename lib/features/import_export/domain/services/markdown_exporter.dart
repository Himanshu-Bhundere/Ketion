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
          buffer.writeln(_spansToMarkdown(p.spans));
          buffer.writeln();
        },
        heading: (h) {
          final prefix = List.filled(h.level.clamp(1, 6), '#').join('');
          buffer.writeln('$prefix ${_spansToMarkdown(h.spans)}');
          buffer.writeln();
        },
        list: (l) {
          final prefix = l.listType == 'checklist'
              ? '- [${l.checked ? 'x' : ' '}]'
              : '-'; // For now, treat all as bullets, except checklist
          buffer.writeln('$prefix ${_spansToMarkdown(l.spans)}');
        },
        image: (img) {
          buffer.writeln('![${img.caption ?? ''}](${img.attachmentId})');
          buffer.writeln();
        },
        file: (f) {
          buffer.writeln('[${f.caption ?? 'File'}](${f.attachmentId})');
          buffer.writeln();
        },
        code: (c) {
          buffer.writeln('```${c.language}');
          buffer.writeln(c.code);
          buffer.writeln('```');
          buffer.writeln();
        },
        divider: (d) {
          buffer.writeln('---');
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
