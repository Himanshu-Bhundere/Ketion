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
