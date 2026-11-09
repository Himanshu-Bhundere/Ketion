import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../blocks/domain/entities/block.dart';
import '../../../editor/domain/models/block_data_models.dart';
import '../../../editor/presentation/widgets/blocks/audio_block_widget.dart';
import '../../../editor/presentation/widgets/blocks/file_block_widget.dart';
import '../../../editor/presentation/widgets/blocks/image_block_widget.dart';
import '../../../editor/presentation/widgets/blocks/pdf_block_widget.dart';
import '../../../editor/presentation/widgets/blocks/video_block_widget.dart';

class RichBlockPreview extends StatelessWidget {
  final Block block;
  final int listOrdinal;

  const RichBlockPreview({
    super.key,
    required this.block,
    this.listOrdinal = 1,
  });

  Map<String, dynamic> _decode() {
    try {
      final decoded = jsonDecode(block.data);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return {};
    } catch (_) {
      return {};
    }
  }

  List<TextSpanData> _readSpans(Map<String, dynamic> data) {
    final raw = data['spans'];

    if (raw is! List) {
      final text = data['text'];
      if (text is String && text.isNotEmpty) {
        return [TextSpanData(text: text)];
      }
      return [];
    }

    return raw.map((item) {
      return TextSpanData.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  List<InlineSpan> _buildSpans(
    List<TextSpanData> spans,
    TextStyle baseStyle,
  ) {
    return spans.map((span) {
      final decorations = <TextDecoration>[
        if (span.underline) TextDecoration.underline,
        if (span.strikethrough) TextDecoration.lineThrough,
      ];

      final TextDecoration decoration;
      if (decorations.isEmpty) {
        decoration = TextDecoration.none;
      } else if (decorations.length == 1) {
        decoration = decorations.first;
      } else {
        decoration = TextDecoration.combine(decorations);
      }

      return TextSpan(
        text: span.text,
        style: baseStyle.copyWith(
          fontWeight: span.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: span.italic ? FontStyle.italic : FontStyle.normal,
          decoration: decoration,
          fontFamily: span.code ? 'monospace' : null,
          backgroundColor:
              span.code ? Colors.grey.withValues(alpha: 0.15) : null,
        ),
      );
    }).toList();
  }

  Widget _richText(
    BuildContext context,
    List<TextSpanData> spans, {
    TextStyle? style,
  }) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium!;

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: _buildSpans(spans, baseStyle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _decode();
    final theme = Theme.of(context);
    final spans = _readSpans(data);

    switch (block.type) {
      case 'text':
        return _buildText(context, data, spans);

      case 'list':
        return _buildList(context, data, spans);

      case 'callout':
        return _buildCallout(context, data, spans);

      case 'code':
        return _buildCode(context, data);

      case 'divider':
        return const Divider(height: 24);

      case 'table':
        return _buildTable(context, data);

      case 'image':
        return ImageBlockWidget(
          block: block,
          onUpdate: (_) {},
        );

      case 'video':
        return VideoBlockWidget(
          block: block,
          onUpdate: (_) {},
        );

      case 'audio':
        return AudioBlockWidget(
          block: block,
          onUpdate: (_) {},
        );

      case 'pdf':
        return PdfBlockWidget(
          block: block,
          onUpdate: (_) {},
        );

      case 'file':
        return FileBlockWidget(
          block: block,
          onUpdate: (_) {},
        );

      case 'bookmark':
        return _buildBookmark(context, data);

      case 'webLink':
        return _buildLink(context, data);

      case 'pageLink':
        return _buildPageLink(context, data);

      case 'reminder':
        return _buildReminder(context, data);

      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            spans.map((s) => s.text).join(),
            style: theme.textTheme.bodyMedium,
          ),
        );
    }
  }

  Widget _buildText(
    BuildContext context,
    Map<String, dynamic> data,
    List<TextSpanData> spans,
  ) {
    final theme = Theme.of(context);
    final heading = data['headingLevel'] as int? ?? 0;
    final isQuote = data['quote'] as bool? ?? false;

    TextStyle style;

    switch (heading) {
      case 1:
        style = theme.textTheme.headlineSmall!;
        break;
      case 2:
        style = theme.textTheme.titleLarge!;
        break;
      case 3:
        style = theme.textTheme.titleMedium!;
        break;
      default:
        style = theme.textTheme.bodyMedium!;
    }

    if (isQuote) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        child: _richText(
          context,
          spans,
          style: style.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _richText(context, spans, style: style),
    );
  }

  Widget _buildList(
    BuildContext context,
    Map<String, dynamic> data,
    List<TextSpanData> spans,
  ) {
    final type = data['listType'] as String? ?? 'bullet';
    final checked = data['checked'] as bool? ?? false;

    Widget marker;

    switch (type) {
      case 'numbered':
        marker = SizedBox(
          width: 24,
          child: Text('$listOrdinal.'),
        );
        break;

      case 'checklist':
        marker = Icon(
          checked ? Icons.check_box : Icons.check_box_outline_blank,
          size: 18,
          color: checked
              ? Colors.green
              : Theme.of(context).colorScheme.onSurfaceVariant,
        );
        break;

      default:
        marker = const SizedBox(
          width: 24,
          child: Center(
            child: Icon(Icons.circle, size: 7),
          ),
        );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          marker,
          const SizedBox(width: 6),
          Expanded(
            child: _richText(context, spans),
          ),
        ],
      ),
    );
  }

  Widget _buildCallout(
    BuildContext context,
    Map<String, dynamic> data,
    List<TextSpanData> spans,
  ) {
    final icon = data['icon'] as String? ?? '💡';
    final colorName = data['color'] as String? ?? 'grey';

    final colors = <String, Color>{
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.amber,
      'red': Colors.red,
      'grey': Colors.grey,
    };

    final color = colors[colorName] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: _richText(context, spans)),
        ],
      ),
    );
  }

  Widget _buildCode(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final code = data['code'] as String? ?? '';
    final language = data['language'] as String? ?? 'plaintext';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF15171A)
            : const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final rows = data['rows'] as List? ?? [];

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstRow = Map<String, dynamic>.from(rows.first as Map);
    final firstCells = firstRow['cells'] as List? ?? [];

    final columnCount = firstCells.length;

    if (columnCount == 0) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(
          color: Theme.of(context).dividerColor,
        ),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: rows.map((row) {
          final rowData = Map<String, dynamic>.from(row as Map);
          final cells =
              (rowData['cells'] as List? ?? []).take(columnCount).toList();

          final renderedCells = cells.map((cell) {
            final cellData = Map<String, dynamic>.from(cell as Map);
            final cellSpans = _readSpans(cellData);

            return Padding(
              padding: const EdgeInsets.all(8),
              child: _richText(context, cellSpans),
            );
          }).toList();

          while (renderedCells.length < columnCount) {
            renderedCells.add(
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox.shrink(),
              ),
            );
          }

          return TableRow(children: renderedCells);
        }).toList(),
      ),
    );
  }

  Widget _buildBookmark(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.bookmark_outline),
        title: Text(data['title'] as String? ?? 'Bookmark'),
        subtitle: Text(
          data['description'] as String? ?? data['url'] as String? ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildLink(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.link),
      title: Text(data['url'] as String? ?? ''),
    );
  }

  Widget _buildPageLink(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.description_outlined),
      title: Text(data['pageId'] as String? ?? 'Linked page'),
    );
  }

  Widget _buildReminder(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.alarm),
      title: Text(data['title'] as String? ?? 'Reminder'),
      subtitle: Text(data['dueAt'] as String? ?? ''),
    );
  }
}
