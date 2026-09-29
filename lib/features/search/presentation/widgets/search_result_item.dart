import 'package:flutter/material.dart';
import '../../domain/models/search_result.dart';

class SearchResultItem extends StatelessWidget {
  final GroupedSearchResult result;
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
    final strongest = result.strongestMatch;
    if (strongest.entityType == 'page') {
      return strongest.pageTitle ?? 'Untitled Note';
    } else if (strongest.entityType == 'block') {
      return strongest.pageTitle ?? 'Untitled Note';
    } else if (strongest.entityType == 'tag') {
      return 'Tag Match: ${strongest.snippet.replaceAll(RegExp(r'<[^>]*>'), '')}';
    }
    return 'Result';
  }

  @override
  Widget build(BuildContext context) {
    final strongest = result.strongestMatch;
    IconData icon;
    switch (strongest.entityType) {
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
          if (strongest.breadcrumb != null) ...[
            Text(
              strongest.breadcrumb!,
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
              children: _buildHighlightedSpans(strongest.snippet, context),
            ),
          ),
          if (strongest.modifiedAt != null || result.matchCount > 1) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (strongest.modifiedAt != null)
                  Text(
                    'Modified ${_formatDate(strongest.modifiedAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (strongest.modifiedAt != null && result.matchCount > 1)
                  const SizedBox(width: 8),
                if (result.matchCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${result.matchCount} matches',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      isThreeLine: strongest.breadcrumb != null || strongest.modifiedAt != null || result.matchCount > 1,
      onTap: onTap,
    );
  }
}
