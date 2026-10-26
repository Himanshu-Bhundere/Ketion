/// Shared list numbering service for calculating 1-based ordered list item ordinals.
///
/// Ensures consistent numbering between the block editor, PDF export,
/// and document models.
class ListNumberingEntry {
  final String key;
  final String? listType;
  final int depth;
  final String? parentKey;

  const ListNumberingEntry({
    required this.key,
    required this.listType,
    required this.depth,
    this.parentKey,
  });

  @override
  String toString() =>
      'ListNumberingEntry(key: $key, listType: $listType, depth: $depth, parentKey: $parentKey)';
}

class ListNumberingService {
  /// Computes the 1-based ordinal value for all ordered list items in [entries].
  ///
  /// Numbering rules:
  /// - Only counts ordered list siblings belonging to the same parent.
  /// - Skips deeper descendants (depth > current.depth) so nested subtrees do not break sibling sequence.
  /// - Terminates when reaching a shallower level (depth < current.depth) or a different parent branch.
  /// - Resets numbering when an item with a different listType interrupts the sequence.
  static Map<String, int> computeOrdinals(
    List<ListNumberingEntry> entries,
  ) {
    final result = <String, int>{};

    for (var i = 0; i < entries.length; i++) {
      final current = entries[i];
      if (current.listType != 'numbered') continue;

      var ordinal = 1;

      for (var j = i - 1; j >= 0; j--) {
        final previous = entries[j];

        if (previous.depth < current.depth) break;
        if (previous.depth > current.depth) continue;

        if (previous.parentKey != current.parentKey) break;
        if (previous.listType != 'numbered') break;

        ordinal++;
      }

      result[current.key] = ordinal;
    }

    return result;
  }
}
