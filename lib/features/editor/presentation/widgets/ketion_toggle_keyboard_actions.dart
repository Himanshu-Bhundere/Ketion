import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
import 'package:uuid/uuid.dart';

import '../../domain/services/block_tree_service.dart';
import 'depth_wrapping_component_builder.dart';
import 'editor_identity_registry.dart';
import 'ketion_edit_requests.dart';
import 'ketion_toggle_component.dart';

/// Resolves the persistent block ID for [toggleNode] using [registry].
///
/// If [toggleNode] does not have a `blockId` in its metadata and cannot be
/// resolved via [registry], a new UUID v7 is allocated, registered as pending,
/// and assigned to `toggleNode.metadata['blockId']`.
///
/// Never falls back to `toggleNode.id`.
String resolveToggleBlockId({
  required TextNode toggleNode,
  Document? document,
  EditorIdentityRegistry? registry,
}) {
  var blockId = toggleNode.metadata['blockId'] as String? ??
      registry?.blockIdForNode(toggleNode.id);

  if (blockId == null || blockId.isEmpty) {
    blockId = const Uuid().v7();
    registry?.registerPendingMapping(
      nodeId: toggleNode.id,
      blockId: blockId,
    );
    if (document is MutableDocument && toggleNode is ParagraphNode) {
      document.replaceNodeById(
        toggleNode.id,
        toggleNode.copyWithAddedMetadata({'blockId': blockId}),
      );
    }
  }
  return blockId;
}

/// Inserts a new child block under [toggleNode] at the end of its subtree.
///
/// Both hardware Enter and IME Enter share this unified helper.
///
/// Ensures the toggle's persistent block ID is resolved through [registry],
/// expanding the toggle if collapsed, inserting the new child after the toggle's
/// last descendant, and placing the caret at offset 0 of the new child.
ParagraphNode insertToggleChild({
  required Editor editor,
  required Document document,
  required TextNode toggleNode,
  EditorIdentityRegistry? registry,
  String? newNodeId,
}) {
  final parentBlockId = resolveToggleBlockId(
    toggleNode: toggleNode,
    document: document,
    registry: registry,
  );

  final isExpanded = toggleNode.metadata['isExpanded'] == true;
  if (!isExpanded) {
    editor.execute([
      ToggleExpandedRequest(nodeId: toggleNode.id, isExpanded: true),
    ]);
  }

  final childId = newNodeId ?? Editor.createNodeId();
  final depth = toggleNode.metadata['depth'] as int? ?? 0;
  final childDepth = depth + 1;

  final lastDescendant = BlockTreeService.findLastDescendant(
    document,
    toggleNode,
    getNodeDepth,
  );

  final childNode = ParagraphNode(
    id: childId,
    text: AttributedText(),
    metadata: {
      'depth': childDepth,
      'parentBlockId': parentBlockId,
    },
  );

  editor.execute([
    InsertNodeAfterNodeRequest(
      existingNodeId: lastDescendant.id,
      newNode: childNode,
    ),
    ChangeSelectionRequest(
      DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: childId,
          nodePosition: const TextNodePosition(offset: 0),
        ),
      ),
      SelectionChangeType.placeCaret,
      SelectionReason.userInteraction,
    ),
  ]);

  return childNode;
}

/// Splits [toggleNode] at [splitOffset] in the middle of its header.
///
/// Retains toggle metadata on the original header with text up to [splitOffset],
/// and inserts a new regular paragraph with the remaining text after the toggle's
/// entire child subtree with the toggle's depth and parentBlockId (outside the toggle subtree).
ParagraphNode splitToggleMiddleOfHeader({
  required Editor editor,
  required Document document,
  required TextNode toggleNode,
  required int splitOffset,
  EditorIdentityRegistry? registry,
  String? newNodeId,
}) {
  final text = toggleNode.text;
  final startText = text.copyText(0, splitOffset);
  final endText = text.copyText(splitOffset);

  // 1. Truncate toggle header text to startText
  final updatedToggle = (toggleNode as ParagraphNode).copyParagraphWith(text: startText);
  (document as MutableDocument).replaceNodeById(toggleNode.id, updatedToggle);

  // 2. Resolve sibling metadata: same depth and parentBlockId as the toggle
  final depth = toggleNode.metadata['depth'] as int? ?? 0;
  final parentBlockId = toggleNode.metadata['parentBlockId'] as String?;

  // 3. Find the last descendant so the new sibling is outside the toggle's subtree
  final lastDescendant = BlockTreeService.findLastDescendant(
    document,
    updatedToggle,
    getNodeDepth,
  );

  final newSiblingId = newNodeId ?? Editor.createNodeId();

  // If registry is provided, register pending mapping for the new paragraph
  if (registry != null && registry.blockIdForNode(newSiblingId) == null) {
    registry.registerPendingMapping(
      nodeId: newSiblingId,
      blockId: const Uuid().v7(),
    );
  }

  // 4. Create new normal sibling paragraph (NO toggle metadata)
  final newNode = ParagraphNode(
    id: newSiblingId,
    text: endText,
    metadata: {
      'depth': depth,
      if (parentBlockId != null && parentBlockId.isNotEmpty)
        'parentBlockId': parentBlockId,
    },
  );

  // 5. Insert new node after lastDescendant and place caret at offset 0
  editor.execute([
    InsertNodeAfterNodeRequest(
      existingNodeId: lastDescendant.id,
      newNode: newNode,
    ),
    ChangeSelectionRequest(
      DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: newSiblingId,
          nodePosition: const TextNodePosition(offset: 0),
        ),
      ),
      SelectionChangeType.placeCaret,
      SelectionReason.userInteraction,
    ),
  ]);

  return newNode;
}

