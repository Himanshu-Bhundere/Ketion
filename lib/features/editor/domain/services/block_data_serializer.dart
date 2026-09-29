import 'dart:convert';

import 'package:super_editor/super_editor.dart';

import '../models/block_data_models.dart';
import '../models/media_nodes.dart';
import '../../presentation/table/ketion_table_node.dart';
import '../../presentation/widgets/ketion_callout_node.dart';
import 'attribution_converter.dart';

/// The one authoritative conversion from Super Editor nodes to persisted data.
///
/// Going through [BlockDataModel.toJson] is intentional: its Freezed
/// discriminator is part of the on-disk format and is required by indexing.
class BlockDataSerializer {
  const BlockDataSerializer._();

  static BlockDataModel fromDocumentNode(DocumentNode node) {
    if (node is KetionCalloutNode) {
      return BlockDataModel.callout(
        spans: _spans(node),
        icon: node.icon,
        color: node.color,
      );
    }
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
      if (node.metadata['blockType'] == const NamedAttribution('toggle')) {
        return BlockDataModel.list(
          spans: _spans(node),
          listType: 'toggle',
          isExpanded: node.metadata['isExpanded'] as bool? ?? false,
        );
      }
      if (node.metadata['blockType'] == codeAttribution) {
        return BlockDataModel.code(
          code: node.text.toPlainText(),
          language: node.metadata['language'] as String? ?? 'plaintext',
          showLineNumbers: node.metadata['showLineNumbers'] as bool? ?? false,
          wrapLines: node.metadata['wrapLines'] as bool? ?? true,
        );
      }
      return BlockDataModel.text(
        spans: _spans(node),
        headingLevel: _headingLevel(node),
        quote: node.metadata['blockType'] == blockquoteAttribution,
      );
    }
    if (node is TextNode) {
      return BlockDataModel.text(spans: _spans(node));
    }
    if (node is HorizontalRuleNode) {
      return const BlockDataModel.divider();
    }
    if (node is ImageNode) {
      return BlockDataModel.image(attachmentId: node.imageUrl);
    }
    if (node is KetionVideoNode) {
      return BlockDataModel.video(attachmentId: node.attachmentId);
    }
    if (node is KetionAudioNode) {
      return BlockDataModel.audio(attachmentId: node.attachmentId);
    }
    if (node is KetionPdfNode) {
      return BlockDataModel.pdf(attachmentId: node.attachmentId);
    }
    if (node is KetionFileNode) {
      return BlockDataModel.file(attachmentId: node.attachmentId);
    }
    if (node is KetionBookmarkNode) {
      return BlockDataModel.bookmark(url: node.url);
    }
    if (node is KetionTableNode) {
      return BlockDataModel.table(
        columnCount: node.metadata['columnCount'] as int? ?? 0,
        rows: node.rows,
      );
    }
    if (node is KetionPageLinkNode) {
      return BlockDataModel.pageLink(pageId: node.pageId);
    }
    if (node is KetionWebLinkNode) {
      return BlockDataModel.webLink(url: node.url);
    }
    if (node is KetionReminderNode) {
      return BlockDataModel.reminder(
        title: node.title,
        dueAt: node.dueAt,
        timezone: node.timezone,
        recurrenceRule: node.recurrenceRule,
        completed: node.completed,
      );
    }
    return const BlockDataModel.unknown();
  }

  static String encodeDocumentNode(DocumentNode node) =>
      jsonEncode(fromDocumentNode(node).toJson());

  static String blockTypeFor(DocumentNode node) {
    if (node is TaskNode || node is ListItemNode) return 'list';
    if (node is HorizontalRuleNode) return 'divider';
    if (node is ImageNode) return 'image';
    if (node is KetionVideoNode) return 'video';
    if (node is KetionAudioNode) return 'audio';
    if (node is KetionPdfNode) return 'pdf';
    if (node is KetionFileNode) return 'file';
    if (node is KetionBookmarkNode) return 'bookmark';
    if (node is KetionTableNode) return 'table';
    if (node is KetionPageLinkNode) return 'pageLink';
    if (node is KetionWebLinkNode) return 'webLink';
    if (node is KetionReminderNode) return 'reminder';
    if (node is KetionCalloutNode) return 'callout';
    if (node is ParagraphNode) {
      if (node.metadata['blockType'] == codeAttribution) return 'code';
      if (node.metadata['blockType'] == const NamedAttribution('toggle')) return 'list';
    }
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
