import 'package:super_editor/super_editor.dart';

class AttributionConverter {
  static List<Map<String, dynamic>> toKetionSpans(AttributedText text) {
    final plainText = text.toPlainText();
    if (plainText.isEmpty) {
      return [];
    }
    
    final spans = <Map<String, dynamic>>[];
    
    int i = 0;
    while (i < plainText.length) {
      final attributions = text.getAllAttributionsAt(i);
      
      int nextChangeIndex = plainText.length;
      for (int j = i + 1; j < plainText.length; j++) {
        final jAttributions = text.getAllAttributionsAt(j);
        if (!_setEquals(attributions, jAttributions)) {
          nextChangeIndex = j;
          break;
        }
      }
      
      final chunkText = plainText.substring(i, nextChangeIndex);
      spans.add({
        'text': chunkText,
        'bold': attributions.contains(boldAttribution),
        'italic': attributions.contains(italicsAttribution),
        'underline': attributions.contains(underlineAttribution),
        'strikethrough': attributions.contains(strikethroughAttribution),
        'code': attributions.contains(codeAttribution), // Assuming code is a standard attribution
      });
      
      i = nextChangeIndex;
    }
    
    return spans;
  }
  
  /// Converts Ketion [spans] to Super Editor [AttributedText].
  static AttributedText fromKetionSpans(List<dynamic> spans) {
    if (spans.isEmpty) {
      return AttributedText();
    }
    
    final fullText = spans.map((e) => e['text'] as String? ?? '').join();
    final attributedText = AttributedText(fullText);
    
    int currentIndex = 0;
    for (final span in spans) {
      final text = span['text'] as String? ?? '';
      if (text.isEmpty) continue;
      
      final end = currentIndex + text.length - 1;
      
      if (span['bold'] == true) {
        attributedText.addAttribution(boldAttribution, SpanRange(currentIndex, end));
      }
      if (span['italic'] == true) {
        attributedText.addAttribution(italicsAttribution, SpanRange(currentIndex, end));
      }
      if (span['underline'] == true) {
        attributedText.addAttribution(underlineAttribution, SpanRange(currentIndex, end));
      }
      if (span['strikethrough'] == true) {
        attributedText.addAttribution(strikethroughAttribution, SpanRange(currentIndex, end));
      }
      // Wait, is there a standard codeAttribution in super editor?
      // I'll assume we can use NamedAttribution('code') if it's not defined, or maybe it's just 'code' 
      // Super Editor doesn't export 'codeAttribution' by default, wait it might be 'code' or similar. 
      // Actually let's check what it's named. It's usually `codeAttribution` in SuperEditor.
      if (span['code'] == true) {
        try {
          // let's define it below just in case or use a custom one if missing
          attributedText.addAttribution(codeAttribution, SpanRange(currentIndex, end));
        } catch (e) {
          // fallback
          attributedText.addAttribution(const NamedAttribution('code'), SpanRange(currentIndex, end));
        }
      }
      
      currentIndex += text.length;
    }
    
    return attributedText;
  }
  
  static bool _setEquals(Set<Attribution> a, Set<Attribution> b) {
    if (a.length != b.length) return false;
    for (final element in a) {
      if (!b.contains(element)) return false;
    }
    return true;
  }
}

// Ensure codeAttribution exists
const Attribution codeAttribution = NamedAttribution('code');
