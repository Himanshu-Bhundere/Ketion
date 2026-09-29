import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';

import 'editor_identity_registry.dart';

/// A page-scoped controller that owns the native Super Editor [Editor]
/// instance for the purpose of history (undo/redo).
///
/// Unlike the previous `EditorStateNotifier`, this does NOT maintain
/// its own undo/redo stacks. It uses the native `Editor` history and
/// orchestrates snapshotting before history operations to allow
/// `KetionEditListener` to perform surgical O(affected) reconciliation.
class EditorHistoryController extends ChangeNotifier {
  final Editor editor;
  final Document document;
  final EditorIdentityRegistry registry;

  bool _canUndo = false;
  bool _canRedo = false;

  bool get canUndo => _canUndo;
  bool get canRedo => _canRedo;

  late final EditListener _editListener;

  EditorHistoryController({
    required this.editor,
    required this.document,
    required this.registry,
  }) {
    _updateState();
    _editListener = FunctionalEditListener((_) => _updateState());
    editor.addListener(_editListener);
  }

  @override
  void dispose() {
    editor.removeListener(_editListener);
    super.dispose();
  }

  void _updateState() {
    final newCanUndo = editor.history.isNotEmpty;
    final newCanRedo = editor.future.isNotEmpty;

    if (_canUndo != newCanUndo || _canRedo != newCanRedo) {
      _canUndo = newCanUndo;
      _canRedo = newCanRedo;
      notifyListeners();
    }
  }

  void undo() {
    debugPrint('KETION: EditorHistoryController.undo() called!');
    if (!canUndo) return;
    
    // 1. Take a pre-history snapshot of the document structure and content
    registry.takeSnapshot(document);

    // 2. Perform the native undo operation
    editor.undo();

    // Note: The actual reconciliation happens in `KetionEditListener.onEdit`
    // which detects the presence of the snapshot and diffs the document.
  }

  void redo() {
    debugPrint('KETION: EditorHistoryController.redo() called!');
    if (!canRedo) return;
    
    // 1. Take a pre-history snapshot of the document structure and content
    registry.takeSnapshot(document);

    // 2. Perform the native redo operation
    editor.redo();
  }
}

final editorHistoryControllerProvider = StateProvider.family.autoDispose<EditorHistoryController?, String>((ref, pageId) {
  return null;
});
