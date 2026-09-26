import 'package:super_editor/super_editor.dart';
import '../../domain/models/block_data_models.dart';
import '../../domain/services/table_state_transformer.dart';

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
        'rows': rows,
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

    final columnCount = node.metadata['columnCount'] as int? ?? 2;
    
    final newRows = TableStateTransformer.insertRow(node.rows, columnCount, afterRowIndex + 1);

    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'rows': newRows,
      }),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

class DuplicateTableRowCommand extends EditCommand {
  final String nodeId;
  final int rowIndex;

  const DuplicateTableRowCommand({
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

    final columnCount = node.metadata['columnCount'] as int? ?? 2;
    
    final newRows = TableStateTransformer.duplicateRow(node.rows, columnCount, rowIndex);

    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'rows': newRows,
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

    final columnCount = node.metadata['columnCount'] as int? ?? 2;
    final newRows = TableStateTransformer.deleteRow(node.rows, columnCount, rowIndex);

    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'rows': newRows,
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

    final columnCount = node.metadata['columnCount'] as int? ?? 2;
    final newRows = TableStateTransformer.insertColumn(node.rows, columnCount, afterColIndex + 1);
    final newColumnCount = columnCount + 1;

    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'columnCount': newColumnCount,
        'rows': newRows,
      }),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

class DuplicateTableColumnCommand extends EditCommand {
  final String nodeId;
  final int colIndex;

  const DuplicateTableColumnCommand({
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

    final columnCount = node.metadata['columnCount'] as int? ?? 2;
    final newRows = TableStateTransformer.duplicateColumn(node.rows, columnCount, colIndex);
    final newColumnCount = columnCount + 1;

    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'columnCount': newColumnCount,
        'rows': newRows,
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

    final columnCount = node.metadata['columnCount'] as int? ?? 2;
    final newRows = TableStateTransformer.deleteColumn(node.rows, columnCount, colIndex);
    final newColumnCount = columnCount - 1;

    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'columnCount': newColumnCount,
        'rows': newRows,
      }),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

class ReorderTableRowCommand extends EditCommand {
  final String nodeId;
  final String draggedRowId;
  final String targetRowId;

  const ReorderTableRowCommand({
    required this.nodeId,
    required this.draggedRowId,
    required this.targetRowId,
  });

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(nodeId);
    
    if (node is! KetionTableNode) {
      return;
    }

    final columnCount = node.metadata['columnCount'] as int? ?? 2;
    final newRows = TableStateTransformer.reorderRowById(node.rows, columnCount, draggedRowId, targetRowId);

    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'rows': newRows,
      }),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}

class ReorderTableColumnCommand extends EditCommand {
  final String nodeId;
  final int draggedColumnIndex;
  final int targetColumnIndex;

  const ReorderTableColumnCommand({
    required this.nodeId,
    required this.draggedColumnIndex,
    required this.targetColumnIndex,
  });

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(nodeId);
    
    if (node is! KetionTableNode) {
      return;
    }

    final columnCount = node.metadata['columnCount'] as int? ?? 2;
    
    final newRows = TableStateTransformer.reorderColumnByIndex(node.rows, columnCount, draggedColumnIndex, targetColumnIndex);

    document.replaceNodeById(
      node.id,
      node.copyWithAddedMetadata({
        'rows': newRows,
      }),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(node.id),
      ),
    ]);
  }
}
