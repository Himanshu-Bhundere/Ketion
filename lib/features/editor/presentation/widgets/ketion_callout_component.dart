import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import 'ketion_callout_node.dart';

class KetionCalloutComponentViewModel extends ParagraphComponentViewModel {
  KetionCalloutComponentViewModel({
    required super.nodeId,
    super.maxWidth,
    required super.padding,
    required super.text,
    required super.textDirection,
    required super.textAlignment,
    required super.selectionColor,
    required super.textStyleBuilder,
    required this.icon,
    required this.colorString,
  });

  final String icon;
  final String colorString;

  @override
  KetionCalloutComponentViewModel copy() {
    return KetionCalloutComponentViewModel(
      nodeId: nodeId,
      maxWidth: maxWidth,
      padding: padding,
      text: text.copyText(0),
      textDirection: textDirection,
      textAlignment: textAlignment,
      selectionColor: selectionColor,
      textStyleBuilder: textStyleBuilder,
      icon: icon,
      colorString: colorString,
    )..internalCopy(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is KetionCalloutComponentViewModel &&
          icon == other.icon &&
          colorString == other.colorString;

  @override
  int get hashCode => super.hashCode ^ icon.hashCode ^ colorString.hashCode;
}

class KetionCalloutComponentBuilder implements ComponentBuilder {
  const KetionCalloutComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! KetionCalloutNode) {
      return null;
    }

    final textDirection = getParagraphDirection(node.text.toPlainText());

    return KetionCalloutComponentViewModel(
      nodeId: node.id,
      maxWidth: double.infinity,
      padding: EdgeInsets.zero,
      text: node.text,
      textDirection: textDirection,
      textAlignment: textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.right,
      textStyleBuilder: noStyleBuilder,
      selectionColor: const Color(0x00000000),
      icon: node.icon,
      colorString: node.color,
    );
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! KetionCalloutComponentViewModel) {
      return null;
    }

    final icon = componentViewModel.icon;
    final colorString = componentViewModel.colorString;

    return KetionCalloutComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel,
      icon: icon,
      colorString: colorString,
    );
  }
}

class KetionCalloutComponent extends StatefulWidget {
  const KetionCalloutComponent({
    super.key,
    required this.viewModel,
    required this.icon,
    required this.colorString,
    this.showDebugPaint = false,
  });

  final ParagraphComponentViewModel viewModel;
  final String icon;
  final String colorString;
  final bool showDebugPaint;

  @override
  State<KetionCalloutComponent> createState() => _KetionCalloutComponentState();
}

class _KetionCalloutComponentState extends State<KetionCalloutComponent> with ProxyDocumentComponent<KetionCalloutComponent>, ProxyTextComposable {
  final _textKey = GlobalKey();

  @override
  GlobalKey<State<StatefulWidget>> get childDocumentComponentKey => _textKey;

  @override
  TextComposable get childTextComposable => childDocumentComponentKey.currentState as TextComposable;

  Color _getBackgroundColor(BuildContext context, String colorString) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (colorString) {
      case 'grey':
        return isDark ? Colors.grey.shade800 : Colors.grey.shade100;
      case 'blue':
        return isDark ? Colors.blue.shade900.withValues(alpha: 0.4) : Colors.blue.shade50;
      case 'green':
        return isDark ? Colors.green.shade900.withValues(alpha: 0.4) : Colors.green.shade50;
      case 'yellow':
        return isDark ? Colors.yellow.shade900.withValues(alpha: 0.4) : Colors.yellow.shade50;
      case 'red':
        return isDark ? Colors.red.shade900.withValues(alpha: 0.4) : Colors.red.shade50;
      default:
        return isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    }
  }

  Color _getBorderColor(BuildContext context, String colorString) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (colorString) {
      case 'grey':
        return isDark ? Colors.grey.shade600 : Colors.grey.shade400;
      case 'blue':
        return isDark ? Colors.blue.shade400 : Colors.blue.shade600;
      case 'green':
        return isDark ? Colors.green.shade400 : Colors.green.shade600;
      case 'yellow':
        return isDark ? Colors.yellow.shade400 : Colors.yellow.shade600;
      case 'red':
        return isDark ? Colors.red.shade400 : Colors.red.shade600;
      default:
        return isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = _getBorderColor(context, widget.colorString);
    
    return Directionality(
      textDirection: widget.viewModel.textDirection,
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(context, widget.colorString),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
            top: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade200),
            right: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade200),
            bottom: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade200),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(),
            ),
            Expanded(
              child: TextComponent(
                key: _textKey,
                text: widget.viewModel.text,
                textDirection: widget.viewModel.textDirection,
                textAlign: widget.viewModel.textAlignment,
                maxLines: widget.viewModel.maxLines,
                textStyleBuilder: widget.viewModel.textStyleBuilder,
                inlineWidgetBuilders: widget.viewModel.inlineWidgetBuilders,
                textSelection: widget.viewModel.selection,
                selectionColor: widget.viewModel.selectionColor,
                highlightWhenEmpty: widget.viewModel.highlightWhenEmpty,
                underlines: widget.viewModel.createUnderlines(),
                showDebugPaint: widget.showDebugPaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
