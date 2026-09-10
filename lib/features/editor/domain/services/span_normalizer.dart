import 'dart:math';
import '../models/inline_span_model.dart';

class SpanNormalizer {
  /// Normalizes a list of spans by handling overlapping ranges, preventing duplicate types
  /// over the same range, and merging adjacent identical spans.
  static List<InlineSpanModel> normalize(List<InlineSpanModel> spans) {
    if (spans.isEmpty) return [];

    // 1. Group by type and value
    final Map<String, List<InlineSpanModel>> grouped = {};
    for (final span in spans) {
      final key = '${span.type}_${span.value ?? ""}';
      grouped.putIfAbsent(key, () => []).add(span);
    }

    final List<InlineSpanModel> normalized = [];

    // 2. Merge overlapping and adjacent spans of the same type/value
    for (final entry in grouped.entries) {
      final groupSpans = entry.value;
      if (groupSpans.isEmpty) continue;

      // Sort by offset
      groupSpans.sort((a, b) => a.offset.compareTo(b.offset));

      InlineSpanModel current = groupSpans.first;

      for (int i = 1; i < groupSpans.length; i++) {
        final next = groupSpans[i];

        // If next starts before or exactly when current ends, merge them
        if (next.offset <= current.offset + current.length) {
          final newEnd = max(current.offset + current.length, next.offset + next.length);
          current = current.copyWith(length: newEnd - current.offset);
        } else {
          // No overlap, save current and move to next
          normalized.add(current);
          current = next;
        }
      }
      normalized.add(current);
    }

    // 3. Optional: sort all spans by offset
    normalized.sort((a, b) => a.offset.compareTo(b.offset));

    return normalized;
  }

  /// Toggles a format on a given range.
  static List<InlineSpanModel> toggleFormat(
    List<InlineSpanModel> existingSpans,
    int offset,
    int length,
    String type,
    {String? value,}
  ) {
    final List<InlineSpanModel> updatedSpans = List.from(existingSpans);
    
    // Check if the entire range is currently covered by this format
    bool isFullyCovered = false;
    final relevantSpans = existingSpans.where((s) => s.type == type && s.value == value).toList();
    
    for (final span in relevantSpans) {
      if (span.offset <= offset && (span.offset + span.length) >= (offset + length)) {
        isFullyCovered = true;
        break;
      }
    }

    if (isFullyCovered) {
      // We need to split or remove the existing span that covers this range
      final spanToRemove = relevantSpans.firstWhere(
        (s) => s.offset <= offset && (s.offset + s.length) >= (offset + length),
      );
      
      updatedSpans.remove(spanToRemove);
      
      // Add left part if any
      if (spanToRemove.offset < offset) {
        updatedSpans.add(spanToRemove.copyWith(
          length: offset - spanToRemove.offset,
        ),);
      }
      
      // Add right part if any
      if ((spanToRemove.offset + spanToRemove.length) > (offset + length)) {
        updatedSpans.add(spanToRemove.copyWith(
          offset: offset + length,
          length: (spanToRemove.offset + spanToRemove.length) - (offset + length),
        ),);
      }
    } else {
      // Add the new span and let normalization merge it
      updatedSpans.add(InlineSpanModel(
        offset: offset,
        length: length,
        type: type,
        value: value,
      ),);
    }

    return normalize(updatedSpans);
  }
}