ExecutionInstruction splitToggleWhenEnterPressed({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
  EditorIdentityRegistry? registry,
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
  if (node is! TextNode) {
    return ExecutionInstruction.continueExecution;
  }

  if (!KetionToggleComponentBuilder.isToggleNode(node)) {
    return ExecutionInstruction.continueExecution;
  }

  final text = node.text;
  final position = selection.extent.nodePosition as TextNodePosition;

  if (position.offset == text.length) {
    insertToggleChild(
      editor: editContext.editor,
      document: editContext.document,
      toggleNode: node,
      registry: registry,
    );
    return ExecutionInstruction.haltExecution;
  }

  splitToggleMiddleOfHeader(
    editor: editContext.editor,
    document: editContext.document,
    toggleNode: node,
    splitOffset: position.offset,
    registry: registry,
  );
  return ExecutionInstruction.haltExecution;
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
    // Non-empty item where Backspace should delete text
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node == null) {
    return ExecutionInstruction.continueExecution;
  }

  if (node is ListItemNode) {
    final indent = node.metadata['depth'] as int? ?? node.indent;
    if (indent > 0) {
      // Nested bullet that should first outdent
      editContext.editor.execute([
        UnIndentListItemRequest(nodeId: node.id),
      ]);
      return ExecutionInstruction.haltExecution;
    } else if (node.text.isEmpty) {
      // First-level empty bullet converts to normal paragraph
      editContext.editor.execute([
        ConvertListItemToParagraphRequest(nodeId: node.id),
      ]);
      return ExecutionInstruction.haltExecution;
    }
    return ExecutionInstruction.continueExecution;
  }

  if (node is TaskNode) {
    final indent = node.metadata['depth'] as int? ?? node.indent;
    if (indent > 0) {
      // Nested task that should first outdent
      editContext.editor.execute([
        UnIndentTaskRequest(node.id),
      ]);
      return ExecutionInstruction.haltExecution;
    } else if (node.text.isEmpty) {
      // First-level empty task converts to normal paragraph
      editContext.editor.execute([
        ConvertTaskToParagraphRequest(nodeId: node.id),
      ]);
      return ExecutionInstruction.haltExecution;
    }
    return ExecutionInstruction.continueExecution;
  }

  if (node is ParagraphNode) {
    final depth = node.metadata['depth'] as int? ?? 0;
    if (depth > 0) {
      editContext.editor.execute([
        UnIndentParagraphRequest(node.id),
      ]);
      return ExecutionInstruction.haltExecution;
    }
  }

  return ExecutionInstruction.continueExecution;
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
  if (node == null) {
    return ExecutionInstruction.continueExecution;
  }

  if (node is TaskNode) {
    final indent = node.metadata['depth'] as int? ?? node.indent;
    if (indent > 0 && node.text.isEmpty) {
      editContext.editor.execute([
        UnIndentTaskRequest(node.id),
      ]);
      return ExecutionInstruction.haltExecution;
    }
  }

  if (node is ListItemNode) {
    final indent = node.metadata['depth'] as int? ?? node.indent;
    if (indent > 0 && node.text.isEmpty) {
      editContext.editor.execute([
        UnIndentListItemRequest(nodeId: node.id),
      ]);
      return ExecutionInstruction.haltExecution;
    }
  }

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
