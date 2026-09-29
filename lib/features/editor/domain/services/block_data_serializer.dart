import 'dart:convert';

import 'package:super_editor/super_editor.dart';

import '../models/block_data_models.dart';
import 'attribution_converter.dart';

/// The one authoritative conversion from Super Editor nodes to persisted data.
///
/// Going through [BlockDataModel.toJson] is intentional: its Freezed
/// discriminator is part of the on-disk format and is required by indexing.
class BlockDataSerializer {
  const BlockDataSerializer._();

  static BlockDataModel fromDocumentNode(DocumentNode node) {
    if (node is TaskNode) {
      return BlockDataModel.list(
        spans: _spans(node),
        listType: 'checklist',
        checked: node.isComplete,
      );
    }
    if (node is ListItemNode) {
      return BlockDataModel.list(
        spans: _spans(node),
        listType: node.type == ListItemType.ordered ? 'numbered' : 'bullet',
      );
    }
    if (node is ParagraphNode) {
      return BlockDataModel.text(
        spans: _spans(node),
        headingLevel: _headingLevel(node),
      );
    }
    if (node is TextNode) {
      return BlockDataModel.text(spans: _spans(node));
    }
    if (node is HorizontalRuleNode) {
      return const BlockDataModel.divider();
    }
    return const BlockDataModel.unknown();
  }

  static String encodeDocumentNode(DocumentNode node) =>
      jsonEncode(fromDocumentNode(node).toJson());

  static String blockTypeFor(DocumentNode node) {
    if (node is TaskNode || node is ListItemNode) return 'list';
    if (node is HorizontalRuleNode) return 'divider';
    return 'text';
  }

  static List<TextSpanData> _spans(TextNode node) =>
      AttributionConverter.toKetionSpans(node.text)
          .map((span) => TextSpanData.fromJson(span))
          .toList(growable: false);

  static int _headingLevel(ParagraphNode node) {
    final blockType = node.metadata['blockType'];
    if (blockType == header1Attribution) return 1;
    if (blockType == header2Attribution) return 2;
    if (blockType == header3Attribution) return 3;
    return 0;
  }
}
