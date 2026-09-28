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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

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
    if (result.entityType == 'page') {
      return result.pageTitle ?? 'Untitled Note';
    } else if (result.entityType == 'block') {
      return result.pageTitle ?? 'Untitled Note';
    } else if (result.entityType == 'tag') {
      return 'Tag Match: ${result.snippet.replaceAll(RegExp(r'<[^>]*>'), '')}';
    }
    return 'Result';
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

    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        _formatTitle(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.breadcrumb != null) ...[
            Text(
              result.breadcrumb!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
          ],
          RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: _buildHighlightedSpans(result.snippet, context),
            ),
          ),
          if (result.modifiedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Modified ${_formatDate(result.modifiedAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      isThreeLine: result.breadcrumb != null || result.modifiedAt != null,
      onTap: onTap,
    );
  }
}
