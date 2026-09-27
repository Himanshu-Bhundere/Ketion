import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import 'ketion_table_commands.dart';
import '../widgets/ketion_edit_requests.dart';
import 'ketion_table_node.dart';
import '../../domain/models/block_data_models.dart';

class KetionTableComponentViewModel
    extends SingleColumnLayoutComponentViewModel {
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
  int get hashCode =>
      nodeId.hashCode ^ columnCount.hashCode ^ Object.hashAll(rows);
}

class KetionTableComponentBuilder implements ComponentBuilder {
  final Editor editor;

  const KetionTableComponentBuilder(this.editor);

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
      Document document, DocumentNode node,) {
    if (node is! KetionTableNode) return null;

    final columnCount = node.metadata['columnCount'] as int? ?? 2;
    final rowsList = node.metadata['rows'] as List<dynamic>? ?? [];

    List<TableRowData> rows = [];
    try {
      rows = rowsList.map((e) {
        if (e is TableRowData) return e;
        return TableRowData.fromJson(e as Map<String, dynamic>);
      }).toList();

      for (int i = 0; i < rows.length; i++) {
        var row = rows[i];
        if (row.cells.length < columnCount) {
          final newCells = List<TableCellData>.from(row.cells);
          while (newCells.length < columnCount) {
            newCells.add(TableCellData(id: Editor.createNodeId(), spans: []));
          }
          rows[i] = row.copyWith(cells: newCells);
        } else if (row.cells.length > columnCount) {
          rows[i] = row.copyWith(cells: row.cells.take(columnCount).toList());
        }
      }
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
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext,
      SingleColumnLayoutComponentViewModel componentViewModel,) {
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

class TableGeometry {
  final Map<String, Rect> rowRects;
  final double columnWidth;
  final double tableWidth;
  final double tableHeight;

  TableGeometry({
    required this.rowRects,
    required this.columnWidth,
    required this.tableWidth,
    required this.tableHeight,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TableGeometry) return false;
    if (columnWidth != other.columnWidth ||
        tableWidth != other.tableWidth ||
        tableHeight != other.tableHeight) {
      return false;
    }
    if (rowRects.length != other.rowRects.length) return false;
    for (final key in rowRects.keys) {
      if (rowRects[key] != other.rowRects[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      columnWidth.hashCode ^ tableWidth.hashCode ^ tableHeight.hashCode;
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
  String? _activeCellId;

  void _setActiveCell(String cellId) {
    if (_activeCellId == cellId) return;
    final previous = _activeCellId;
    _activeCellId = cellId;
    if (previous != null) {
      _focusNodes[previous]?.unfocus();
    }
  }

  // Column drag auto-scroll state
  final GlobalKey _horizontalViewportKey = GlobalKey();
  Timer? _dragAutoScrollTimer;
  bool _isColumnDragging = false;
  double _autoScrollDirection = 0; // -1 left, 0 none, +1 right

  final GlobalKey _tableKey = GlobalKey();
  TableGeometry? _geometry;

  @visibleForTesting
  TableGeometry? get geometry => _geometry;

  bool _geometryUpdateScheduled = false;

  void _scheduleGeometryUpdate() {
    if (_geometryUpdateScheduled) return;
    _geometryUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryUpdateScheduled = false;
      if (!mounted) return;
      _updateGeometry();
    });
  }

  @override
  void initState() {
    super.initState();
    _scheduleGeometryUpdate();
  }

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

    debugPrint(
        'didUpdateWidget: rows.length=${widget.viewModel.rows.length}, validCellIds.length=${validCellIds.length}, keysToRemove=${keysToRemove.length}, currentControllers=${_controllers.length}',);

    for (var key in keysToRemove) {
      _controllers.remove(key)?.dispose();
      _focusNodes.remove(key)?.dispose();
      _localCellState.remove(key);
    }

    if (_activeCellId != null && !validCellIds.contains(_activeCellId!)) {
      _activeCellId = null;
    }

    for (var row in widget.viewModel.rows) {
      for (var cell in row.cells) {
        if (_controllers.containsKey(cell.id)) {
          if (_localCellState.containsKey(cell.id)) continue;
          final controller = _controllers[cell.id]!;
          final cellText = cell.spans.map((s) => s.text).join('');
          if (controller.text != cellText) {
            final currentSelection = controller.selection;
            controller.text = cellText;
            if (currentSelection.isValid &&
                currentSelection.end <= cellText.length) {
              controller.selection = currentSelection;
            } else {
              controller.selection =
                  TextSelection.collapsed(offset: cellText.length);
            }
          }
        }
      }
    }

    // Focus transfer after row/col insertion
    final oldRowCount = oldWidget.viewModel.rows.length;
    final newRowCount = widget.viewModel.rows.length;
    final oldColCount = oldWidget.viewModel.columnCount;
    final newColCount = widget.viewModel.columnCount;

    if (newRowCount > oldRowCount) {
      final oldRowIds = oldWidget.viewModel.rows.map((r) => r.id).toSet();
      try {
        final newRow =
            widget.viewModel.rows.firstWhere((r) => !oldRowIds.contains(r.id));
        if (newRow.cells.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _getFocusNode(newRow.cells.first.id).requestFocus();
          });
        }
      } catch (_) {}
    } else if (newColCount > oldColCount) {
      if (widget.viewModel.rows.isNotEmpty &&
          oldWidget.viewModel.rows.isNotEmpty) {
        final oldCellIds =
            oldWidget.viewModel.rows.first.cells.map((c) => c.id).toSet();
        try {
          final newCell = widget.viewModel.rows.first.cells
              .firstWhere((c) => !oldCellIds.contains(c.id));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _getFocusNode(newCell.id).requestFocus();
          });
        } catch (_) {}
      }
    }

    _scheduleGeometryUpdate();
  }

  void _updateGeometry() {
    if (!mounted) return;
    final RenderObject? renderObj =
        _tableKey.currentContext?.findRenderObject();
    if (renderObj is RenderTable) {
      final rows = widget.viewModel.rows;
      final Map<String, Rect> rowRects = {};

      double tableWidth = renderObj.size.width;
      double tableHeight = renderObj.size.height;

      for (int i = 0; i < rows.length; i++) {
        try {
          final double rowBoxHeight = renderObj.getRowBox(i).height;
          final double rowBoxTop = renderObj.getRowBox(i).top;
          rowRects[rows[i].id] =
              Rect.fromLTWH(0, rowBoxTop, tableWidth, rowBoxHeight);
        } catch (e) {
          // Ignore
        }
      }

      final newGeometry = TableGeometry(
        rowRects: rowRects,
        columnWidth: 150.0,
        tableWidth: tableWidth,
        tableHeight: tableHeight,
      );

      if (_geometry != newGeometry) {
        setState(() {
          _geometry = newGeometry;
        });
      }
    }
  }

  void _handleColumnDragUpdate(DragUpdateDetails details) {
    if (!_isColumnDragging) return;
    final viewportBox =
        _horizontalViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null) return;

    final localPos = viewportBox.globalToLocal(details.globalPosition);
    final viewportWidth = viewportBox.size.width;
    const edgeThreshold = 48.0;

    double direction = 0;
    if (localPos.dx < edgeThreshold) {
      direction = -1;
    } else if (localPos.dx > viewportWidth - edgeThreshold) {
      direction = 1;
    }

    if (direction != _autoScrollDirection) {
      _autoScrollDirection = direction;
      _dragAutoScrollTimer?.cancel();
      if (direction != 0) {
        _dragAutoScrollTimer = Timer.periodic(
          const Duration(milliseconds: 16), // ~60fps
          (_) {
            final current = _horizontalScrollController.offset;
            final max = _horizontalScrollController.position.maxScrollExtent;
            final next = (current + direction * 4.0).clamp(0.0, max);
            _horizontalScrollController.jumpTo(next);
          },
        );
      }
    }
  }

  void _stopColumnAutoScroll() {
    _dragAutoScrollTimer?.cancel();
    _dragAutoScrollTimer = null;
    _autoScrollDirection = 0;
    _isColumnDragging = false;
  }

  @override
  void dispose() {
    _flushPendingCommit();
    _dragAutoScrollTimer?.cancel();
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
          updatedCells.add(
            cell.copyWith(
              spans: [TextSpanData(text: pendingText)],
            ),
          );
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
            'rows': updatedRows,
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
          _setActiveCell(cellId);
          _ensureCellVisible(cellId);
        }
      });
      _focusNodes[cellId] = fn;
    }
    return _focusNodes[cellId]!;
  }

  void _ensureCellVisible(String cellId) {
    final context = _focusNodes[cellId]?.context;
    if (context != null) {
      Scrollable.ensureVisible(context,
          alignment: 0.5, duration: const Duration(milliseconds: 200),);
    }
  }

  Widget _buildPureTable() {
    final rows = widget.viewModel.rows;
    final columnCount = widget.viewModel.columnCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double colWidth = 150.0;

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _scheduleGeometryUpdate();
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: SizedBox(
          width: columnCount * colWidth,
          child: Table(
            key: _tableKey,
            border: TableBorder(
              horizontalInside: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,),
              verticalInside: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,),
              top: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,),
              bottom: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,),
              left: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,),
              right: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,),
            ),
            columnWidths: {
              for (var i = 0; i < columnCount; i++)
                i: const FixedColumnWidth(colWidth),
            },
            children: [
              for (int r = 0; r < rows.length; r++)
                TableRow(
                  children: [
                    for (int c = 0; c < columnCount; c++)
                      Builder(
                        builder: (context) {
                          final cell = c < rows[r].cells.length
                              ? rows[r].cells[c]
                              : null;
                          final text =
                              cell?.spans.map((s) => s.text).join('') ?? '';
                          final cellId =
                              cell?.id ?? 'temp_cell_${rows[r].id}_$c';

                          return TableCell(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: cell != null
                                  ? TextField(
                                      key: ValueKey(cellId),
                                      controller: _getController(cellId, text),
                                      focusNode: _getFocusNode(cellId),
                                      maxLines: null,
                                      onTap: () => _setActiveCell(cellId),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 12.0,),
                                      ),
                                      style: const TextStyle(fontSize: 14),
                                      onChanged: (value) {
                                        _localCellState[cellId] = value;
                                        _debounceTimer?.cancel();
                                        _debounceTimer = Timer(
                                            const Duration(milliseconds: 300),
                                            () {
                                          _commitLocalState();
                                        });
                                      },
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0,),
                                      child: Text(text,
                                          style: const TextStyle(fontSize: 14),),
                                    ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _draggingRowId;
  String? _dropTargetRowId;

  int? _draggingColumnIndex;
  int? _dropTargetColumnIndex;

  List<Widget> _buildRowHandles() {
    if (_geometry == null) return [];

    final rows = widget.viewModel.rows;
    final rowWidgets = <Widget>[];

    double currentY = 0;
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rect = _geometry!.rowRects[row.id];
      final rowRect = rect ??
          Rect.fromLTWH(
              0, currentY, widget.viewModel.columnCount * 150.0, 48.0,);
      currentY = rowRect.bottom;

      rowWidgets.add(
        Positioned(
          top: rowRect.top,
          left: 0,
          width: 32,
          height: rowRect.height,
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) =>
                details.data.startsWith('row_') &&
                details.data != 'row_${row.id}',
            onAcceptWithDetails: (details) {
              final draggedRowId = details.data.replaceFirst('row_', '');

              if (draggedRowId != row.id) {
                widget.editor.execute([
                  UpdateTableRequest(
                    nodeId: widget.viewModel.nodeId,
                    innerCommand: ReorderTableRowCommand(
                      nodeId: widget.viewModel.nodeId,
                      draggedRowId: draggedRowId,
                      targetRowId: row.id,
                    ),
                  ),
                ]);
              }

              setState(() {
                _dropTargetRowId = null;
              });
            },
            onMove: (details) {
              if (_dropTargetRowId != row.id) {
                setState(() => _dropTargetRowId = row.id);
              }
            },
            onLeave: (data) {
              if (_dropTargetRowId == row.id) {
                setState(() => _dropTargetRowId = null);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showRowMenu(row.id),
                    child: Icon(Icons.more_horiz,
                        size: 16, color: Colors.grey.shade500,),
                  ),
                  const SizedBox(height: 2),
                  LongPressDraggable<String>(
                    data: 'row_${row.id}',
                    onDragStarted: () {
                      _flushPendingCommit();
                      setState(() => _draggingRowId = row.id);
                    },
                    onDragEnd: (details) {
                      setState(() {
                        _draggingRowId = null;
                        _dropTargetRowId = null;
                      });
                    },
                    feedback: Material(
                      elevation: 4,
                      color: Colors.transparent,
                      child: Container(
                        width: widget.viewModel.columnCount * 150.0,
                        height: rowRect.height,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .cardColor
                              .withValues(alpha: 0.9),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Center(
                          child: Icon(Icons.drag_indicator,
                              color: Colors.grey.shade600,),
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color:
                          (candidateData.isNotEmpty || _draggingRowId == row.id)
                              ? Colors.blue
                              : Colors.grey.shade400,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return rowWidgets;
  }

  List<Widget> _buildColumnHandles() {
    final columnCount = widget.viewModel.columnCount;
    const double colWidth = 150.0;
    final colWidgets = <Widget>[];

    double currentX = 0;
    for (int c = 0; c < columnCount; c++) {
      colWidgets.add(
        Positioned(
          top: 0,
          left: currentX,
          width: colWidth,
          height: 32,
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) =>
                details.data.startsWith('col_') && details.data != 'col_$c',
            onAcceptWithDetails: (details) {
              final draggedColStr = details.data.replaceFirst('col_', '');
              final draggedColIndex = int.tryParse(draggedColStr);
              final targetColIndex = c;

              if (draggedColIndex != null &&
                  draggedColIndex != targetColIndex) {
                widget.editor.execute([
                  UpdateTableRequest(
                    nodeId: widget.viewModel.nodeId,
                    innerCommand: ReorderTableColumnCommand(
                      nodeId: widget.viewModel.nodeId,
                      draggedColumnIndex: draggedColIndex,
                      targetColumnIndex: targetColIndex,
                    ),
                  ),
                ]);
              }

              setState(() {
                _dropTargetColumnIndex = null;
              });
            },
            onMove: (details) {
              if (_dropTargetColumnIndex != c) {
                setState(() => _dropTargetColumnIndex = c);
              }
            },
            onLeave: (data) {
              if (_dropTargetColumnIndex == c) {
                setState(() => _dropTargetColumnIndex = null);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showColumnMenu(c),
                    child: Icon(Icons.more_vert,
                        size: 16, color: Colors.grey.shade500,),
                  ),
                  const SizedBox(width: 4),
                  LongPressDraggable<String>(
                    data: 'col_$c',
                    onDragStarted: () {
                      _flushPendingCommit();
                      setState(() {
                        _draggingColumnIndex = c;
                        _isColumnDragging = true;
                      });
                    },
                    onDragUpdate: _handleColumnDragUpdate,
                    onDragEnd: (details) {
                      _stopColumnAutoScroll();
                      setState(() {
                        _draggingColumnIndex = null;
                        _dropTargetColumnIndex = null;
                      });
                    },
                    feedback: Material(
                      elevation: 4,
                      color: Colors.transparent,
                      child: Container(
                        width: colWidth,
                        height: _geometry?.tableHeight ?? 32,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .cardColor
                              .withValues(alpha: 0.9),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Center(
                          child: Icon(Icons.drag_handle,
                              color: Colors.grey.shade600,),
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      size: 16,
                      color: (candidateData.isNotEmpty ||
                              _draggingColumnIndex == c)
                          ? Colors.blue
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      currentX += colWidth;
    }

    return colWidgets;
  }

  List<Widget> _buildDropIndicators() {
    final indicators = <Widget>[];
    final columnCount = widget.viewModel.columnCount;
    const double colWidth = 150.0;
    final structuralTableWidth = columnCount * colWidth;

    if (_dropTargetRowId != null && _geometry != null) {
      final rect = _geometry!.rowRects[_dropTargetRowId!];
      if (rect != null) {
        indicators.add(
          Positioned(
            top: rect.top - 2, // Draw slightly above the target row
            left: 0,
            width: structuralTableWidth,
            height: 4,
            child: Container(color: Colors.blue),
          ),
        );
      }
    }

    if (_dropTargetColumnIndex != null) {
      final leftOffset = _dropTargetColumnIndex! * colWidth;
      indicators.add(
        Positioned(
          top: 0,
          left: leftOffset - 2, // Draw slightly left of the target column
          width: 4,
          height: _geometry?.tableHeight ?? 32,
          child: Container(color: Colors.blue),
        ),
      );
    }

    return indicators;
  }

  void _showAdaptiveMenu({
    required Offset offset,
    required List<PopupMenuEntry<String>> items,
    required void Function(String) onSelected,
  }) {
    final bool isMobile = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android;

    if (isMobile) {
      showModalBottomSheet<String>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) {
                if (item is PopupMenuItem<String>) {
                  return ListTile(
                    title: item.child,
                    enabled: item.enabled,
                    onTap: () => Navigator.pop(context, item.value),
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
          );
        },
      ).then((value) {
        if (value != null) onSelected(value);
      });
    } else {
      showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
            offset.dx, offset.dy, offset.dx + 1, offset.dy + 1,),
        items: items,
      ).then((value) {
        if (value != null) onSelected(value);
      });
    }
  }

  void _showRowMenu(String rowId) {
    _flushPendingCommit();
    final rows = widget.viewModel.rows;
    final rowIndex = rows.indexWhere((r) => r.id == rowId);
    if (rowIndex == -1) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final rect = _geometry?.rowRects[rowId];
    if (rect == null) return;

    final offset = renderBox.localToGlobal(Offset(32, rect.top + 32 + 4));

    _showAdaptiveMenu(
      offset: offset,
      items: [
        const PopupMenuItem<String>(
            value: 'insert_above', child: Text('Insert row above'),),
        const PopupMenuItem<String>(
            value: 'insert_below', child: Text('Insert row below'),),
        const PopupMenuItem<String>(
            value: 'duplicate', child: Text('Duplicate row'),),
        PopupMenuItem<String>(
          value: 'delete',
          enabled: widget.viewModel.rows.length > 1,
          child: Text('Delete row',
              style: TextStyle(
                  color: widget.viewModel.rows.length > 1
                      ? Colors.red
                      : Colors.grey,),),
        ),
      ],
      onSelected: (value) {
        if (value == 'insert_above') {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: AddTableRowCommand(
                  nodeId: widget.viewModel.nodeId, afterRowIndex: rowIndex - 1,),
            ),
          ]);
        } else if (value == 'insert_below') {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: AddTableRowCommand(
                  nodeId: widget.viewModel.nodeId, afterRowIndex: rowIndex,),
            ),
          ]);
        } else if (value == 'duplicate') {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: DuplicateTableRowCommand(
                  nodeId: widget.viewModel.nodeId, rowIndex: rowIndex,),
            ),
          ]);
        } else if (value == 'delete') {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: DeleteTableRowCommand(
                  nodeId: widget.viewModel.nodeId, rowIndex: rowIndex,),
            ),
          ]);
        }
      },
    );
  }

  void _showColumnMenu(int colIndex) {
    _flushPendingCommit();
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    const double colWidth = 150.0;
    final leftOffset = colIndex * colWidth;

    final offset = renderBox.localToGlobal(
      Offset(32 + leftOffset - _horizontalScrollController.offset, 32 + 4),
    );

    _showAdaptiveMenu(
      offset: offset,
      items: [
        const PopupMenuItem<String>(
            value: 'insert_left', child: Text('Insert column left'),),
        const PopupMenuItem<String>(
            value: 'insert_right', child: Text('Insert column right'),),
        const PopupMenuItem<String>(
            value: 'duplicate', child: Text('Duplicate column'),),
        PopupMenuItem<String>(
          value: 'delete',
          enabled: widget.viewModel.columnCount > 1,
          child: Text('Delete column',
              style: TextStyle(
                  color: widget.viewModel.columnCount > 1
                      ? Colors.red
                      : Colors.grey,),),
        ),
      ],
      onSelected: (value) {
        if (value == 'insert_left') {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: AddTableColumnCommand(
                  nodeId: widget.viewModel.nodeId, afterColIndex: colIndex - 1,),
            ),
          ]);
        } else if (value == 'insert_right') {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: AddTableColumnCommand(
                  nodeId: widget.viewModel.nodeId, afterColIndex: colIndex,),
            ),
          ]);
        } else if (value == 'duplicate') {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: DuplicateTableColumnCommand(
                  nodeId: widget.viewModel.nodeId, colIndex: colIndex,),
            ),
          ]);
        } else if (value == 'delete') {
          widget.editor.execute([
            UpdateTableRequest(
              nodeId: widget.viewModel.nodeId,
              innerCommand: DeleteTableColumnCommand(
                  nodeId: widget.viewModel.nodeId, colIndex: colIndex,),
            ),
          ]);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.viewModel.rows;
    final columnCount = widget.viewModel.columnCount;
    const double colWidth = 150.0;
    final double structuralTableWidth = columnCount * colWidth;

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

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.tab) {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FixedRowGutter
            Column(
              children: [
                const SizedBox(
                    height: 32,
                    width: 32,), // Corner space for ColumnHandleHeader
                SizedBox(
                  width: 32,
                  height: _geometry?.tableHeight ?? 0,
                  child: Stack(
                    children: _buildRowHandles(),
                  ),
                ),
              ],
            ),
            // Scrollable TableViewport
            Expanded(
              child: SingleChildScrollView(
                key: _horizontalViewportKey,
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ColumnHandleHeader
                    SizedBox(
                      height: 32,
                      width: structuralTableWidth,
                      child: Stack(
                        children: _buildColumnHandles(),
                      ),
                    ),
                    // TableContent
                    Stack(
                      children: [
                        _buildPureTable(),
                        ..._buildDropIndicators(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
