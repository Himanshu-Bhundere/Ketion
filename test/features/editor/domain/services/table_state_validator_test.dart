import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/editor/domain/services/table_state_validator.dart';
import 'package:ketion/features/editor/domain/models/block_data_models.dart';

void main() {
  group('TableStateValidator', () {
    test('validate throws InvalidTableStateException for < 1 row', () {
      expect(
        () => TableStateValidator.validate([], 2),
        throwsA(isA<InvalidTableStateException>().having((e) => e.message, 'message', 'Table must have at least 1 row')),
      );
    });

    test('validate throws InvalidTableStateException for < 1 column', () {
      expect(
        () => TableStateValidator.validate([const TableRowData(id: 'r1', cells: [])], 0),
        throwsA(isA<InvalidTableStateException>().having((e) => e.message, 'message', 'Table must have at least 1 column')),
      );
    });

    test('validate succeeds for valid dimensions', () {
      expect(() => TableStateValidator.validate([const TableRowData(id: 'r1', cells: [TableCellData(id: 'c1', spans: [])])], 1), returnsNormally);
    });

    test('validate throws InvalidTableStateException for mismatched column counts', () {
      final rows = [
        const TableRowData(id: 'r1', cells: [TableCellData(id: 'c1', spans: [])]),
        const TableRowData(id: 'r2', cells: [TableCellData(id: 'c2', spans: []), TableCellData(id: 'c3', spans: [])]),
      ];
      
      expect(
        () => TableStateValidator.validate(rows, 1),
        throwsA(isA<InvalidTableStateException>().having((e) => e.message, 'message', 'Row r2 has 2 cells, expected 1')),
      );
    });

    test('validate throws InvalidTableStateException for duplicate row IDs', () {
      final rows = [
        const TableRowData(id: 'r1', cells: [TableCellData(id: 'c1', spans: [])]),
        const TableRowData(id: 'r1', cells: [TableCellData(id: 'c2', spans: [])]),
      ];
      
      expect(
        () => TableStateValidator.validate(rows, 1),
        throwsA(isA<InvalidTableStateException>().having((e) => e.message, 'message', 'Duplicate row id: r1')),
      );
    });

    test('validate throws InvalidTableStateException for duplicate cell IDs', () {
      final rows = [
        const TableRowData(id: 'r1', cells: [TableCellData(id: 'c1', spans: []), TableCellData(id: 'c2', spans: [])]),
        const TableRowData(id: 'r2', cells: [TableCellData(id: 'c3', spans: []), TableCellData(id: 'c1', spans: [])]),
      ];
      
      expect(
        () => TableStateValidator.validate(rows, 2),
        throwsA(isA<InvalidTableStateException>().having((e) => e.message, 'message', 'Duplicate cell id: c1')),
      );
    });

    test('validate succeeds for unique IDs', () {
      final rows = [
        const TableRowData(id: 'r1', cells: [TableCellData(id: 'c1', spans: []), TableCellData(id: 'c2', spans: [])]),
        const TableRowData(id: 'r2', cells: [TableCellData(id: 'c3', spans: []), TableCellData(id: 'c4', spans: [])]),
      ];
      
      expect(() => TableStateValidator.validate(rows, 2), returnsNormally);
    });
  });
}
