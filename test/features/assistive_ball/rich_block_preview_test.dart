import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/assistive_ball/presentation/widgets/rich_block_preview.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';

void main() {
  Widget buildTestable(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  group('RichBlockPreview Tests', () {
    final now = DateTime.now();

    testWidgets('renders heading text block', (tester) async {
      final block = Block(
        id: 'h1',
        pageId: 'page1',
        type: 'text',
        position: 1000.0,
        data: jsonEncode({
          'headingLevel': 1,
          'spans': [
            {'text': 'Main Heading', 'bold': true},
          ],
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildTestable(RichBlockPreview(block: block)));
      expect(find.text('Main Heading'), findsOneWidget);
    });

    testWidgets('renders quote text block', (tester) async {
      final block = Block(
        id: 'quote1',
        pageId: 'page1',
        type: 'text',
        position: 1000.0,
        data: jsonEncode({
          'quote': true,
          'spans': [
            {'text': 'Wise quote', 'italic': true},
          ],
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildTestable(RichBlockPreview(block: block)));
      expect(find.text('Wise quote'), findsOneWidget);
    });

    testWidgets('renders numbered list with custom ordinal', (tester) async {
      final block = Block(
        id: 'list1',
        pageId: 'page1',
        type: 'list',
        position: 1000.0,
        data: jsonEncode({
          'listType': 'numbered',
          'spans': [
            {'text': 'Third item'},
          ],
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        buildTestable(RichBlockPreview(block: block, listOrdinal: 3)),
      );
      expect(find.text('3.'), findsOneWidget);
      expect(find.text('Third item'), findsOneWidget);
    });

    testWidgets('renders checklist item', (tester) async {
      final block = Block(
        id: 'chk1',
        pageId: 'page1',
        type: 'list',
        position: 1000.0,
        data: jsonEncode({
          'listType': 'checklist',
          'checked': true,
          'spans': [
            {'text': 'Done item'},
          ],
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildTestable(RichBlockPreview(block: block)));
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(find.text('Done item'), findsOneWidget);
    });

    testWidgets('renders callout block', (tester) async {
      final block = Block(
        id: 'callout1',
        pageId: 'page1',
        type: 'callout',
        position: 1000.0,
        data: jsonEncode({
          'icon': '⚠️',
          'color': 'yellow',
          'spans': [
            {'text': 'Warning note'},
          ],
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildTestable(RichBlockPreview(block: block)));
      expect(find.text('⚠️'), findsOneWidget);
      expect(find.text('Warning note'), findsOneWidget);
    });

    testWidgets('renders code block', (tester) async {
      final block = Block(
        id: 'code1',
        pageId: 'page1',
        type: 'code',
        position: 1000.0,
        data: jsonEncode({
          'code': 'final x = 42;',
          'language': 'dart',
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildTestable(RichBlockPreview(block: block)));
      expect(find.text('DART'), findsOneWidget);
      expect(find.text('final x = 42;'), findsOneWidget);
    });

    testWidgets('renders divider block', (tester) async {
      final block = Block(
        id: 'div1',
        pageId: 'page1',
        type: 'divider',
        position: 1000.0,
        data: '{}',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildTestable(RichBlockPreview(block: block)));
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders table block', (tester) async {
      final block = Block(
        id: 'tbl1',
        pageId: 'page1',
        type: 'table',
        position: 1000.0,
        data: jsonEncode({
          'rows': [
            {
              'cells': [
                {
                  'spans': [
                    {'text': 'Header 1'},
                  ],
                },
                {
                  'spans': [
                    {'text': 'Header 2'},
                  ],
                },
              ],
            },
            {
              'cells': [
                {
                  'spans': [
                    {'text': 'Row 1 Col 1'},
                  ],
                },
                {
                  'spans': [
                    {'text': 'Row 1 Col 2'},
                  ],
                },
              ],
            },
          ],
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildTestable(RichBlockPreview(block: block)));
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('Header 1'), findsOneWidget);
      expect(find.text('Row 1 Col 2'), findsOneWidget);
    });

    testWidgets('renders bookmark block', (tester) async {
      final block = Block(
        id: 'bm1',
        pageId: 'page1',
        type: 'bookmark',
        position: 1000.0,
        data: jsonEncode({
          'title': 'Google',
          'url': 'https://google.com',
          'description': 'Search engine',
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildTestable(RichBlockPreview(block: block)));
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Search engine'), findsOneWidget);
    });

    testWidgets('renders reminder and webLink blocks', (tester) async {
      final reminderBlock = Block(
        id: 'rem1',
        pageId: 'page1',
        type: 'reminder',
        position: 1000.0,
        data: jsonEncode({
          'title': 'Submit invoice',
          'dueAt': 'Tomorrow 10:00',
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        buildTestable(RichBlockPreview(block: reminderBlock)),
      );
      expect(find.text('Submit invoice'), findsOneWidget);
      expect(find.text('Tomorrow 10:00'), findsOneWidget);

      final linkBlock = Block(
        id: 'lnk1',
        pageId: 'page1',
        type: 'webLink',
        position: 2000.0,
        data: jsonEncode({
          'url': 'https://flutter.dev',
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        buildTestable(RichBlockPreview(block: linkBlock)),
      );
      expect(find.text('https://flutter.dev'), findsOneWidget);
    });

    testWidgets('renders toggle block with disclosure arrow and indentation',
        (tester) async {
      bool toggleTapped = false;
      final toggleBlock = Block(
        id: 'tog1',
        pageId: 'page1',
        type: 'toggle',
        position: 1000.0,
        data: jsonEncode({
          'spans': [
            {'text': 'Expandable section'},
          ],
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        buildTestable(
          RichBlockPreview(
            block: toggleBlock,
            depth: 1,
            isExpanded: true,
            hasChildren: true,
            onToggle: () => toggleTapped = true,
          ),
        ),
      );

      expect(find.text('Expandable section'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      expect(toggleTapped, isTrue);

      // Verify indentation padding is applied when depth > 0
      final paddingFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.only(left: 20.0),
      );
      expect(paddingFinder, findsWidgets);
    });

    testWidgets('renders list item with toggle listType', (tester) async {
      final toggleListBlock = Block(
        id: 'togList1',
        pageId: 'page1',
        type: 'list',
        position: 1000.0,
        data: jsonEncode({
          'listType': 'toggle',
          'spans': [
            {'text': 'Nested Toggle Item'},
          ],
        }),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        buildTestable(
          RichBlockPreview(
            block: toggleListBlock,
            depth: 2,
            isExpanded: false,
          ),
        ),
      );

      expect(find.text('Nested Toggle Item'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_right), findsOneWidget);
    });
  });
}
