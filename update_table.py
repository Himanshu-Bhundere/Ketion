import re

with open("lib/features/editor/presentation/table/ketion_table_component.dart", "r", encoding="utf-8") as f:
    content = f.read()

# We keep everything up to the class KetionTableComponent
match = re.search(r"class KetionTableComponent extends StatefulWidget", content)
if not match:
    print("Could not find KetionTableComponent")
    exit(1)

header = content[:match.start()]

new_code = """class TableGeometry {
  final Map<String, Rect> rowRects;
  final Map<int, Rect> colRects;
  final double tableWidth;
  final double tableHeight;

  TableGeometry({
    required this.rowRects,
    required this.colRects,
    required this.tableWidth,
    required this.tableHeight,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TableGeometry) return false;
    if (tableWidth != other.tableWidth || tableHeight != other.tableHeight) return false;
    if (rowRects.length != other.rowRects.length) return false;
    for (final key in rowRects.keys) {
      if (rowRects[key] != other.rowRects[key]) return false;
    }
    return true;
  }
  
  @override
  int get hashCode => tableWidth.hashCode ^ tableHeight.hashCode;
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
  
  final GlobalKey _tableKey = GlobalKey();
  TableGeometry? _geometry;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateGeometry();
    });
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateGeometry();
    });
  }

  void _updateGeometry() {
    if (!mounted) return;
    final RenderObject? renderObj = _tableKey.currentContext?.findRenderObject();
    if (renderObj is RenderTable) {
      final rows = widget.viewModel.rows;
      final columnCount = widget.viewModel.columnCount;
      final Map<String, Rect> rowRects = {};
      final Map<int, Rect> colRects = {};
      
      double tableWidth = renderObj.size.width;
      double tableHeight = renderObj.size.height;
      
      for (int i = 0; i < rows.length; i++) {
         try {
           final double rowBoxHeight = renderObj.getRowBox(i).height;
           final double rowBoxTop = renderObj.getRowBox(i).top;
           rowRects[rows[i].id] = Rect.fromLTWH(0, rowBoxTop, tableWidth, rowBoxHeight);
         } catch(e) {
           // Ignore
         }
      }
      
      double currentX = 0;
      for (int c = 0; c < columnCount; c++) {
         colRects[c] = Rect.fromLTWH(currentX, 0, 150.0, tableHeight);
         currentX += 150.0;
      }
      
      final newGeometry = TableGeometry(
         rowRects: rowRects,
         colRects: colRects,
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
    final context = _focusNodes[cellId]?.context;
    if (context != null) {
      Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 200));
    }
  }

  Widget _buildPureTable() {
    final rows = widget.viewModel.rows;
    final columnCount = widget.viewModel.columnCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double colWidth = 150.0;
    
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateGeometry();
         });
         return true;
      },
      child: SizeChangedLayoutNotifier(
        child: SizedBox(
          width: columnCount * colWidth,
          child: Table(
            key: _tableKey,
            border: TableBorder(
              horizontalInside: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              verticalInside: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              left: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              right: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            ),
            columnWidths: {
              for (var i = 0; i < columnCount; i++) i: const FixedColumnWidth(colWidth),
            },
            children: [
              for (int r = 0; r < rows.length; r++)
                TableRow(
                  children: [
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
    
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
             return KeyEventResult.ignored;
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FixedRowGutter placeholder (will be used in Phase 3)
            const SizedBox(width: 32, height: 32),
            // Scrollable TableViewport
            Expanded(
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ColumnHandleHeader placeholder (will be used in Phase 4)
                    const SizedBox(height: 32),
                    // TableContent
                    Stack(
                      children: [
                        _buildPureTable(),
                        // DropIndicatorOverlay will go here in later phases
                      ]
                    )
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
"""

with open("lib/features/editor/presentation/table/ketion_table_component.dart", "w", encoding="utf-8") as f:
    f.write(header + new_code)
