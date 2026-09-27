import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

class DepthWrappingComponentBuilder implements ComponentBuilder {
  const DepthWrappingComponentBuilder(this.innerBuilder, this.document);

  final ComponentBuilder innerBuilder;
  final Document document;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    return innerBuilder.createViewModel(document, node);
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    final widget =
        innerBuilder.createComponent(componentContext, componentViewModel);
    if (widget == null) return null;

    final node = document.getNodeById(componentViewModel.nodeId);
    final depth = node?.metadata['depth'] as int? ?? 0;
    
    if (depth > 0) {
      return Padding(
        padding: EdgeInsets.only(left: depth * 24.0),
        child: widget,
      );
    }

    return widget;
  }
}
