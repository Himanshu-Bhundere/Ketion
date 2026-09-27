import 'package:ketion/features/editor/domain/models/block_data_models.dart';

class InvalidTableStateException implements Exception {
  final String message;
  const InvalidTableStateException(this.message);

  @override
  String toString() => 'InvalidTableStateException: $message';
}

class TableStateValidator {
  static void validate(List<TableRowData> rows, int columnCount) {
    if (rows.isEmpty) {
      throw const InvalidTableStateException('Table must have at least 1 row');
    }
    if (columnCount < 1) {
      throw const InvalidTableStateException(
          'Table must have at least 1 column',);
    }

    final rowIds = <String>{};
    final cellIds = <String>{};

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (!rowIds.add(row.id)) {
        throw InvalidTableStateException('Duplicate row id: ${row.id}');
      }
      if (row.cells.length != columnCount) {
        throw InvalidTableStateException(
          'Row ${row.id} has ${row.cells.length} cells, expected $columnCount',
        );
      }
      for (var cell in row.cells) {
        if (!cellIds.add(cell.id)) {
          throw InvalidTableStateException('Duplicate cell id: ${cell.id}');
        }
      }
    }
  }

  static void validateDeletion(List<TableRowData> rows, int columnCount,
      {bool isRow = true,}) {
    validate(rows, columnCount);
    if (isRow && rows.length <= 1) {
      throw const InvalidTableStateException('Cannot delete the last row');
    }
    if (!isRow && columnCount <= 1) {
      throw const InvalidTableStateException('Cannot delete the last column');
    }
  }
}
