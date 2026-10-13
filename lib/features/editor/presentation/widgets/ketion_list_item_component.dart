import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

/// A component builder for [ListItemNode]s that uses a fixed prefix width (24.0)
/// for bullets and numbers, delegating all per-level indentation to
/// [DepthWrappingComponentBuilder] to maintain a single unified indentation model.
/// Computes the 1-based ordinal value for an ordered [ListItemNode].
/// Numbering is scoped to the item's sibling group (same depth and parent)
/// in document order. Preceding items with deeper depth (nested descendants)
/// are skipped so they do not break the sibling sequence.
/// Preceding siblings that are ordered list items increment the count.
/// Any non-ordered sibling at the same level, or reaching a shallower depth,
/// terminates the sequence.
int computeKetionListItemOrdinalValue(ListItemNode node, Document document) {
  int count = 1;
  final nodeDepth = node.metadata['depth'] as int? ?? node.indent;
  final nodeParentId = node.metadata['parentBlockId'] as String?;

  DocumentNode? prev = document.getNodeBeforeById(node.id);
  while (prev != null) {
    final prevDepth = prev.metadata['depth'] as int? ??
        (prev is ListItemNode ? prev.indent : 0);
    final prevParentId = prev.metadata['parentBlockId'] as String?;

    if (prevDepth < nodeDepth) {
      // Reached an ancestor level or parent
      break;
    }

    if (prevDepth == nodeDepth && prevParentId == nodeParentId) {
      if (prev is ListItemNode && prev.type == ListItemType.ordered) {
        count++;
      } else {
        // A non-ordered sibling at the same level resets list sequence
        break;
      }
    }

    prev = document.getNodeBeforeById(prev.id);
  }

  return count;
}

class KetionListItemComponentBuilder implements ComponentBuilder {
  const KetionListItemComponentBuilder();

  static double fixedIndentCalculator(TextStyle textStyle, int indent) => 24.0;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! ListItemNode) {
      return null;
    }

    int? ordinalValue;
    if (node.type == ListItemType.ordered) {
      ordinalValue = computeKetionListItemOrdinalValue(node, document);
    }

    final textDirection = getParagraphDirection(node.text.toPlainText());
    final textAlignment =
        textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.right;

    final createdAt = node.metadata[NodeMetadata.createdAt] as DateTime?;

    return switch (node.type) {
      ListItemType.unordered => UnorderedListItemComponentViewModel(
          nodeId: node.id,
          createdAt: createdAt,
          indent: 0,
          text: node.text,
          textDirection: textDirection,
          textAlignment: textAlignment,
          textStyleBuilder: noStyleBuilder,
          selectionColor: const Color(0x00000000),
        ),
      ListItemType.ordered => OrderedListItemComponentViewModel(
          nodeId: node.id,
          createdAt: createdAt,
          indent: 0,
          ordinalValue: ordinalValue,
          text: node.text,
          textDirection: textDirection,
          textAlignment: textAlignment,
          textStyleBuilder: noStyleBuilder,
          selectionColor: const Color(0x00000000),
        ),
    };
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! UnorderedListItemComponentViewModel &&
        componentViewModel is! OrderedListItemComponentViewModel) {
      return null;
    }

    if (componentViewModel is UnorderedListItemComponentViewModel) {
      return UnorderedListItemComponent(
        componentKey: componentContext.componentKey,
        text: componentViewModel.text,
        styleBuilder: componentViewModel.textStyleBuilder,
        indent: 0,
        indentCalculator: fixedIndentCalculator,
        dotStyle: componentViewModel.dotStyle,
        textSelection: componentViewModel.selection,
        textDirection: componentViewModel.textDirection,
        textAlignment: componentViewModel.textAlignment,
        selectionColor: componentViewModel.selectionColor,
        highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
        underlines: componentViewModel.createUnderlines(),
        inlineWidgetBuilders: componentViewModel.inlineWidgetBuilders,
      );
    } else if (componentViewModel is OrderedListItemComponentViewModel) {
      return OrderedListItemComponent(
        componentKey: componentContext.componentKey,
        indent: 0,
        indentCalculator: fixedIndentCalculator,
        listIndex: componentViewModel.ordinalValue ?? 1,
        text: componentViewModel.text,
        textDirection: componentViewModel.textDirection,
        textAlignment: componentViewModel.textAlignment,
        styleBuilder: componentViewModel.textStyleBuilder,
        numeralStyle: componentViewModel.numeralStyle,
        textSelection: componentViewModel.selection,
        selectionColor: componentViewModel.selectionColor,
        highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
        underlines: componentViewModel.createUnderlines(),
        inlineWidgetBuilders: componentViewModel.inlineWidgetBuilders,
      );
    }
    return null;
  }
}
