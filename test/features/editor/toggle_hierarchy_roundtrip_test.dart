import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/domain/services/block_tree_service.dart';
import 'package:ketion/features/import_export/domain/services/html_exporter.dart';
import 'package:ketion/features/import_export/domain/services/markdown_exporter.dart';
import 'package:ketion/features/import_export/domain/services/pdf_exporter.dart';
import 'package:ketion/features/import_export/domain/usecases/export_usecase.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';

void main() {
  group('ToggleHierarchyRoundtripTest', () {
    late ExportUseCase exportUseCase;
    final now = DateTime(2026, 10, 29, 10, 0);

    setUp(() {
      exportUseCase = ExportUseCase([
        PdfExporter(),
        MarkdownExporter(),
        HtmlExporter(),
      ]);
    });

    final testPage = Page(
      id: 'page-roundtrip-1',
      title: 'Sprint Planning Notes',
      icon: '📝',
      createdAt: now,
      updatedAt: now,
    );

    test(
      'full roundtrip: tree filtering, cycle protection, and export to PDF, HTML, and Markdown',
      () async {
        final blocks = <Block>[
          Block(
            id: 't-root',
            pageId: testPage.id,
            type: 'list',
            position: 1.0,
            data: jsonEncode({
              'runtimeType': 'list',
              'listType': 'toggle',
              'isExpanded': true,
              'spans': [
                {'text': 'Release Deliverables'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
          Block(
            id: 'child-task-1',
            pageId: testPage.id,
            parentBlockId: 't-root',
            type: 'list',
            position: 2.0,
            data: jsonEncode({
              'runtimeType': 'list',
              'listType': 'checklist',
              'checked': true,
              'spans': [
                {'text': 'Preserve placement metadata across slash commands'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
          Block(
            id: 'child-task-2',
            pageId: testPage.id,
            parentBlockId: 't-root',
            type: 'list',
            position: 3.0,
            data: jsonEncode({
              'runtimeType': 'list',
              'listType': 'checklist',
              'checked': false,
              'spans': [
                {'text': 'Verify interactive toggle export in HTML and Markdown'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
          Block(
            id: 'child-nested-toggle',
            pageId: testPage.id,
            parentBlockId: 't-root',
            type: 'list',
            position: 4.0,
            data: jsonEncode({
              'runtimeType': 'list',
              'listType': 'toggle',
              'isExpanded': true,
              'spans': [
                {'text': 'Sub-toggle: Performance Criteria'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
          Block(
            id: 'child-leaf-para',
            pageId: testPage.id,
            parentBlockId: 'child-nested-toggle',
            type: 'text',
            position: 5.0,
            data: jsonEncode({
              'runtimeType': 'text',
              'headingLevel': 0,
              'spans': [
                {'text': 'Subtree filtering completes in < 5ms.'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
          Block(
            id: 'root-para-after',
            pageId: testPage.id,
            type: 'text',
            position: 6.0,
            data: jsonEncode({
              'runtimeType': 'text',
              'headingLevel': 0,
              'spans': [
                {'text': 'Outside toggle subtree.'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
        ];

        // 1. Verify visible tree calculation with BlockTreeService
        final visibleItems = BlockTreeService.buildVisibleTree(blocks);
        expect(visibleItems.length, equals(6));
        expect(visibleItems[0].depth, equals(0)); // t-root
        expect(visibleItems[1].depth, equals(1)); // child-task-1
        expect(visibleItems[2].depth, equals(1)); // child-task-2
        expect(visibleItems[3].depth, equals(1)); // child-nested-toggle
        expect(visibleItems[4].depth, equals(2)); // child-leaf-para
        expect(visibleItems[5].depth, equals(0)); // root-para-after

        // 2. Export to PDF and verify signature
        final pdfBytes = await exportUseCase.exportToBytes(
          testPage,
          blocks,
          'pdf',
        );
        expect(pdfBytes, isNotEmpty);
        expect(
          utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true),
          startsWith('%PDF'),
        );

        // 3. Export to HTML and verify interactive details structure
        final htmlBytes = await exportUseCase.exportToBytes(
          testPage,
          blocks,
          'html',
        );
        final html = utf8.decode(htmlBytes);
        expect(html, contains('<details class="ketion-toggle" open'));
        expect(html, contains('<summary>Release Deliverables</summary>'));
        expect(html, contains('<summary>Sub-toggle: Performance Criteria</summary>'));
        expect(html, contains('Subtree filtering completes in &lt; 5ms.'));
        expect(html, contains('<input type="checkbox" checked disabled>'));
        expect(html, contains('<input type="checkbox"  disabled>'));
        expect(html, contains('<p>Outside toggle subtree.</p>'));

        // 4. Export to Markdown and verify indentation hierarchy
        final mdBytes = await exportUseCase.exportToBytes(
          testPage,
          blocks,
          'md',
        );
        final md = utf8.decode(mdBytes);
        expect(md, contains('# Sprint Planning Notes'));
        expect(md, contains('- ▾ Release Deliverables'));
        expect(
          md,
          contains('  - [x] Preserve placement metadata across slash commands'),
        );
        expect(
          md,
          contains('  - [ ] Verify interactive toggle export in HTML and Markdown'),
        );
        expect(md, contains('  - ▾ Sub-toggle: Performance Criteria'));
        expect(md, contains('    Subtree filtering completes in < 5ms.'));
        expect(md, contains('Outside toggle subtree.'));
      },
    );

    test('collapsed toggle hides descendant subtree in export', () async {
      final blocks = <Block>[
        Block(
          id: 't-collapsed',
          pageId: testPage.id,
          type: 'list',
          position: 1.0,
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'toggle',
            'isExpanded': false,
            'spans': [
              {'text': 'Collapsed Header'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        Block(
          id: 't-hidden-child',
          pageId: testPage.id,
          parentBlockId: 't-collapsed',
          type: 'text',
          position: 2.0,
          data: jsonEncode({
            'runtimeType': 'text',
            'headingLevel': 0,
            'spans': [
              {'text': 'Should not appear in visible tree or export'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final visibleItems = BlockTreeService.buildVisibleTree(blocks);
      expect(visibleItems.length, equals(1));
      expect(visibleItems.first.block.id, equals('t-collapsed'));

      final mdBytes = await exportUseCase.exportToBytes(testPage, blocks, 'md');
      final md = utf8.decode(mdBytes);
      expect(md, contains('- ▸ Collapsed Header'));
      expect(md, isNot(contains('Should not appear')));
    });

    test('resilient against cyclic parent references', () async {
      final cyclicBlocks = <Block>[
        Block(
          id: 'node-a',
          pageId: testPage.id,
          parentBlockId: 'node-b',
          type: 'text',
          position: 1.0,
          data: jsonEncode({
            'runtimeType': 'text',
            'headingLevel': 0,
            'spans': [
              {'text': 'Node A'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        Block(
          id: 'node-b',
          pageId: testPage.id,
          parentBlockId: 'node-a',
          type: 'text',
          position: 2.0,
          data: jsonEncode({
            'runtimeType': 'text',
            'headingLevel': 0,
            'spans': [
              {'text': 'Node B'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Should complete cleanly without infinite recursion or stack overflow
      final visible = BlockTreeService.buildVisibleTree(cyclicBlocks);
      expect(visible, isNotEmpty);

      final mdBytes = await exportUseCase.exportToBytes(
        testPage,
        cyclicBlocks,
        'md',
      );
      expect(mdBytes, isNotEmpty);
    });
  });
}
