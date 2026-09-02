import 'package:flutter/material.dart';
import '../../domain/models/search_result.dart';

class SearchResultItem extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.result,
    required this.onTap,
  });

  /// Parse the SQLite snippet tags `<mark>` and `</mark>` into a RichText widget.
  List<TextSpan> _buildHighlightedSpans(String text, BuildContext context) {
    final theme = Theme.of(context);
    final highlightStyle = theme.textTheme.bodyMedium?.copyWith(
      backgroundColor: theme.colorScheme.primaryContainer,
      color: theme.colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.bold,
    );
    final normalStyle = theme.textTheme.bodyMedium;

    final spans = <TextSpan>[];
    final parts = text.split('<mark>');

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (i == 0) {
        if (part.isNotEmpty) {
          spans.add(TextSpan(text: part, style: normalStyle));
        }
      } else {
        final subParts = part.split('</mark>');
        if (subParts.isNotEmpty) {
          spans.add(TextSpan(text: subParts[0], style: highlightStyle));
          if (subParts.length > 1 && subParts[1].isNotEmpty) {
            spans.add(TextSpan(text: subParts[1], style: normalStyle));
          }
        }
      }
    }

    return spans;
  }

  String _formatTitle() {
    switch (result.entityType) {
      case 'page':
        return 'Page Title Match';
      case 'tag':
        return 'Tag Match';
      case 'block':
        return 'Page: ${result.pageId ?? "Unknown"}';
      default:
        return 'Result';
    }
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (result.entityType) {
      case 'page':
        icon = Icons.insert_drive_file_outlined;
        break;
      case 'tag':
        icon = Icons.tag;
        break;
      case 'block':
        icon = Icons.text_snippet_outlined;
        break;
      default:
        icon = Icons.search;
    }

    return ListTile(
      leading: Icon(icon),
      title: Text(_formatTitle()),
      subtitle: RichText(
        text: TextSpan(
          children: _buildHighlightedSpans(result.snippet, context),
        ),
      ),
      onTap: onTap,
    );
  }
}
