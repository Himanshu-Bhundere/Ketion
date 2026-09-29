import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import 'slash_command_menu.dart';
import 'slash_command_popup.dart';
import 'ketion_edit_requests.dart';

class SuperEditorSlashCommandOption extends SlashCommandOption {
  final List<EditRequest> Function(String nodeId) getEditRequests;
  
  SuperEditorSlashCommandOption({
    required super.title,
    required super.subtitle,
    required super.icon,
    required super.category,
    super.aliases,
    required this.getEditRequests,
  }) : super(onSelected: (_) {});
}

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
  SlashCommandTarget? _target;
  String? get nodeId => _target?.nodeId;

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
    
    if (_target != null && _target!.nodeId == node.id && _target!.slashStartIndex == slashIndex && offset >= slashIndex) {
      _query = beforeCursor.substring(slashIndex + 1);
      _target = SlashCommandTarget(
        nodeId: node.id,
        slashStartIndex: slashIndex,
        slashEndIndex: offset,
      );
      _show();
    } else if (slashIndex != -1 &&
        (slashIndex == 0 ||
            beforeCursor[slashIndex - 1] == ' ' ||
            beforeCursor[slashIndex - 1] == '\n')) {
      _query = beforeCursor.substring(slashIndex + 1);
      _target = SlashCommandTarget(
        nodeId: node.id,
        slashStartIndex: slashIndex,
        slashEndIndex: offset,
      );
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

  void selectCommand(int index) {
    final options = _options;
    if (options.isEmpty || index >= options.length) {
      close();
      return;
    }
    
    final option = options[index];
    final action = option.onSelected;
    final target = _target;
    
    if (target != null) {
       if (option is SuperEditorSlashCommandOption) {
          final innerRequests = option.getEditRequests(target.nodeId);
          if (innerRequests.isNotEmpty) {
             final requests = <EditRequest>[];
             requests.add(ConvertSlashCommandRequest(
               target: target,
               innerRequest: innerRequests.first,
             ),);
             requests.addAll(innerRequests.skip(1));
             editor.execute(requests);
          }
       }
    }
    
    close();
    
    if (target != null) {
      action(target.nodeId);
    }
  }

  void selectCurrent() {
    selectCommand(_selectedIndex);
  }

  void close() {
    if (_overlay != null) {
       _overlay?.remove();
       _overlay = null;
       _query = '';
       _selectedIndex = 0;
       _target = null;
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
          final mediaQuery = MediaQuery.of(overlayContext);
          final keyboardHeight = mediaQuery.viewInsets.bottom;
          
          return Stack(
            children: [
               Positioned(
                 bottom: keyboardHeight > 0 ? keyboardHeight + 8 : 50,
                 left: 24,
                 right: 24,
                 child: Align(
                   alignment: Alignment.bottomLeft,
                   child: SlashCommandPopup(
                     options: _options,
                     selectedIndex: _selectedIndex,
                     onOptionTapped: (index) {
                       selectCommand(index);
                     },
                   ),
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
