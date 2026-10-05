import 'package:super_editor/super_editor.dart';

class KetionCalloutNode extends ParagraphNode {
  KetionCalloutNode({
    required super.id,
    required super.text,
    super.metadata,
    this.icon = '💡',
    this.color = 'grey',
  });

  final String icon;
  final String color;

  @override
  bool hasEquivalentContent(DocumentNode other) {
    if (other is! KetionCalloutNode) {
      return false;
    }
    return icon == other.icon && color == other.color && text == other.text;
  }

  @override
  KetionCalloutNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return KetionCalloutNode(
      id: id,
      text: text.copyText(0),
      metadata: newMetadata,
      icon: (newMetadata['icon'] as String?) ?? icon,
      color: (newMetadata['color'] as String?) ?? color,
    );
  }

  @override
  KetionCalloutNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    return KetionCalloutNode(
      id: id,
      text: text.copyText(0),
      metadata: {
        ...metadata,
        ...newProperties,
      },
      icon: (newProperties['icon'] as String?) ?? icon,
      color: (newProperties['color'] as String?) ?? color,
    );
  }

  @override
  KetionCalloutNode copyParagraphWith({
    String? id,
    AttributedText? text,
    int? indent,
    Map<String, dynamic>? metadata,
  }) {
    final mergedMetadata = metadata ?? this.metadata;
    return KetionCalloutNode(
      id: id ?? this.id,
      text: text ?? this.text,
      metadata: mergedMetadata,
      icon: (mergedMetadata['icon'] as String?) ?? icon,
      color: (mergedMetadata['color'] as String?) ?? color,
    );
  }

  @override
  KetionCalloutNode copyTextNodeWith({
    String? id,
    AttributedText? text,
    Map<String, dynamic>? metadata,
  }) {
    return copyParagraphWith(
      id: id,
      text: text,
      metadata: metadata,
    );
  }

  @override
  KetionCalloutNode copy() {
    return KetionCalloutNode(
      id: id,
      text: text.copyText(0),
      metadata: Map.from(metadata),
      icon: icon,
      color: color,
    );
  }

  KetionCalloutNode copyWith({
    String? id,
    AttributedText? text,
    Map<String, dynamic>? metadata,
    String? icon,
    String? color,
  }) {
    return KetionCalloutNode(
      id: id ?? this.id,
      text: text ?? this.text.copyText(0),
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  String copyContent(dynamic selection) {
    if (selection is! NodeSelection) {
      return text.toPlainText();
    }
    return super.copyContent(selection);
  }
}
