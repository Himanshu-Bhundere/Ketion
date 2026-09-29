import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import 'ketion_edit_requests.dart';

class KetionToggleComponentViewModel extends ParagraphComponentViewModel {
  KetionToggleComponentViewModel({
    required super.nodeId,
    super.maxWidth,
    required super.padding,
    required super.text,
    required super.textDirection,
    required super.textAlignment,
    required super.selectionColor,
    required super.textStyleBuilder,
    required this.isExpanded,
    required this.setExpanded,
  });

  final bool isExpanded;
  final ValueChanged<bool> setExpanded;
}

class KetionToggleComponentBuilder implements ComponentBuilder {
  const KetionToggleComponentBuilder(this.editor);
  
  final Editor editor;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! ParagraphNode || node.metadata['blockType'] != 'toggle') {
      return null;
    }

    final textDirection = getParagraphDirection(node.text.toPlainText());
    final isExpanded = node.metadata['isExpanded'] as bool? ?? false;

    return KetionToggleComponentViewModel(
      nodeId: node.id,
      maxWidth: double.infinity,
      padding: EdgeInsets.zero,
      text: node.text,
      textDirection: textDirection,
      textAlignment: textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.right,
      textStyleBuilder: noStyleBuilder,
      selectionColor: const Color(0x00000000),
      isExpanded: isExpanded,
      setExpanded: (bool expanded) {
         editor.execute([
           ToggleExpandedRequest(
             nodeId: node.id,
             isExpanded: expanded,
           ),
         ],);
      },
    );
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! KetionToggleComponentViewModel) {
      return null;
    }

    return KetionToggleComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel,
      isExpanded: componentViewModel.isExpanded,
      onToggle: componentViewModel.setExpanded,
    );
  }
}

class KetionToggleComponent extends StatefulWidget {
  const KetionToggleComponent({
    super.key,
    required this.viewModel,
    required this.isExpanded,
    required this.onToggle,
    this.showDebugPaint = false,
  });

  final ParagraphComponentViewModel viewModel;
  final bool isExpanded;
  final ValueChanged<bool> onToggle;
  final bool showDebugPaint;

  @override
  State<KetionToggleComponent> createState() => _KetionToggleComponentState();
}

class _KetionToggleComponentState extends State<KetionToggleComponent> with ProxyDocumentComponent<KetionToggleComponent>, ProxyTextComposable {
  final _textKey = GlobalKey();

  @override
  GlobalKey<State<StatefulWidget>> get childDocumentComponentKey => _textKey;

  @override
  TextComposable get childTextComposable => childDocumentComponentKey.currentState as TextComposable;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.viewModel.textDirection,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 2),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.onToggle(!widget.isExpanded),
                  child: Icon(
                    widget.isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
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
