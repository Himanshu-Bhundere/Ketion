import 'package:super_editor/super_editor.dart';

class ChangeParagraphMetadataRequest implements EditRequest {
  const ChangeParagraphMetadataRequest({
    required this.nodeId,
    required this.metadata,
  });

  final String nodeId;
  final Map<String, dynamic> metadata;
}

class ChangeParagraphMetadataCommand extends EditCommand {
  ChangeParagraphMetadataCommand(this.request);

  final ChangeParagraphMetadataRequest request;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(request.nodeId);
    
    if (node is ParagraphNode) {
      document.replaceNodeById(
        node.id,
        ParagraphNode(
          id: node.id,
          text: node.text,
          metadata: request.metadata,
        ),
      );
      
      executor.logChanges([
        DocumentEdit(
          NodeChangeEvent(node.id),
        ),
      ]);
    }
  }
}

EditCommand? changeParagraphMetadataRequestHandler(Editor editor, EditRequest request) {
  if (request is ChangeParagraphMetadataRequest) {
    return ChangeParagraphMetadataCommand(request);
  }
  return null;
}
