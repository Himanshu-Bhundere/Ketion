import 'package:ketion/features/editor/domain/models/block_data_models.dart';
import 'package:ketion/features/editor/domain/services/table_state_validator.dart';
import 'package:uuid/uuid.dart';

class TableStateTransformer {
  static const Uuid _uuid = Uuid();

  static List<TableRowData> insertRow(List<TableRowData> rows, int columnCount, int targetIndex) {
    TableStateValidator.validate(rows, columnCount);
    
    final newCells = List.generate(
      columnCount, 
      (_) => TableCellData(id: _uuid.v4(), spans: []),
    );
    final newRow = TableRowData(id: _uuid.v4(), cells: newCells);
    
    final updatedRows = List<TableRowData>.from(rows);
    updatedRows.insert(targetIndex.clamp(0, updatedRows.length), newRow);
    return updatedRows;
  }

  static List<TableRowData> deleteRow(List<TableRowData> rows, int columnCount, int rowIndex) {
    TableStateValidator.validateDeletion(rows, columnCount, isRow: true);
    if (rowIndex < 0 || rowIndex >= rows.length) return rows;
    
    final updatedRows = List<TableRowData>.from(rows);
    updatedRows.removeAt(rowIndex);
    return updatedRows;
  }

  static List<TableRowData> insertColumn(List<TableRowData> rows, int columnCount, int targetIndex) {
    TableStateValidator.validate(rows, columnCount);
    
    final updatedRows = rows.map((row) {
      final updatedCells = List<TableCellData>.from(row.cells);
      updatedCells.insert(
        targetIndex.clamp(0, updatedCells.length), 
        TableCellData(id: _uuid.v4(), spans: []),
      );
      return row.copyWith(cells: updatedCells);
    }).toList();
    return updatedRows;
  }

  static List<TableRowData> deleteColumn(List<TableRowData> rows, int columnCount, int colIndex) {
    TableStateValidator.validateDeletion(rows, columnCount, isRow: false);
    if (colIndex < 0 || colIndex >= columnCount) return rows;
    
    final updatedRows = rows.map((row) {
      final updatedCells = List<TableCellData>.from(row.cells);
      updatedCells.removeAt(colIndex);
      return row.copyWith(cells: updatedCells);
    }).toList();
    return updatedRows;
  }

  static List<TableRowData> duplicateRow(List<TableRowData> rows, int columnCount, int rowIndex) {
    TableStateValidator.validate(rows, columnCount);
    if (rowIndex < 0 || rowIndex >= rows.length) return rows;

    final sourceRow = rows[rowIndex];
    final newCells = sourceRow.cells.map((c) => c.copyWith(id: _uuid.v4())).toList();
    final newRow = TableRowData(id: _uuid.v4(), cells: newCells);

    final updatedRows = List<TableRowData>.from(rows);
    updatedRows.insert(rowIndex + 1, newRow);
    return updatedRows;
  }

  static List<TableRowData> duplicateColumn(List<TableRowData> rows, int columnCount, int colIndex) {
    TableStateValidator.validate(rows, columnCount);
    if (colIndex < 0 || colIndex >= columnCount) return rows;

    final updatedRows = rows.map((row) {
      final updatedCells = List<TableCellData>.from(row.cells);
      final sourceCell = updatedCells[colIndex];
      updatedCells.insert(colIndex + 1, sourceCell.copyWith(id: _uuid.v4()));
      return row.copyWith(cells: updatedCells);
    }).toList();
    return updatedRows;
  }

  static List<TableRowData> reorderRow(List<TableRowData> rows, int columnCount, int oldIndex, int targetIndex) {
    TableStateValidator.validate(rows, columnCount);
    if (oldIndex < 0 || oldIndex >= rows.length || oldIndex == targetIndex) return rows;

    final updatedRows = List<TableRowData>.from(rows);
    final row = updatedRows.removeAt(oldIndex);
    updatedRows.insert(targetIndex, row);
    return updatedRows;
  }

  static List<TableRowData> reorderColumn(List<TableRowData> rows, int columnCount, int oldIndex, int targetIndex) {
    TableStateValidator.validate(rows, columnCount);
    if (oldIndex < 0 || oldIndex >= columnCount || oldIndex == targetIndex) return rows;

    final updatedRows = rows.map((row) {
      final updatedCells = List<TableCellData>.from(row.cells);
      final cell = updatedCells.removeAt(oldIndex);
      updatedCells.insert(targetIndex, cell);
      return row.copyWith(cells: updatedCells);
    }).toList();
    
    return updatedRows;
  }
}
