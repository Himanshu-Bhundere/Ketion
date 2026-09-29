import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import 'slash_command_menu.dart';
import 'slash_command_popup.dart';

class SuperEditorSlashCommandController {
  final MutableDocument document;
  final MutableDocumentComposer composer;
  final Editor editor;
  final BuildContext Function() context;
  final List<SlashCommandOption> Function(String query) optionsBuilder;
  final VoidCallback onDismiss;

  SuperEditorSlashCommandController({
    required this.document,
    required this.composer,
    required this.editor,
    required this.context,
    required this.optionsBuilder,
    required this.onDismiss,
  }) {
    composer.selectionNotifier.addListener(_onSelectionChanged);
  }

  OverlayEntry? _overlay;
  String _query = '';
  int _selectedIndex = 0;
  int _slashStartIndex = -1;
  String? _nodeId;
  String? get nodeId => _nodeId;

  bool get isOpen => _overlay != null;

  List<SlashCommandOption> get _options => optionsBuilder(_query);
  
  final LayerLink layerLink = LayerLink();

  void _onSelectionChanged() {
    final selection = composer.selection;
    if (selection == null || !selection.isCollapsed) {
      close();
      return;
    }

    final position = selection.extent;
    if (position.nodePosition is! TextNodePosition) {
      close();
      return;
    }

    final textPosition = position.nodePosition as TextNodePosition;
    final node = document.getNodeById(position.nodeId);
    if (node is! TextNode) {
      close();
      return;
    }

    final text = node.text.toPlainText();
    final offset = textPosition.offset;
    final beforeCursor = text.substring(0, offset);
    final slashIndex = beforeCursor.lastIndexOf('/');
    
    if (slashIndex != -1 &&
        (slashIndex == 0 ||
            beforeCursor[slashIndex - 1] == ' ' ||
            beforeCursor[slashIndex - 1] == '\n')) {
      _slashStartIndex = slashIndex;
      _query = beforeCursor.substring(slashIndex + 1);
      _nodeId = node.id;
      _selectedIndex = 0;
      _show();
    } else {
      close();
    }
  }

  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !isOpen) return false;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _selectedIndex = math.max(0, _selectedIndex - 1);
      _overlay?.markNeedsBuild();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _selectedIndex = math.min(math.max(0, _options.length - 1), _selectedIndex + 1);
      _overlay?.markNeedsBuild();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      selectCurrent();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      close();
      return true;
    }
    return false;
  }

  void selectCurrent() {
    final options = _options;
    if (options.isEmpty || _selectedIndex >= options.length) {
      close();
      return;
    }
    
    final action = options[_selectedIndex].onSelected;
    
    if (_nodeId != null) {
       final node = document.getNodeById(_nodeId!);
       if (node is TextNode) {
          final selection = composer.selection;
          if (selection != null && selection.isCollapsed) {
             final extent = selection.extent;
             if (extent.nodePosition is TextNodePosition) {
                final offset = (extent.nodePosition as TextNodePosition).offset;
                if (_slashStartIndex >= 0 && offset > _slashStartIndex) {
                   editor.execute([
                      DeleteContentRequest(
                         documentRange: DocumentRange(
                            start: DocumentPosition(nodeId: _nodeId!, nodePosition: TextNodePosition(offset: _slashStartIndex)),
                            end: DocumentPosition(nodeId: _nodeId!, nodePosition: TextNodePosition(offset: offset)),
                         ),
                      ),
                   ]);
                }
             }
          }
       }
    }
    
    close();
    action();
  }

  void close() {
    if (_overlay != null) {
       _overlay?.remove();
       _overlay = null;
       _query = '';
       _selectedIndex = 0;
       _slashStartIndex = -1;
       _nodeId = null;
       onDismiss();
    }
  }

  void dispose() {
    composer.selectionNotifier.removeListener(_onSelectionChanged);
    close();
  }

  void _show() {
    if (_overlay == null) {
      _overlay = OverlayEntry(
        builder: (overlayContext) {
          return Stack(
            children: [
               Positioned(
                 bottom: 50,
                 left: 50,
                 child: SlashCommandPopup(
                   options: _options,
                   selectedIndex: _selectedIndex,
                 ),
               ),
            ],
          );
        },
      );
      Overlay.of(context()).insert(_overlay!);
    } else {
      _overlay!.markNeedsBuild();
    }
  }
}
