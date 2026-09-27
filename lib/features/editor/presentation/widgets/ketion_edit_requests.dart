import 'package:super_editor/super_editor.dart';

class SlashCommandTarget {
  final String nodeId;
  final int slashStartIndex;
  final int slashEndIndex;

  SlashCommandTarget({
    required this.nodeId,
    required this.slashStartIndex,
    required this.slashEndIndex,
  });
}

mixin HandlesSlashDeletion {
  int? get slashStartIndex => null;
  int? get slashEndIndex => null;
}

class ConvertSlashCommandRequest implements EditRequest {
  final SlashCommandTarget target;
  final EditRequest innerRequest;

  ConvertSlashCommandRequest({
    required this.target,
    required this.innerRequest,
  });
}

/// A request to execute an EditCommand directly.
class ExecuteCommandRequest implements EditRequest {
  final EditCommand command;

  ExecuteCommandRequest(this.command);
}

class ToggleExpandedRequest implements EditRequest {
  final String nodeId;
  final bool isExpanded;

  ToggleExpandedRequest({
    required this.nodeId,
    required this.isExpanded,
  });
}

class UpdateReminderRequest implements EditRequest {
  final String nodeId;
  final String title;
  final String dueAt;
  final bool completed;

  UpdateReminderRequest({
    required this.nodeId,
    required this.title,
    required this.dueAt,
    this.completed = false,
  });
}

class ReplaceSlashParagraphWithBlockRequest implements EditRequest {
  final String existingNodeId;
  final DocumentNode newNode;

  ReplaceSlashParagraphWithBlockRequest({
    required this.existingNodeId,
    required this.newNode,
  });
}

class ReplaceSlashParagraphWithBlockCommand implements EditCommand {
  final ReplaceSlashParagraphWithBlockRequest request;

  ReplaceSlashParagraphWithBlockCommand(this.request);

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  String describe() => 'Replace Slash Paragraph With Block';

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final existingNode = document.getNodeById(request.existingNodeId);
    if (existingNode == null) return;
    
    // Insert new node after existing node
    executor.executeCommand(InsertNodeAfterNodeCommand(existingNodeId: request.existingNodeId, newNode: request.newNode));
    
    // Insert an empty paragraph after the new node so the caret has a place to go
    final emptyParagraph = ParagraphNode(id: Editor.createNodeId(), text: AttributedText());
    executor.executeCommand(InsertNodeAfterNodeCommand(existingNodeId: request.newNode.id, newNode: emptyParagraph));

    // Delete the original slash command paragraph
    executor.executeCommand(DeleteNodeCommand(nodeId: request.existingNodeId));

    // Set selection to the new empty paragraph
    executor.executeCommand(
      ChangeSelectionCommand(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: emptyParagraph.id,
            nodePosition: emptyParagraph.beginningPosition,
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    );
  }
}


class UpdateTableRequest implements EditRequest {
  final String nodeId;
  final EditCommand innerCommand;

  UpdateTableRequest({
    required this.nodeId,
    required this.innerCommand,
  });
}
