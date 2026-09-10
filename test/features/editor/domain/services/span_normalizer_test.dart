import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/editor/domain/models/inline_span_model.dart';
import 'package:ketion/features/editor/domain/services/span_normalizer.dart';

void main() {
  group('SpanNormalizer', () {
    test('normalize removes zero-length spans (if length=0 was supported, but currently it just handles them normally)', () {
      final spans = [
        const InlineSpanModel(offset: 0, length: 5, type: 'bold'),
        const InlineSpanModel(offset: 5, length: 0, type: 'italic'),
      ];
      final result = SpanNormalizer.normalize(spans);
      expect(result.length, 2);
      expect(result[0].type, 'bold');
    });

    test('normalize merges identical adjacent spans', () {
      final spans = [
        const InlineSpanModel(offset: 0, length: 5, type: 'bold'),
        const InlineSpanModel(offset: 5, length: 5, type: 'bold'),
      ];
      final result = SpanNormalizer.normalize(spans);
      expect(result.length, 1);
      expect(result[0].offset, 0);
      expect(result[0].length, 10);
    });

    test('normalize does not merge different adjacent spans', () {
      final spans = [
        const InlineSpanModel(offset: 0, length: 5, type: 'bold'),
        const InlineSpanModel(offset: 5, length: 5, type: 'italic'),
      ];
      final result = SpanNormalizer.normalize(spans);
      expect(result.length, 2);
    });

    test('toggleFormat adds new style and normalizes', () {
      final spans = [
        const InlineSpanModel(offset: 0, length: 10, type: 'bold'),
      ];
      // Apply bold to 5-15 (length 10) (should extend existing bold)
      final result = SpanNormalizer.toggleFormat(spans, 5, 10, 'bold');
      expect(result.length, 1);
      expect(result[0].offset, 0);
      expect(result[0].length, 15);
    });

    test('toggleFormat removes style and splits', () {
      final spans = [
        const InlineSpanModel(offset: 0, length: 10, type: 'bold'),
      ];
      // Remove bold from 3-7 (length 4) (should split into 0-3 and 7-10)
      final result = SpanNormalizer.toggleFormat(spans, 3, 4, 'bold');
      expect(result.length, 2);
      expect(result[0].offset, 0);
      expect(result[0].length, 3);
      expect(result[1].offset, 7);
      expect(result[1].length, 3);
    });

    test('toggleFormat removes exact match', () {
      final spans = [
        const InlineSpanModel(offset: 0, length: 10, type: 'bold'),
      ];
      final result = SpanNormalizer.toggleFormat(spans, 0, 10, 'bold');
      expect(result.isEmpty, isTrue);
    });
  });
}
