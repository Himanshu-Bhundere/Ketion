import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import 'ketion_table_commands.dart';
import '../widgets/ketion_edit_requests.dart';
import 'ketion_table_node.dart';
import '../../domain/models/block_data_models.dart';

class KetionTableComponentViewModel extends SingleColumnLayoutComponentViewModel {
  final int columnCount;
  final List<TableRowData> rows;

  KetionTableComponentViewModel({
    required super.nodeId,
    super.maxWidth,
    required super.padding,
    super.createdAt,
    required this.columnCount,
    required this.rows,
  });

  @override
  KetionTableComponentViewModel copy() {
    return KetionTableComponentViewModel(
      nodeId: nodeId,
      maxWidth: maxWidth,
      padding: padding,
      createdAt: createdAt,
      columnCount: columnCount,
      rows: rows,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is KetionTableComponentViewModel &&
      super == other &&
      other.nodeId == nodeId &&
      other.columnCount == columnCount &&
      _rowsEqual(other.rows, rows);
  }

  bool _rowsEqual(List<TableRowData> list1, List<TableRowData> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => nodeId.hashCode ^ columnCount.hashCode ^ Object.hashAll(rows);
}

class KetionTableComponentBuilder implements ComponentBuilder {
  final Editor editor;

  const KetionTableComponentBuilder(this.editor);

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! KetionTableNode) return null;
    
    final columnCount = node.metadata['columnCount'] as int? ?? 2;
    final rowsList = node.metadata['rows'] as List<dynamic>? ?? [];
    
    List<TableRowData> rows = [];
    try {
      rows = rowsList
          .map((e) => TableRowData.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error parsing table rows: $e');
    }
    
    return KetionTableComponentViewModel(
      nodeId: node.id,
      maxWidth: double.infinity,
      padding: EdgeInsets.zero,
      createdAt: node.metadata['createdAt'] as DateTime?,
      columnCount: columnCount,
      rows: rows,
    );
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! KetionTableComponentViewModel) return null;
    return BoxComponent(
      key: componentContext.componentKey,
      child: KetionTableComponent(
        viewModel: componentViewModel,
        editor: editor,
      ),
    );
  }
}

class KetionTableComponent extends StatefulWidget {
  final KetionTableComponentViewModel viewModel;
  final Editor editor;

  const KetionTableComponent({
    super.key, 
    required this.viewModel,
    required this.editor,
  });

  @override
  State<KetionTableComponent> createState() => _KetionTableComponentState();
}

class _KetionTableComponentState extends State<KetionTableComponent> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  Timer? _debounceTimer;
  final Map<String, String> _localCellState = {};

  void _commitLocalState() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (_localCellState.isEmpty) return;

    final currentRows = widget.viewModel.rows;
    final updatedRows = <TableRowData>[];
    bool hasValidUpdates = false;

    for (final row in currentRows) {
      final updatedCells = <TableCellData>[];
      for (final cell in row.cells) {
        final pendingText = _localCellState[cell.id];
        if (pendingText != null) {
          updatedCells.add(cell.copyWith(
            spans: [TextSpanData(text: pendingText)],
          ),);
          hasValidUpdates = true;
        } else {
          updatedCells.add(cell);
        }
      }
      updatedRows.add(row.copyWith(cells: updatedCells));
    }

    _localCellState.clear();
    
    if (!hasValidUpdates) return;

    widget.editor.execute([
      UpdateTableRequest(
        nodeId: widget.viewModel.nodeId,
        innerCommand: UpdateTableCommand(
          nodeId: widget.viewModel.nodeId,
          newMetadata: {
            'rows': updatedRows.map((r) => r.toJson()).toList(),
          },
        ),
      ),
    ]);
  }

  void _flushPendingCommit() {
    _commitLocalState();
  }

  @override
  void didUpdateWidget(KetionTableComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var row in widget.viewModel.rows) {
      for (var cell in row.cells) {
        if (_controllers.containsKey(cell.id)) {
          if (_localCellState.containsKey(cell.id)) continue;
          final controller = _controllers[cell.id]!;
          final focusNode = _focusNodes[cell.id];
          if (focusNode != null && !focusNode.hasFocus) {
            final cellText = cell.spans.map((s) => s.text).join('');
            if (controller.text != cellText) {
              controller.text = cellText;
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _flushPendingCommit();
    for (var c in _controllers.values) {
      c.dispose();
    }
    for (var f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String cellId, String initialText) {
    if (!_controllers.containsKey(cellId)) {
      _controllers[cellId] = TextEditingController(text: initialText);
    }
    return _controllers[cellId]!;
  }

  FocusNode _getFocusNode(String cellId) {
    if (!_focusNodes.containsKey(cellId)) {
      final fn = FocusNode();
      _focusNodes[cellId] = fn;
    }
    return _focusNodes[cellId]!;
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.viewModel.rows;
    final columnCount = widget.viewModel.columnCount;
    
    if (rows.isEmpty || columnCount <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: Text('Empty Table', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double minColumnWidth = 150.0;
    
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = math.max(
                  constraints.maxWidth,
                  columnCount * minColumnWidth,
                );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                      ),
                      columnWidths: {
                        for (var i = 0; i < columnCount; i++) i: const FlexColumnWidth(),
                      },
                      children: rows.map((row) {
                        return TableRow(
                          children: List.generate(columnCount, (index) {
                            final cell = index < row.cells.length ? row.cells[index] : null;
                            final text = cell?.spans.map((s) => s.text).join('') ?? '';
                            final cellId = cell?.id ?? 'temp_cell_${row.id}_$index';
                            
                            return TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: cell != null
                                    ? TextField(
                                        controller: _getController(cellId, text),
                                        focusNode: _getFocusNode(cellId),
                                        maxLines: null,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                        onChanged: (value) {
                                          _localCellState[cellId] = value;
                                          _debounceTimer?.cancel();
                                          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                                            _commitLocalState();
                                          });
                                        },
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text(text, style: const TextStyle(fontSize: 14)),
                                      ),
                              ),
                            );
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  _flushPendingCommit();
                  widget.editor.execute([
                    UpdateTableRequest(
                      nodeId: widget.viewModel.nodeId,
                      innerCommand: AddTableRowCommand(
                        nodeId: widget.viewModel.nodeId,
                        afterRowIndex: rows.length - 1,
                      ),
                    ),
                  ]);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Row'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  _flushPendingCommit();
                  widget.editor.execute([
                    UpdateTableRequest(
                      nodeId: widget.viewModel.nodeId,
                      innerCommand: AddTableColumnCommand(
                        nodeId: widget.viewModel.nodeId,
                        afterColIndex: columnCount - 1,
                      ),
                    ),
                  ]);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Column'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
