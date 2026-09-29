import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'slash_command_menu.dart';
import 'slash_command_popup.dart';

/// Shared slash-command interaction for every editable block type.
///
/// The block widget supplies commands, while this class owns filtering, overlay
/// lifetime, keyboard selection, and viewport-aware placement.
class SlashCommandController {
  SlashCommandController({
    required this.textController,
    required this.layerLink,
    required this.anchorKey,
    required this.context,
    required this.optionsBuilder,
  });

  static const _popupMaxHeight = 300.0;

  final TextEditingController textController;
  final LayerLink layerLink;
  final GlobalKey anchorKey;
  final BuildContext Function() context;
  final List<SlashCommandOption> Function(String query) optionsBuilder;

  OverlayEntry? _overlay;
  String _query = '';
  int _selectedIndex = 0;
  int _slashStartIndex = -1;

  bool get isOpen => _overlay != null;

  List<SlashCommandOption> get _options => optionsBuilder(_query);

  void check(String value) {
    final selection = textController.selection;
    if (selection.isValid && selection.isCollapsed) {
      final cursor = selection.start.clamp(0, value.length);
      final beforeCursor = value.substring(0, cursor);
      final slashIndex = beforeCursor.lastIndexOf('/');
      if (slashIndex != -1 &&
          (slashIndex == 0 ||
              beforeCursor[slashIndex - 1] == ' ' ||
              beforeCursor[slashIndex - 1] == '\n')) {
        _slashStartIndex = slashIndex;
        _query = beforeCursor.substring(slashIndex + 1);
        _selectedIndex = 0;
        _show();
        return;
      }
    }
    close();
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

    final text = textController.text;
    final selection = textController.selection;
    final cursor =
        selection.isValid ? selection.start.clamp(0, text.length) : text.length;
    final before = text.substring(
      0,
      _slashStartIndex.clamp(0, text.length),
    );
    final after = text.substring(cursor);
    textController.value = TextEditingValue(
      text: before + after,
      selection: TextSelection.collapsed(offset: before.length),
    );
    final action = options[_selectedIndex].onSelected;
    close();
    action('legacy_node_id');
  }

  void close() {
    _overlay?.remove();
    _overlay = null;
    _query = '';
    _selectedIndex = 0;
    _slashStartIndex = -1;
  }

  void dispose() => close();

  void _show() {
    if (_overlay == null) {
      _overlay = OverlayEntry(
        builder: (overlayContext) {
          final media = MediaQuery.of(overlayContext);
          final anchorBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
          final anchorPosition = anchorBox?.localToGlobal(Offset.zero);
          final anchorHeight = anchorBox?.size.height ?? 24.0;
          final anchorTop = anchorPosition?.dy ?? 0.0;
          final keyboardTop = media.size.height - media.viewInsets.bottom;
          final below = keyboardTop - (anchorTop + anchorHeight) - 10.0;
          final above = anchorTop - 10.0;
          final showAbove = below < _popupMaxHeight && above > below;
          final offset = showAbove
              ? Offset(
                  0,
                  -math.min(_popupMaxHeight, math.max(0, above)).toDouble(),
                )
              : Offset(0, anchorHeight + 10.0);

          return Positioned(
            width: 300,
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              offset: offset,
              child: SlashCommandPopup(
                options: _options,
                selectedIndex: _selectedIndex,
                onOptionTapped: (index) {
                  _selectedIndex = index;
                  selectCurrent();
                },
              ),
            ),
          );
        },
      );
      Overlay.of(context()).insert(_overlay!);
    } else {
      _overlay!.markNeedsBuild();
    }
  }
}
