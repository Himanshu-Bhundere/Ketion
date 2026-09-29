import 'package:super_editor/super_editor.dart';

class InsertReminderRequest implements EditRequest {
  final String nodeId;

  InsertReminderRequest({
    required this.nodeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsertReminderRequest &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId;

  @override
  int get hashCode => nodeId.hashCode;
}
