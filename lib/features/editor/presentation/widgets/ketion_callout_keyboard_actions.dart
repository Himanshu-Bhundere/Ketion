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
  if (selection == null) {
    return ExecutionInstruction.continueExecution;
  }

  final extentNodeId = selection.extent.nodeId;
  final baseNodeId = selection.base.nodeId;
  if (extentNodeId != baseNodeId) {
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(extentNodeId);
  if (node is! KetionCalloutNode) {
    return ExecutionInstruction.continueExecution;
  }

  int splitOffset = 0;
  int? tailOffset;
  final extentPos = selection.extent.nodePosition;
  final basePos = selection.base.nodePosition;
  if (extentPos is TextNodePosition && basePos is TextNodePosition) {
    final startOffset =
        extentPos.offset < basePos.offset ? extentPos.offset : basePos.offset;
    final endOffset =
        extentPos.offset > basePos.offset ? extentPos.offset : basePos.offset;
    splitOffset = startOffset;
    tailOffset = endOffset;
  }

  final newNodeId = Editor.createNodeId();

  editContext.editor.execute([
    SplitCalloutRequest(
      nodeId: node.id,
      newNodeId: newNodeId,
      splitOffset: splitOffset,
      tailOffset: tailOffset,
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

/// Backspace at offset 0 of a callout should NOT implicitly convert it to a paragraph.
/// Conversion should happen only when explicitly requested by the user.
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

  // We are at the start of a Callout. Do not convert to paragraph implicitly.
  return ExecutionInstruction.haltExecution;
}
