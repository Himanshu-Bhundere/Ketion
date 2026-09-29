import 'package:super_editor/super_editor.dart';

class KetionCalloutNode extends TextNode {
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
      icon: icon,
      color: color,
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
      icon: icon,
      color: color,
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
