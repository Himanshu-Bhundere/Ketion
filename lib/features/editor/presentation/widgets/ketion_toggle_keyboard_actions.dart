import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import 'ketion_edit_requests.dart';
import 'ketion_toggle_component.dart';

ExecutionInstruction splitToggleWhenEnterPressed({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent.logicalKey != LogicalKeyboardKey.enter &&
      keyEvent.logicalKey != LogicalKeyboardKey.numpadEnter) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  try {
    if (HardwareKeyboard.instance.isShiftPressed) {
      return ExecutionInstruction.continueExecution;
    }
  } catch (_) {
    // HardwareKeyboard not initialized in some test environments
  }

  final selection = editContext.composer.selection;
  if (selection == null || !selection.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! ParagraphNode) {
    return ExecutionInstruction.continueExecution;
  }

  if (!KetionToggleComponentBuilder.isToggleNode(node)) {
    return ExecutionInstruction.continueExecution;
  }

  // If we are at the end of the toggle, we create or focus a child block inside that toggle
  final text = node.text;
  final position = selection.extent.nodePosition as TextNodePosition;

  if (position.offset == text.length) {
    final isExpanded = node.metadata['isExpanded'] == true;
    final depth = node.metadata['depth'] as int? ?? 0;

    // First ensure the toggle is expanded if currently collapsed
    if (!isExpanded) {
      editContext.editor.execute([
        ToggleExpandedRequest(nodeId: node.id, isExpanded: true),
      ]);
    }

    final parentBlockId = node.metadata['blockId'] as String? ?? node.id;
    final newNodeId = Editor.createNodeId();
    final childDepth = depth + 1;

    // Create a new child block inside the toggle hierarchy
    editContext.editor.execute([
      InsertNodeAfterNodeRequest(
        existingNodeId: node.id,
        newNode: ParagraphNode(
          id: newNodeId,
          text: AttributedText(),
          metadata: {
            'depth': childDepth,
            'parentBlockId': parentBlockId,
          },
        ),
      ),
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: newNodeId,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);

    return ExecutionInstruction.haltExecution;
  }

  // If not at the end of the text, let standard super_editor split the paragraph
  // which will copy the toggle metadata (creating a new sibling toggle).
  return ExecutionInstruction.continueExecution;
}

ExecutionInstruction indentParagraphWhenTabPressed({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent.logicalKey != LogicalKeyboardKey.tab) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  final hardwareKeyboard = HardwareKeyboard.instance;
  if (hardwareKeyboard.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || !selection.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! ParagraphNode) {
    return ExecutionInstruction.continueExecution;
  }

  // We indent the paragraph!
  editContext.editor.execute([
    IndentParagraphRequest(node.id),
  ]);

  return ExecutionInstruction.haltExecution;
}

ExecutionInstruction unindentParagraphWhenShiftTabPressed({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent.logicalKey != LogicalKeyboardKey.tab) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  final hardwareKeyboard = HardwareKeyboard.instance;
  if (!hardwareKeyboard.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || !selection.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! ParagraphNode) {
    return ExecutionInstruction.continueExecution;
  }

  // We unindent the paragraph!
  editContext.editor.execute([
    UnIndentParagraphRequest(node.id),
  ]);

  return ExecutionInstruction.haltExecution;
}

ExecutionInstruction unindentParagraphWhenBackspacePressed({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent.logicalKey != LogicalKeyboardKey.backspace) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || !selection.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  final position = selection.extent.nodePosition;
  if (position is! TextNodePosition || position.offset > 0) {
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! ParagraphNode) {
    return ExecutionInstruction.continueExecution;
  }

  final depth = node.metadata['depth'] as int? ?? 0;
  if (depth == 0) {
    return ExecutionInstruction.continueExecution;
  }

  editContext.editor.execute([
    UnIndentParagraphRequest(node.id),
  ]);

  return ExecutionInstruction.haltExecution;
}

ExecutionInstruction unindentParagraphWhenEnterPressedOnEmpty({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent.logicalKey != LogicalKeyboardKey.enter &&
      keyEvent.logicalKey != LogicalKeyboardKey.numpadEnter) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent is! KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }

  final hardwareKeyboard = HardwareKeyboard.instance;
  if (hardwareKeyboard.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || !selection.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! ParagraphNode) {
    return ExecutionInstruction.continueExecution;
  }

  if (KetionToggleComponentBuilder.isToggleNode(node)) {
    return ExecutionInstruction.continueExecution;
  }

  final depth = node.metadata['depth'] as int? ?? 0;
  if (depth > 0 && node.text.isEmpty) {
    editContext.editor.execute([
      UnIndentParagraphRequest(node.id),
    ]);
    return ExecutionInstruction.haltExecution;
  }

  return ExecutionInstruction.continueExecution;
}
