import 'package:super_editor/super_editor.dart';
import '../../domain/models/block_data_models.dart';
import 'ketion_table_node.dart';

class UpdateTableCommand extends EditCommand {
  final String nodeId;
  final Map<String, dynamic> newMetadata;

  const UpdateTableCommand({
    required this.nodeId,
    required this.newMetadata,
  });

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(nodeId);
    
    if (node is! KetionTableNode) {
      return;
    }

    final updatedMetadata = Map<String, dynamic>.from(node.metadata);
    for (final entry in newMetadata.entries) {
      updatedMetadata[entry.key] = entry.value;
    }

    document.replaceNodeById(
      node.id,
      node.copyAndReplaceMetadata(updatedMetadata),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

class UpdateTableCellCommand extends EditCommand {
  final String nodeId;
  final int rowIndex;
  final int colIndex;
  final String text;

  const UpdateTableCellCommand({
    required this.nodeId,
    required this.rowIndex,
    required this.colIndex,
    required this.text,
  });

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(nodeId);
    
    if (node is! KetionTableNode) {
      return;
    }

    List<TableRowData> rows = List.from(node.rows);
    final columnCount = node.metadata['columnCount'] as int? ?? 2;

    if (rowIndex < 0 || rowIndex >= rows.length) return;
    if (colIndex < 0 || colIndex >= columnCount) return;

    final cell = rows[rowIndex].cells[colIndex];
    final updatedCell = cell.copyWith(
      spans: [TextSpanData(text: text)],
    );

    final newCells = List<TableCellData>.from(rows[rowIndex].cells);
    newCells[colIndex] = updatedCell;

    final newRow = rows[rowIndex].copyWith(cells: newCells);
    rows[rowIndex] = newRow;

    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'rows': rows.map((r) => r.toJson()).toList(),
      }),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

class AddTableRowCommand extends EditCommand {
  final String nodeId;
  final int afterRowIndex; // Use -1 to insert at the beginning

  const AddTableRowCommand({
    required this.nodeId,
    required this.afterRowIndex,
  });

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(nodeId);
    
    if (node is! KetionTableNode) {
      return;
    }

    List<TableRowData> rows = List.from(node.rows);
    final columnCount = node.metadata['columnCount'] as int? ?? 2;

    final newRow = TableRowData(
      id: Editor.createNodeId(),
      cells: List.generate(columnCount, (_) => TableCellData(id: Editor.createNodeId(), spans: [])),
    );

    int insertIndex = afterRowIndex + 1;
    if (insertIndex < 0) insertIndex = 0;
    if (insertIndex > rows.length) insertIndex = rows.length;

    rows.insert(insertIndex, newRow);
    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'rows': rows.map((r) => r.toJson()).toList(),
      }),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

class DeleteTableRowCommand extends EditCommand {
  final String nodeId;
  final int rowIndex;

  const DeleteTableRowCommand({
    required this.nodeId,
    required this.rowIndex,
  });

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(nodeId);
    
    if (node is! KetionTableNode) {
      return;
    }

    List<TableRowData> rows = List.from(node.rows);

    if (rowIndex < 0 || rowIndex >= rows.length) return;

    rows.removeAt(rowIndex);
    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'rows': rows.map((r) => r.toJson()).toList(),
      }),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

class AddTableColumnCommand extends EditCommand {
  final String nodeId;
  final int afterColIndex;

  const AddTableColumnCommand({
    required this.nodeId,
    required this.afterColIndex,
  });

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(nodeId);
    
    if (node is! KetionTableNode) {
      return;
    }

    List<TableRowData> rows = List.from(node.rows);
    final columnCount = node.metadata['columnCount'] as int? ?? 2;

    int insertIndex = afterColIndex + 1;
    if (insertIndex < 0) insertIndex = 0;
    if (insertIndex > columnCount) insertIndex = columnCount;

    for (int i = 0; i < rows.length; i++) {
      final newCells = List<TableCellData>.from(rows[i].cells);
      newCells.insert(insertIndex, TableCellData(id: Editor.createNodeId(), spans: []));
      rows[i] = rows[i].copyWith(cells: newCells);
    }

    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'columnCount': columnCount + 1,
        'rows': rows.map((r) => r.toJson()).toList(),
      }),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

class DeleteTableColumnCommand extends EditCommand {
  final String nodeId;
  final int colIndex;

  const DeleteTableColumnCommand({
    required this.nodeId,
    required this.colIndex,
  });

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(nodeId);
    
    if (node is! KetionTableNode) {
      return;
    }

    List<TableRowData> rows = List.from(node.rows);
    final columnCount = node.metadata['columnCount'] as int? ?? 2;

    if (colIndex < 0 || colIndex >= columnCount) return;

    for (int i = 0; i < rows.length; i++) {
      final newCells = List<TableCellData>.from(rows[i].cells);
      newCells.removeAt(colIndex);
      rows[i] = rows[i].copyWith(cells: newCells);
    }

    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'columnCount': columnCount - 1,
        'rows': rows.map((r) => r.toJson()).toList(),
      }),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}
