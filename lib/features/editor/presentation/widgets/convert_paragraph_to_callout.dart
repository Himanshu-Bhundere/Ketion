import 'package:super_editor/super_editor.dart';
import 'ketion_callout_node.dart';

import 'ketion_edit_requests.dart';

/// Explicit request to convert a text node
/// into a [KetionCalloutNode].
class ConvertToCalloutRequest with HandlesSlashDeletion implements EditRequest {
  const ConvertToCalloutRequest({
    required this.nodeId,
    this.icon = '💡',
    this.color = 'grey',
    this.slashStartIndex,
    this.slashEndIndex,
  });

  final String nodeId;
  final String icon;
  final String color;
  @override
  final int? slashStartIndex;
  @override
  final int? slashEndIndex;
}

/// Command that replaces a [TextNode] with a [KetionCalloutNode],
/// preserving text content, metadata, and node identity.
class ConvertToCalloutCommand implements EditCommand {
  const ConvertToCalloutCommand(this.request);

  final ConvertToCalloutRequest request;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  String describe() => 'Convert Paragraph to Callout';

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(request.nodeId);
    if (node is! TextNode) return;

    AttributedText newText = node.text;

    if (request.slashStartIndex != null && request.slashEndIndex != null) {
      final textLength = newText.toPlainText().length;
      final safeStart = request.slashStartIndex!.clamp(0, textLength);
      final safeEnd = request.slashEndIndex!.clamp(0, textLength);
      if (safeEnd > safeStart) {
        newText = newText.removeRegion(startOffset: safeStart, endOffset: safeEnd);
      }
    }

    document.replaceNodeById(
      node.id,
      KetionCalloutNode(
        id: node.id,
        text: newText,
        metadata: node.metadata,
        icon: request.icon,
        color: request.color,
      ),
    );

    if (request.slashStartIndex != null && request.slashEndIndex != null) {
      final textLength = newText.toPlainText().length;
      final safeStart = request.slashStartIndex!.clamp(0, textLength);
      executor.executeCommand(
        ChangeSelectionCommand(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: node.id,
              nodePosition: TextNodePosition(offset: safeStart),
            ),
          ),
          SelectionChangeType.placeCaret,
          SelectionReason.userInteraction,
        ),
      );
    }

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

class ConvertCalloutToParagraphRequest implements EditRequest {
  const ConvertCalloutToParagraphRequest({
    required this.nodeId,
  });

  final String nodeId;
}

class ConvertCalloutToParagraphCommand implements EditCommand {
  const ConvertCalloutToParagraphCommand(this.request);

  final ConvertCalloutToParagraphRequest request;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  String describe() => 'Convert Callout to Paragraph';

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(request.nodeId);
    if (node is! KetionCalloutNode) return;

    document.replaceNodeById(
      node.id,
      ParagraphNode(
        id: node.id,
        text: node.text,
        metadata: node.metadata,
      ),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

class SplitCalloutRequest implements EditRequest {
  const SplitCalloutRequest({
    required this.nodeId,
    required this.newNodeId,
  });

  final String nodeId;
  final String newNodeId;
}

class SplitCalloutCommand implements EditCommand {
  const SplitCalloutCommand(this.request);

  final SplitCalloutRequest request;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  String describe() => 'Split Callout';

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(request.nodeId);
    if (node is! KetionCalloutNode) return;

    final selection = context.composer.selection;
    if (selection == null || !selection.isCollapsed || selection.extent.nodeId != node.id) {
      return;
    }

    final position = selection.extent.nodePosition;
    if (position is! TextNodePosition) return;

    final textBefore = node.text.copyText(0, position.offset);
    final textAfter = node.text.copyText(position.offset);

    // Create new nodes
    final newCalloutNode = KetionCalloutNode(
      id: node.id,
      text: textBefore,
      icon: node.icon,
      color: node.color,
      metadata: node.metadata,
    );

    final newNode = ParagraphNode(
      id: request.newNodeId,
      text: textAfter,
    );
    
    document.replaceNodeById(node.id, newCalloutNode);
    document.insertNodeAfter(existingNodeId: node.id, newNode: newNode);

    // Note: Caret selection change is handled by the caller or by a separate command.
    executor.logChanges([
      DocumentEdit(NodeChangeEvent(node.id)),
      DocumentEdit(NodeInsertedEvent(newNode.id, document.getNodeIndexById(newNode.id))),
    ]);
  }
}
