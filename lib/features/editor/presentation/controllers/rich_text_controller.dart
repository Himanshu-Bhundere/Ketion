import 'package:flutter/material.dart';
import '../../domain/models/inline_span_model.dart';
import '../../domain/services/span_normalizer.dart';

class RichTextController extends TextEditingController {
  List<InlineSpanModel> _spans = [];

  RichTextController({super.text, List<InlineSpanModel>? spans}) {
    if (spans != null) {
      _spans = List.from(spans);
    }
  }

  List<InlineSpanModel> get spans => _spans;

  void updateSpans(List<InlineSpanModel> newSpans) {
    _spans = SpanNormalizer.normalize(newSpans);
    notifyListeners();
  }

  void toggleFormat(String type, {String? value}) {
    if (selection.isCollapsed) return; // Cannot toggle format without selection for now
    
    _spans = SpanNormalizer.toggleFormat(
      _spans,
      selection.start,
      selection.end - selection.start,
      type,
      value: value,
    );
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_spans.isEmpty || text.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    final List<TextSpan> children = [];
    int currentIndex = 0;

    // Create segments by breaking the text at every span start and end boundary
    final Set<int> boundaries = {0, text.length};
    for (final span in _spans) {
      boundaries.add(span.offset);
      boundaries.add(span.offset + span.length);
    }

    final sortedBoundaries = boundaries.where((b) => b <= text.length).toList()..sort();

    for (int i = 0; i < sortedBoundaries.length - 1; i++) {
      final start = sortedBoundaries[i];
      final end = sortedBoundaries[i + 1];
      if (start == end) continue;

      final segmentText = text.substring(start, end);
      
      // Find all spans that cover this segment
      final activeSpans = _spans.where((s) => s.offset <= start && (s.offset + s.length) >= end).toList();

      TextStyle segmentStyle = style ?? const TextStyle();
      
      for (final span in activeSpans) {
        segmentStyle = _applySpanStyle(segmentStyle, span, context);
      }

      children.add(TextSpan(text: segmentText, style: segmentStyle));
    }

    return TextSpan(style: style, children: children);
  }

  TextStyle _applySpanStyle(TextStyle baseStyle, InlineSpanModel span, BuildContext context) {
    switch (span.type) {
      case 'bold':
        return baseStyle.copyWith(fontWeight: FontWeight.bold);
      case 'italic':
        return baseStyle.copyWith(fontStyle: FontStyle.italic);
      case 'strikethrough':
        return baseStyle.copyWith(
          decoration: TextDecoration.combine([
            if (baseStyle.decoration != null) baseStyle.decoration!,
            TextDecoration.lineThrough,
          ]),
        );
      case 'underline':
        return baseStyle.copyWith(
          decoration: TextDecoration.combine([
            if (baseStyle.decoration != null) baseStyle.decoration!,
            TextDecoration.underline,
          ]),
        );
      case 'code':
        return baseStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        );
      case 'color':
        if (span.value != null) {
          try {
            final color = Color(int.parse(span.value!.replaceFirst('#', '0xFF')));
            return baseStyle.copyWith(color: color);
          } catch (_) {}
        }
        return baseStyle;
      default:
        return baseStyle;
    }
  }

  @override
  set value(TextEditingValue newValue) {
    // Handle text length changes: shift spans or remove them if text is deleted
    final oldLength = text.length;
    final newLength = newValue.text.length;
    
    if (oldLength != newLength) {
      final delta = newLength - oldLength;
      
      // Determine roughly where the change happened based on selection changes
      // In a robust implementation, we would need the actual diff to perfectly shift spans.
      // For now, if typing at end, spans remain untouched.
      // If typing in middle, shift spans after cursor.
      
      final cursor = selection.baseOffset;
      if (cursor >= 0) {
        final List<InlineSpanModel> adjustedSpans = [];
        for (final span in _spans) {
          if (span.offset >= cursor) {
             // Span is after cursor, shift it
             final newOffset = span.offset + delta;
             if (newOffset >= 0 && newOffset < newLength) {
               adjustedSpans.add(span.copyWith(offset: newOffset));
             }
          } else if (span.offset + span.length > cursor) {
             // Span covers cursor, extend or shrink it
             final newLen = span.length + delta;
             if (newLen > 0) {
                adjustedSpans.add(span.copyWith(length: newLen));
             }
          } else {
             // Span is before cursor, keep as is
             adjustedSpans.add(span);
          }
        }
        _spans = SpanNormalizer.normalize(adjustedSpans);
      }
    }
    super.value = newValue;
  }
}
