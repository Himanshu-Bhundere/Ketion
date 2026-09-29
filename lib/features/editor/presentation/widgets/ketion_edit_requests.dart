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

class UpdateTableRequest implements EditRequest {
  final String nodeId;
  final EditCommand innerCommand;

  UpdateTableRequest({
    required this.nodeId,
    required this.innerCommand,
  });
}
