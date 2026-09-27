import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import 'ketion_callout_node.dart';
import 'convert_paragraph_to_callout.dart'; // Contains SplitCalloutRequest and ConvertCalloutToParagraphRequest

ExecutionInstruction splitCalloutWhenEnterPressed({
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
  if (node is! KetionCalloutNode) {
    return ExecutionInstruction.continueExecution;
  }

  final newNodeId = Editor.createNodeId();

  editContext.editor.execute([
    SplitCalloutRequest(
      nodeId: node.id,
      newNodeId: newNodeId,
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

ExecutionInstruction convertCalloutToParagraphWhenBackspacePressed({
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

  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! KetionCalloutNode) {
    return ExecutionInstruction.continueExecution;
  }

  final position = selection.extent.nodePosition;
  if (position is! TextNodePosition || position.offset > 0) {
    return ExecutionInstruction.continueExecution;
  }

  // We are at the start of a Callout. Backspace should convert it to a Paragraph.
  editContext.editor.execute([
    ConvertCalloutToParagraphRequest(
      nodeId: node.id,
    ),
  ]);

  return ExecutionInstruction.haltExecution;
}
