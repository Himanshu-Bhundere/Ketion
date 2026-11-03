import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import 'editor_identity_registry.dart';
import 'ketion_edit_requests.dart';
import 'ketion_toggle_keyboard_actions.dart';

void _defaultOnExit() {}

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
    this.onExit = _defaultOnExit,
  });

  final bool isExpanded;
  final ValueChanged<bool> setExpanded;
  final VoidCallback onExit;

  @override
  KetionToggleComponentViewModel copy() {
    return KetionToggleComponentViewModel(
      nodeId: nodeId,
      maxWidth: maxWidth,
      padding: padding,
      text: text.copyText(0),
      textDirection: textDirection,
      textAlignment: textAlignment,
      selectionColor: selectionColor,
      textStyleBuilder: textStyleBuilder,
      isExpanded: isExpanded,
      setExpanded: setExpanded,
      onExit: onExit,
    )..internalCopy(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is KetionToggleComponentViewModel &&
          isExpanded == other.isExpanded;

  @override
  int get hashCode => super.hashCode ^ isExpanded.hashCode;
}

class KetionToggleComponentBuilder implements ComponentBuilder {
  const KetionToggleComponentBuilder(
    this.editor, {
    this.registry,
  });

  final Editor editor;
  final EditorIdentityRegistry? registry;

  static bool isToggleNode(DocumentNode node) {
    if (node is! TextNode) return false;
    final blockType = node.metadata['blockType'];
    final listType = node.metadata['listType'];
    final type = node.metadata['type'];
    return blockType == 'toggle' ||
        blockType == const NamedAttribution('toggle') ||
        (blockType is NamedAttribution && blockType.name == 'toggle') ||
        (listType == 'toggle') ||
        (type == 'toggle');
  }

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (!isToggleNode(node) || node is! TextNode) {
      return null;
    }

    final textDirection = getParagraphDirection(node.text.toPlainText());
    final isExpanded = node.metadata['isExpanded'] as bool? ?? false;
    debugPrint(
      '[KETION_TOGGLE_DIAG] KetionToggleComponentBuilder.createViewModel: nodeId=${node.id}, isExpanded=$isExpanded, metadata=${node.metadata}',
    );

    return KetionToggleComponentViewModel(
      nodeId: node.id,
      maxWidth: double.infinity,
      padding: EdgeInsets.zero,
      text: node.text,
      textDirection: textDirection,
      textAlignment:
          textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.right,
      textStyleBuilder: noStyleBuilder,
      selectionColor: const Color(0x00000000),
      isExpanded: isExpanded,
      setExpanded: (bool expanded) {
        debugPrint(
          '[KETION_TOGGLE_DIAG] Toggle arrow clicked for nodeId=${node.id}, new isExpanded=$expanded',
        );
        editor.execute(
          [
            ToggleExpandedRequest(
              nodeId: node.id,
              isExpanded: expanded,
            ),
          ],
        );
      },
      onExit: () {
        insertExitParagraphAfterToggle(
          editor: editor,
          document: document,
          toggleNode: node,
          registry: registry,
        );
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

    debugPrint(
      '[KETION_TOGGLE_DIAG] KetionToggleComponentBuilder.createComponent: nodeId=${componentViewModel.nodeId}, isExpanded=${componentViewModel.isExpanded}',
    );

    return KetionToggleComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel,
      isExpanded: componentViewModel.isExpanded,
      onToggle: componentViewModel.setExpanded,
      onExit: componentViewModel.onExit,
    );
  }
}

class KetionToggleComponent extends StatefulWidget {
  const KetionToggleComponent({
    super.key,
    required this.viewModel,
    required this.isExpanded,
    required this.onToggle,
    this.onExit = _defaultOnExit,
    this.showDebugPaint = false,
  });

  final ParagraphComponentViewModel viewModel;
  final bool isExpanded;
  final ValueChanged<bool> onToggle;
  final VoidCallback onExit;
  final bool showDebugPaint;

  @override
  State<KetionToggleComponent> createState() => _KetionToggleComponentState();
}

class _KetionToggleComponentState extends State<KetionToggleComponent>
    with ProxyDocumentComponent<KetionToggleComponent>, ProxyTextComposable {
  final _textKey = GlobalKey();

  @override
  GlobalKey<State<StatefulWidget>> get childDocumentComponentKey => _textKey;

  @override
  TextComposable get childTextComposable =>
      childDocumentComponentKey.currentState as TextComposable;

  @override
  NodePosition? getPositionAtOffset(Offset localOffset) {
    final childPosition = super.getPositionAtOffset(localOffset);
    if (childPosition != null) {
      return childPosition;
    }

    final childContext = childDocumentComponentKey.currentContext;
    if (childContext == null) return null;
    final childRenderObject = childContext.findRenderObject() as RenderBox?;
    if (childRenderObject == null) return null;

    final parentRenderObject = context.findRenderObject() as RenderBox;
    final childOffset = parentRenderObject.globalToLocal(
      childRenderObject.localToGlobal(Offset.zero),
    );

    final childLocalOffset = localOffset - childOffset;

    // Snap to the closest text boundary
    final dx = childLocalOffset.dx.clamp(0.0, childRenderObject.size.width);
    final dy = childLocalOffset.dy.clamp(0.0, childRenderObject.size.height);

    return (childDocumentComponentKey.currentState as DocumentComponent)
        .getPositionAtOffset(Offset(dx, dy));
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[KETION_TOGGLE_DIAG] KetionToggleComponent.build: nodeId=${widget.viewModel.nodeId}, isExpanded=${widget.isExpanded}',
    );
    return Directionality(
      textDirection: widget.viewModel.textDirection,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onToggle(!widget.isExpanded),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: Icon(
                          widget.isExpanded
                              ? Icons.arrow_drop_down
                              : Icons.arrow_right,
                          size: 24,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  if (widget.isExpanded)
                    IconButton(
                      tooltip: 'Exit toggle',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.subdirectory_arrow_right, size: 18),
                      onPressed: widget.onExit,
                    ),
                ],
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
