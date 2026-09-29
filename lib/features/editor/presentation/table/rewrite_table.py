import os

content = """import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ScrollController _horizontalScrollController = ScrollController();
  Timer? _debounceTimer;
  final Map<String, String> _localCellState = {};

  // Table Interaction State
  String? _hoveredRowId;
  int? _hoveredColIndex;
  
  // Drag State
  String? _draggingRowId;
  int? _draggingColIndex;
  
  int? _dropTargetRowIndex;
  int? _dropTargetColIndex;

  @override
  void didUpdateWidget(KetionTableComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final validCellIds = <String>{};
    for (var row in widget.viewModel.rows) {
      for (var cell in row.cells) {
        validCellIds.add(cell.id);
      }
    }
    
    final keysToRemove = <String>[];
    for (var key in _controllers.keys) {
      if (!validCellIds.contains(key)) {
        keysToRemove.add(key);
      }
    }
    
    for (var key in keysToRemove) {
      _controllers.remove(key)?.dispose();
      _focusNodes.remove(key)?.dispose();
      _localCellState.remove(key);
    }
    
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
    _horizontalScrollController.dispose();
    super.dispose();
  }

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
          ));
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

  TextEditingController _getController(String cellId, String initialText) {
    if (!_controllers.containsKey(cellId)) {
      _controllers[cellId] = TextEditingController(text: initialText);
    }
    return _controllers[cellId]!;
  }

  FocusNode _getFocusNode(String cellId) {
    if (!_focusNodes.containsKey(cellId)) {
      final fn = FocusNode();
      fn.addListener(() {
        if (fn.hasFocus) {
           _ensureCellVisible(cellId);
        }
      });
      _focusNodes[cellId] = fn;
    }
    return _focusNodes[cellId]!;
  }

  void _ensureCellVisible(String cellId) {
    // A simplified auto-scroll approach. For production, measuring the exact 
    // RenderBox of the cell is better, but doing a slight scroll jump or 
    // letting Flutter's Scrollable.ensureVisible handle it usually works.
    final context = _focusNodes[cellId]?.context;
    if (context != null) {
      Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 200));
    }
  }
  
  void _executeReorderRow(int oldIndex, int targetIndex) {
    if (oldIndex == targetIndex || oldIndex + 1 == targetIndex) return;
    int finalTarget = targetIndex;
    if (oldIndex < targetIndex) {
      finalTarget -= 1;
    }
    widget.editor.execute([
      UpdateTableRequest(
        nodeId: widget.viewModel.nodeId,
        innerCommand: ReorderTableRowCommand(
          nodeId: widget.viewModel.nodeId,
          oldIndex: oldIndex,
          targetIndex: finalTarget,
        ),
      )
    ]);
  }

  void _executeReorderCol(int oldIndex, int targetIndex) {
    if (oldIndex == targetIndex || oldIndex + 1 == targetIndex) return;
    int finalTarget = targetIndex;
    if (oldIndex < targetIndex) {
      finalTarget -= 1;
    }
    widget.editor.execute([
      UpdateTableRequest(
        nodeId: widget.viewModel.nodeId,
        innerCommand: ReorderTableColumnCommand(
          nodeId: widget.viewModel.nodeId,
          oldIndex: oldIndex,
          targetIndex: finalTarget,
        ),
      )
    ]);
  }
  
  void _handleMenuAction(String action, int? rowIndex, int? colIndex) {
    _flushPendingCommit();
    final rows = widget.viewModel.rows;
    final columnCount = widget.viewModel.columnCount;
    
    switch (action) {
      case 'insert_row_above':
        if (rowIndex != null) {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: AddTableRowCommand(
                nodeId: widget.viewModel.nodeId,
                afterRowIndex: rowIndex - 1,
              ),
            ),
          ]);
        }
        break;
      case 'insert_row_below':
        if (rowIndex != null) {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: AddTableRowCommand(
                nodeId: widget.viewModel.nodeId,
                afterRowIndex: rowIndex,
              ),
            ),
          ]);
        }
        break;
      case 'delete_row':
        if (rowIndex != null && rows.length > 1) {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: DeleteTableRowCommand(
                nodeId: widget.viewModel.nodeId,
                rowIndex: rowIndex,
              ),
            ),
          ]);
        }
        break;
      case 'insert_col_left':
        if (colIndex != null) {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: AddTableColumnCommand(
                nodeId: widget.viewModel.nodeId,
                afterColIndex: colIndex - 1,
              ),
            ),
          ]);
        }
        break;
      case 'insert_col_right':
        if (colIndex != null) {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: AddTableColumnCommand(
                nodeId: widget.viewModel.nodeId,
                afterColIndex: colIndex,
              ),
            ),
          ]);
        }
        break;
      case 'delete_col':
        if (colIndex != null && columnCount > 1) {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: DeleteTableColumnCommand(
                nodeId: widget.viewModel.nodeId,
                colIndex: colIndex,
              ),
            ),
          ]);
        }
        break;
    }
  }
  
  Widget _buildRowHandle(int rowIndex, String rowId) {
    final canDelete = widget.viewModel.rows.length > 1;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowId = rowId),
      onExit: (_) => setState(() => _hoveredRowId = null),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) {
           setState(() {
             _dropTargetRowIndex = null;
           });
           _executeReorderRow(details.data, rowIndex);
        },
        onMove: (details) {
           if (_dropTargetRowIndex != rowIndex) {
             setState(() {
                _dropTargetRowIndex = rowIndex;
             });
           }
        },
        onLeave: (data) {
           setState(() {
              _dropTargetRowIndex = null;
           });
        },
        builder: (context, candidateData, rejectedData) {
          final isHovered = _hoveredRowId == rowId || _draggingRowId == rowId;
          return Container(
            width: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: _dropTargetRowIndex == rowIndex ? const Border(top: BorderSide(color: Colors.blue, width: 2)) : null,
            ),
            child: isHovered ? PopupMenuButton<String>(
              icon: const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
              padding: EdgeInsets.zero,
              onSelected: (action) => _handleMenuAction(action, rowIndex, null),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'insert_row_above', child: Text('Insert row above')),
                const PopupMenuItem(value: 'insert_row_below', child: Text('Insert row below')),
                PopupMenuItem(value: 'delete_row', enabled: canDelete, child: Text('Delete row', style: TextStyle(color: canDelete ? Colors.red : Colors.grey))),
              ],
              child: LongPressDraggable<int>(
                data: rowIndex,
                feedback: Material(
                  elevation: 4,
                  child: Container(
                    width: 200, 
                    height: 40, 
                    color: Colors.blue.withOpacity(0.1),
                    alignment: Alignment.center,
                    child: const Text('Moving Row...'),
                  ),
                ),
                onDragStarted: () => setState(() { _draggingRowId = rowId; }),
                onDragEnd: (_) => setState(() { _draggingRowId = null; _dropTargetRowIndex = null; }),
                child: const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
              ),
            ) : const SizedBox(),
          );
        }
      ),
    );
  }

  Widget _buildColHandle(int colIndex) {
    final canDelete = widget.viewModel.columnCount > 1;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredColIndex = colIndex),
      onExit: (_) => setState(() => _hoveredColIndex = null),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) {
           setState(() {
             _dropTargetColIndex = null;
           });
           _executeReorderCol(details.data, colIndex);
        },
        onMove: (details) {
           if (_dropTargetColIndex != colIndex) {
             setState(() {
                _dropTargetColIndex = colIndex;
             });
           }
        },
        onLeave: (data) {
           setState(() {
              _dropTargetColIndex = null;
           });
        },
        builder: (context, candidateData, rejectedData) {
          final isHovered = _hoveredColIndex == colIndex || _draggingColIndex == colIndex;
          return Container(
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: _dropTargetColIndex == colIndex ? const Border(left: BorderSide(color: Colors.blue, width: 2)) : null,
            ),
            child: isHovered ? PopupMenuButton<String>(
              icon: const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
              padding: EdgeInsets.zero,
              onSelected: (action) => _handleMenuAction(action, null, colIndex),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'insert_col_left', child: Text('Insert column left')),
                const PopupMenuItem(value: 'insert_col_right', child: Text('Insert column right')),
                PopupMenuItem(value: 'delete_col', enabled: canDelete, child: Text('Delete column', style: TextStyle(color: canDelete ? Colors.red : Colors.grey))),
              ],
              child: LongPressDraggable<int>(
                data: colIndex,
                feedback: Material(
                  elevation: 4,
                  child: Container(
                    width: 150, 
                    height: 100, 
                    color: Colors.blue.withOpacity(0.1),
                    alignment: Alignment.center,
                    child: const Text('Moving Col...'),
                  ),
                ),
                onDragStarted: () => setState(() { _draggingColIndex = colIndex; }),
                onDragEnd: (_) => setState(() { _draggingColIndex = null; _dropTargetColIndex = null; }),
                child: const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
              ),
            ) : const SizedBox(),
          );
        }
      ),
    );
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
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
      child: Focus(
        onKeyEvent: (node, event) {
          // Allow localized Tab navigation without escaping
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
             // Let the native FocusManager handle it, but we trap it here if needed 
             // to keep focus strictly within the table. For now, returning KeyEventResult.ignored
             // allows flutter to use default Tab traversal which usually works for TextFields.
             return KeyEventResult.ignored;
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = math.max(
              constraints.maxWidth,
              (columnCount * minColumnWidth) + 32, // +32 for row handles
            );
            return SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    verticalInside: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                  ),
                  columnWidths: {
                    0: const FixedColumnWidth(32.0),
                    for (var i = 1; i <= columnCount; i++) i: const FlexColumnWidth(),
                  },
                  children: [
                    // Top row for column handles
                    TableRow(
                      children: [
                        const SizedBox(width: 32, height: 32), // Top-left corner empty
                        for (int c = 0; c < columnCount; c++)
                          _buildColHandle(c),
                      ],
                    ),
                    // Data rows with row handles
                    for (int r = 0; r < rows.length; r++)
                      TableRow(
                        children: [
                          _buildRowHandle(r, rows[r].id),
                          for (int c = 0; c < columnCount; c++)
                            Builder(
                              builder: (context) {
                                final cell = c < rows[r].cells.length ? rows[r].cells[c] : null;
                                final text = cell?.spans.map((s) => s.text).join('') ?? '';
                                final cellId = cell?.id ?? 'temp_cell_${rows[r].id}_$c';
                                
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
                              }
                            ),
                        ],
                      ),
                    
                    // Invisible row for final drop target
                    TableRow(
                      children: [
                        DragTarget<int>(
                          onWillAcceptWithDetails: (details) => true,
                          onAcceptWithDetails: (details) {
                            setState(() {
                              _dropTargetRowIndex = null;
                            });
                            _executeReorderRow(details.data, rows.length);
                          },
                          onMove: (details) {
                            if (_dropTargetRowIndex != rows.length) {
                              setState(() {
                                _dropTargetRowIndex = rows.length;
                              });
                            }
                          },
                          onLeave: (data) {
                            setState(() {
                                _dropTargetRowIndex = null;
                            });
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              height: 16,
                              decoration: BoxDecoration(
                                border: _dropTargetRowIndex == rows.length ? const Border(top: BorderSide(color: Colors.blue, width: 2)) : null,
                              ),
                            );
                          }
                        ),
                        for (int c = 0; c < columnCount; c++)
                          const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
"""

with open(r'c:\Projects\Ketion\lib\features\editor\presentation\table\ketion_table_component.dart', 'w', encoding='utf-8') as f:
    f.write(content)
