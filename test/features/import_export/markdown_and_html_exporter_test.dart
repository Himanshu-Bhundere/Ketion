import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/import_export/domain/models/document_model.dart';
import 'package:ketion/features/import_export/domain/services/html_exporter.dart';
import 'package:ketion/features/import_export/domain/services/markdown_exporter.dart';

void main() {
  group('MarkdownExporter', () {
    late MarkdownExporter exporter;

    setUp(() {
      exporter = MarkdownExporter();
    });

    test('exports page title and text formatting spans', () async {
      const doc = ExportDocument(
        title: 'Project Notes',
        nodes: [
          DocumentNode.paragraph(
            spans: [
              DocumentTextSpan(text: 'Normal '),
              DocumentTextSpan(text: 'bold', bold: true),
              DocumentTextSpan(text: ' and '),
              DocumentTextSpan(text: 'italic', italic: true),
              DocumentTextSpan(text: ' and '),
              DocumentTextSpan(text: 'strike', strikethrough: true),
              DocumentTextSpan(text: ' and '),
              DocumentTextSpan(text: 'code', code: true),
              DocumentTextSpan(
                text: 'link',
                link: 'https://example.com',
              ),
              DocumentTextSpan(text: 'wiki', pageLink: 'TargetPage'),
            ],
          ),
        ],
      );

      final bytes = await exporter.exportDocument(doc);
      final md = utf8.decode(bytes);

      expect(md, contains('# Project Notes'));
      expect(
        md,
        contains(
          'Normal **bold** and _italic_ and ~~strike~~ and `code`[link](https://example.com)[[wiki]]',
        ),
      );
    });

    test('exports hierarchical lists with proper depth indentation', () async {
      const doc = ExportDocument(
        title: 'Hierarchical Lists',
        nodes: [
          DocumentNode.list(
            listType: 'bullet',
            checked: false,
            depth: 0,
            spans: [DocumentTextSpan(text: 'Top bullet')],
          ),
          DocumentNode.list(
            listType: 'bullet',
            checked: false,
            depth: 1,
            spans: [DocumentTextSpan(text: 'Nested bullet level 1')],
          ),
          DocumentNode.list(
            listType: 'numbered',
            checked: false,
            depth: 1,
            spans: [DocumentTextSpan(text: 'Nested numbered 1')],
          ),
          DocumentNode.list(
            listType: 'checklist',
            checked: false,
            depth: 2,
            spans: [DocumentTextSpan(text: 'Pending task')],
          ),
          DocumentNode.list(
            listType: 'checklist',
            checked: true,
            depth: 2,
            spans: [DocumentTextSpan(text: 'Completed task')],
          ),
          DocumentNode.list(
            listType: 'toggle_expanded',
            checked: false,
            depth: 0,
            spans: [DocumentTextSpan(text: 'Expanded Toggle')],
          ),
          DocumentNode.list(
            listType: 'toggle',
            checked: false,
            depth: 0,
            spans: [DocumentTextSpan(text: 'Collapsed Toggle')],
          ),
        ],
      );

      final bytes = await exporter.exportDocument(doc);
      final md = utf8.decode(bytes);

      expect(md, contains('- Top bullet'));
      expect(md, contains('  - Nested bullet level 1'));
      expect(md, contains('  1. Nested numbered 1'));
      expect(md, contains('    - [ ] Pending task'));
      expect(md, contains('    - [x] Completed task'));
      expect(md, contains('- ▾ Expanded Toggle'));
      expect(md, contains('- ▸ Collapsed Toggle'));
    });

    test('exports code blocks, callouts, and tables', () async {
      const doc = ExportDocument(
        title: 'Blocks Spec',
        nodes: [
          DocumentNode.code(
            language: 'dart',
            code: 'void main() {\n  print("hi");\n}',
            depth: 1,
          ),
          DocumentNode.callout(
            icon: '💡',
            color: 'blue',
            depth: 0,
            spans: [DocumentTextSpan(text: 'Important note')],
          ),
          DocumentNode.table(
            columnCount: 2,
            rows: [
              ['Header 1', 'Header 2'],
              ['Value A', 'Value B'],
            ],
          ),
        ],
      );

      final bytes = await exporter.exportDocument(doc);
      final md = utf8.decode(bytes);

      expect(md, contains('  ```dart'));
      expect(md, contains('  void main() {'));
      expect(md, contains('> 💡 Important note'));
      expect(md, contains('| Header 1 | Header 2 |'));
      expect(md, contains('| --- | --- |'));
      expect(md, contains('| Value A | Value B |'));
    });
  });

  group('HtmlExporter', () {
    late HtmlExporter exporter;

    setUp(() {
      exporter = HtmlExporter();
    });

    test('exports collapsible details toggles with nested content', () async {
      const doc = ExportDocument(
        title: 'HTML Toggles',
        nodes: [
          DocumentNode.list(
            listType: 'toggle_expanded',
            checked: false,
            depth: 0,
            spans: [DocumentTextSpan(text: 'Open Section')],
          ),
          DocumentNode.paragraph(
            depth: 1,
            spans: [DocumentTextSpan(text: 'Child under open toggle')],
          ),
          DocumentNode.list(
            listType: 'toggle',
            checked: false,
            depth: 0,
            spans: [DocumentTextSpan(text: 'Closed Section')],
          ),
          DocumentNode.paragraph(
            depth: 1,
            spans: [DocumentTextSpan(text: 'Child under closed toggle')],
          ),
          DocumentNode.paragraph(
            depth: 0,
            spans: [DocumentTextSpan(text: 'Root paragraph')],
          ),
        ],
      );

      final bytes = await exporter.exportDocument(doc);
      final html = utf8.decode(bytes);

      expect(
        html,
        contains(
          '<details class="ketion-toggle" open style="margin-left: 0px;">',
        ),
      );
      expect(html, contains('<summary>Open Section</summary>'));
      expect(
        html,
        contains(
          '<p style="margin-left: 20px;">Child under open toggle</p>',
        ),
      );
      expect(
        html,
        contains(
          '<details class="ketion-toggle" style="margin-left: 0px;">',
        ),
      );
      expect(html, contains('<summary>Closed Section</summary>'));
      expect(
        html,
        contains(
          '<p style="margin-left: 20px;">Child under closed toggle</p>',
        ),
      );
      expect(html, contains('<p>Root paragraph</p>'));
      // Verify all <details> tags are closed properly
      final openCount = '<details'.allMatches(html).length;
      final closeCount = '</details>'.allMatches(html).length;
      expect(openCount, equals(closeCount));
      expect(openCount, equals(2));
    });

    test('differentiates ol and ul and formats checklist items', () async {
      const doc = ExportDocument(
        title: 'Lists Spec',
        nodes: [
          DocumentNode.list(
            listType: 'numbered',
            checked: false,
            depth: 0,
            spans: [DocumentTextSpan(text: 'Step 1')],
          ),
          DocumentNode.list(
            listType: 'numbered',
            checked: false,
            depth: 0,
            spans: [DocumentTextSpan(text: 'Step 2')],
          ),
          DocumentNode.list(
            listType: 'checklist',
            checked: false,
            depth: 0,
            spans: [DocumentTextSpan(text: 'Incomplete')],
          ),
          DocumentNode.list(
            listType: 'checklist',
            checked: true,
            depth: 0,
            spans: [DocumentTextSpan(text: 'Done')],
          ),
          DocumentNode.list(
            listType: 'bullet',
            checked: false,
            depth: 0,
            spans: [DocumentTextSpan(text: 'Simple bullet')],
          ),
        ],
      );

      final bytes = await exporter.exportDocument(doc);
      final html = utf8.decode(bytes);

      expect(html, contains('<ol>'));
      expect(html, contains('<li>Step 1</li>'));
      expect(html, contains('<li>Step 2</li>'));
      expect(html, contains('</ol>'));
      expect(
        html,
        contains(
          '<li class="checklist-item"><input type="checkbox"  disabled> Incomplete</li>',
        ),
      );
      expect(
        html,
        contains(
          '<li class="checklist-item" style="text-decoration: line-through; color: #888;"><input type="checkbox" checked disabled> Done</li>',
        ),
      );
      expect(html, contains('<li>Simple bullet</li>'));
    });
  });
}
