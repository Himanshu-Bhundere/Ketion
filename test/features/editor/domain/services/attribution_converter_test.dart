import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:ketion/features/editor/domain/services/attribution_converter.dart';

void main() {
  group('AttributionConverter', () {
    test('converts Super Editor AttributedText to Ketion spans', () {
      final text = AttributedText(
        'Hello World',
        AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 4, markerType: SpanMarkerType.end),
            const SpanMarker(attribution: italicsAttribution, offset: 6, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: italicsAttribution, offset: 10, markerType: SpanMarkerType.end),
          ],
        ),
      );

      final spans = AttributionConverter.toKetionSpans(text);
      expect(spans.length, 3);
      
      expect(spans[0]['text'], 'Hello');
      expect(spans[0]['bold'], true);
      expect(spans[0]['italic'], false);

      expect(spans[1]['text'], ' ');
      expect(spans[1]['bold'], false);
      expect(spans[1]['italic'], false);

      expect(spans[2]['text'], 'World');
      expect(spans[2]['bold'], false);
      expect(spans[2]['italic'], true);
    });

    test('converts Ketion spans to Super Editor AttributedText', () {
      final spans = [
        {'text': 'Hello', 'bold': true, 'italic': false, 'underline': false, 'strikethrough': false, 'code': false},
        {'text': ' ', 'bold': false, 'italic': false, 'underline': false, 'strikethrough': false, 'code': false},
        {'text': 'World', 'bold': false, 'italic': true, 'underline': false, 'strikethrough': false, 'code': false},
      ];

      final text = AttributionConverter.fromKetionSpans(spans);
      expect(text.toPlainText(), 'Hello World');
      
      expect(text.getAllAttributionsAt(0).contains(boldAttribution), true);
      expect(text.getAllAttributionsAt(4).contains(boldAttribution), true);
      expect(text.getAllAttributionsAt(5).contains(boldAttribution), false);

      expect(text.getAllAttributionsAt(6).contains(italicsAttribution), true);
      expect(text.getAllAttributionsAt(10).contains(italicsAttribution), true);
    });
  });
}
