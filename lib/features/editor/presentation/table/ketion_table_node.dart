import 'package:super_editor/super_editor.dart';
import '../../domain/models/block_data_models.dart';

class KetionTableNode extends BlockNode {
  KetionTableNode({
    required this.id,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  @override
  final String id;
  @override
  final Map<String, dynamic> metadata;

  int get columnCount => metadata['columnCount'] as int? ?? 0;
  
  late final List<TableRowData> rows = _initRows();

  List<TableRowData> _initRows() {
    final rawRows = metadata['rows'];
    if (rawRows is List<TableRowData>) return rawRows;
    final rowsList = rawRows as List<dynamic>? ?? [];
    return rowsList
        .map((e) => TableRowData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  bool hasEquivalentContent(DocumentNode other) {
    if (other is! KetionTableNode) {
      return false;
    }
    
    return columnCount == other.columnCount && 
           _rowsEqual(rows, other.rows);
  }

  bool _rowsEqual(List<TableRowData> a, List<TableRowData> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  BlockNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return KetionTableNode(
      id: id,
      metadata: newMetadata,
    );
  }

  @override
  BlockNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    return KetionTableNode(
      id: id,
      metadata: {
        ...metadata,
        ...newProperties,
      },
    );
  }

  @override
  String? copyContent(NodeSelection selection) {
    return null;
  }
}
