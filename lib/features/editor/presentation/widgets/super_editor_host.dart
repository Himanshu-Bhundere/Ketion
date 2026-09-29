import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import '../../../../core/utils/result.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_edit_request_handler.dart';
import 'package:ketion/features/editor/presentation/widgets/super_editor_adapter.dart';
import 'editor_identity_registry.dart';
import '../providers/editor_state_provider.dart';
import '../../../blocks/presentation/providers/block_providers.dart';
import 'ketion_edit_listener.dart';
import 'super_editor_slash_command.dart';
import 'package:ketion/features/editor/presentation/widgets/slash_command_menu.dart';
import 'package:ketion/features/editor/presentation/widgets/page_header.dart';
import '../../domain/models/editor_open_target.dart';
import '../../services/editor_persistence_snapshot.dart';
import 'editor_history_controller.dart';
import '../../services/editor_persistence_coordinator.dart';
import '../../services/editor_persistence_gateway.dart';
import 'ketion_task_component.dart';

class SuperEditorHost extends ConsumerStatefulWidget {
  final String pageId;
  final bool focusTitle;
  final Future<Result<void>> Function(String) onTitleChanged;
  final Future<Result<void>> Function(String) onIconChanged;
  final EditorOpenTarget? openTarget;

  const SuperEditorHost({
    super.key,
    required this.pageId,
    required this.onTitleChanged,
    required this.onIconChanged,
    this.focusTitle = false,
    this.openTarget,
  });

  @override
  ConsumerState<SuperEditorHost> createState() => _SuperEditorHostState();
}

class _SuperEditorHostState extends ConsumerState<SuperEditorHost> {
  late final MutableDocument _document;
  late final MutableDocumentComposer _composer;
  late final Editor _editor;
  late final KetionSuperEditorAdapter _adapter;
  late final SuperEditorSlashCommandController _slashController;
  late final KetionEditListener _editListener;
  late final FocusNode _focusNode;
  late final EditorHistoryController _historyController;
  late final EditorPersistenceCoordinator _coordinator;
  bool _isInitialized = false;
  bool _isHandlingPop = false;

  @visibleForTesting
  MutableDocument get document => _document;
  
  @visibleForTesting
  Editor get editor => _editor;

  @visibleForTesting
  EditorIdentityRegistry get registry => _adapter.registry;

  @visibleForTesting
  KetionSuperEditorAdapter get adapter => _adapter;

  @override
  void initState() {
    super.initState();
    _composer = MutableDocumentComposer();
    _focusNode = FocusNode();
    
    // Defer initialization to avoid state access during initState which can cause 
    // Riverpod assertion errors or freezes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initEditor();
    });
  }
  
  Future<void> _initEditor() async {
    try {
      debugPrint('Ketion _initEditor: invalidating state');
      ref.invalidate(editorStateProvider(widget.pageId));
      debugPrint('Ketion _initEditor: awaiting blocks...');
      final blocks = await ref.read(editorStateProvider(widget.pageId).future);
      debugPrint('Ketion _initEditor: got blocks: ${blocks.length}');
      
      if (!mounted) return;
      
      final blockRepository = ref.read(blockRepositoryProvider);
      _coordinator = EditorPersistenceCoordinator(
        gateway: RepositoryEditorPersistenceGateway(repository: blockRepository),
      );

      final initialSnapshotMap = <String, BlockSnapshot>{};
      for (final block in blocks) {
        initialSnapshotMap[block.id] = BlockSnapshot(
          blockId: block.id,
          pageId: block.pageId,
          version: block.version,
          parentBlockId: block.parentBlockId,
          position: block.position,
          type: block.type,
          createdAt: block.createdAt,
          deleted: false,
        );
      }
      final snapshot = EditorPersistenceSnapshot(widget.pageId, initialSnapshotMap);

      _adapter = KetionSuperEditorAdapter(
        pageId: widget.pageId,
        coordinator: _coordinator,
        snapshot: snapshot,
      );
      
      _document = _adapter.createDocument(blocks);

      final ketionHandler = createKetionRequestHandler(
        registry: _adapter.registry,
        pageId: widget.pageId,
        document: _document,
        composer: _composer,
        coordinator: _coordinator,
        snapshot: snapshot,
        adapter: _adapter,
      );
      
      _editor = Editor(
        editables: {
          Editor.documentKey: _document,
          Editor.composerKey: _composer,
        },
        requestHandlers: <EditRequestHandler>[
          ketionHandler,
          ...defaultRequestHandlers.cast<EditRequestHandler>(),
        ],
        reactionPipeline: List.from(defaultEditorReactions),
        isHistoryEnabled: true,
      );
      
      _adapter.bind(_document, _editor);
      
      _editListener = KetionEditListener(
        registry: _adapter.registry,
        document: _document,
        pageId: widget.pageId,
        coordinator: _coordinator,
      );
      _editor.addListener(_editListener);
      
      _slashController = SuperEditorSlashCommandController(
        document: _document,
        composer: _composer,
        editor: _editor,
        context: () => context,
        optionsBuilder: _slashOptionsFor,
        onDismiss: () => _focusNode.requestFocus(),
      );
      
      _historyController = EditorHistoryController(
        editor: _editor,
        document: _document,
        registry: _adapter.registry,
      );

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(editorHistoryControllerProvider(widget.pageId).notifier).state = _historyController;
            if (widget.openTarget?.targetBlockId != null) {
              _scrollToTarget(widget.openTarget!);
            }
          }
        });
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      debugPrint('Ketion _initEditor crashed: $e\n$stack');
    }
  }


  void _scrollToTarget(EditorOpenTarget target) {
    if (target.targetBlockId == null) return;
    
    final nodeId = _adapter.registry.nodeIdForBlock(target.targetBlockId!);
    if (nodeId == null) return;
    
    _editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: nodeId,
            nodePosition: TextNodePosition(offset: target.textOffset ?? 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
    
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _editor.removeListener(_editListener);
      _slashController.dispose();
      _historyController.dispose();
      _adapter.dispose();
    }
    _focusNode.dispose();
    _composer.dispose();
    super.dispose();
  }

  @visibleForTesting
  List<SlashCommandOption> getSlashOptionsForTesting(String query) => _slashOptionsFor(query);

  List<SlashCommandOption> _slashOptionsFor(String query) {
    final allOptions = [
      SuperEditorSlashCommandOption(
        title: 'Heading 1',
        subtitle: 'Large section heading',
        icon: Icons.title,
        category: SlashCommandCategory.basic,
        aliases: const ['h1', 'title', 'header1'],
        getEditRequests: (nodeId) => _getHeadingRequests(nodeId, 1),
      ),
      SuperEditorSlashCommandOption(
        title: 'Heading 2',
        subtitle: 'Medium section heading',
        icon: Icons.title,
        category: SlashCommandCategory.basic,
        aliases: const ['h2', 'subtitle', 'header2'],
        getEditRequests: (nodeId) => _getHeadingRequests(nodeId, 2),
      ),
      SuperEditorSlashCommandOption(
        title: 'Heading 3',
        subtitle: 'Small section heading',
        icon: Icons.title,
        category: SlashCommandCategory.basic,
        aliases: const ['h3', 'header3'],
        getEditRequests: (nodeId) => _getHeadingRequests(nodeId, 3),
      ),
      SuperEditorSlashCommandOption(
        title: 'Quote',
        subtitle: 'Capture a quote',
        icon: Icons.format_quote,
        category: SlashCommandCategory.basic,
        aliases: const ['quote', 'blockquote', '>'],
        getEditRequests: (nodeId) => _getQuoteRequests(nodeId),
      ),
      SuperEditorSlashCommandOption(
        title: 'Divider',
        subtitle: 'Visually divide blocks',
        icon: Icons.horizontal_rule,
        category: SlashCommandCategory.basic,
        aliases: const ['divider', 'hr', 'line', '---'],
        getEditRequests: (nodeId) => _getDividerRequests(nodeId),
      ),
      SuperEditorSlashCommandOption(
        title: 'Checklist',
        subtitle: 'Track tasks with a to-do list',
        icon: Icons.check_box_outlined,
        category: SlashCommandCategory.list,
        aliases: const ['todo', 'checkbox', 'task'],
        getEditRequests: (nodeId) => _getListRequests(nodeId, 'checklist'),
      ),
      SuperEditorSlashCommandOption(
        title: 'Bulleted List',
        subtitle: 'Create a simple bulleted list',
        icon: Icons.format_list_bulleted,
        category: SlashCommandCategory.list,
        aliases: const ['bullet', 'unordered'],
        getEditRequests: (nodeId) => _getListRequests(nodeId, 'bullet'),
      ),
      SuperEditorSlashCommandOption(
        title: 'Numbered List',
        subtitle: 'Create a list with numbering',
        icon: Icons.format_list_numbered,
        category: SlashCommandCategory.list,
        aliases: const ['number', 'ordered', '1.'],
        getEditRequests: (nodeId) => _getListRequests(nodeId, 'numbered'),
      ),
    ];
    
    final normalizedQuery = query.trim().toLowerCase();
    
    final filteredOptions = allOptions.where((option) {
      if (normalizedQuery.isEmpty) return true;
      
      final matchesTitleOrSubtitle = option.title.toLowerCase().contains(normalizedQuery) ||
          option.subtitle.toLowerCase().contains(normalizedQuery);
          
      final matchesAlias = option.aliases.any((alias) => alias.toLowerCase().contains(normalizedQuery));
      
      return matchesTitleOrSubtitle || matchesAlias;
    }).toList();

    filteredOptions.sort((a, b) => a.category.index.compareTo(b.category.index));
    
    return filteredOptions;
  }

  List<EditRequest> _getHeadingRequests(String nodeId, int level) {
    Attribution blockType;
    if (level == 1) {
      blockType = header1Attribution;
    } else if (level == 2) {
      blockType = header2Attribution;
    } else {
      blockType = header3Attribution;
    }
    
    return [
      ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: blockType),
    ];
  }

  List<EditRequest> _getQuoteRequests(String nodeId) {
    return [
      ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: blockquoteAttribution),
    ];
  }

  List<EditRequest> _getDividerRequests(String nodeId) {
    return [
      InsertNodeBeforeNodeRequest(
        existingNodeId: nodeId,
        newNode: HorizontalRuleNode(id: Editor.createNodeId()),
      ),
    ];
  }

  List<EditRequest> _getListRequests(String nodeId, String listType) {
    final node = _document.getNodeById(nodeId);

    if (listType == 'checklist') {
      if (node is ParagraphNode) {
        return [
          ConvertParagraphToTaskRequest(nodeId: nodeId),
        ];
      }
      return [];
    }

    if (listType == 'bullet' || listType == 'numbered') {
      final newType = listType == 'numbered' ? ListItemType.ordered : ListItemType.unordered;

      if (node is ListItemNode) {
        return [
          ChangeListItemTypeRequest(nodeId: nodeId, newType: newType),
        ];
      }
      if (node is ParagraphNode) {
        return [
          ConvertParagraphToListItemRequest(nodeId: nodeId, type: newType),
        ];
      }
      if (node is TaskNode) {
        return [
          ConvertTaskToParagraphRequest(nodeId: nodeId),
          ConvertParagraphToListItemRequest(nodeId: nodeId, type: newType),
        ];
      }
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Keep the editorStateProvider alive while the editor is open
    ref.watch(editorStateProvider(widget.pageId));
    
    final pageAsync = ref.watch(pageProvider(widget.pageId));
    final page = pageAsync.valueOrNull;
    if (page == null) return const SizedBox.shrink();
    
    return PopScope(
      canPop: _isHandlingPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _isHandlingPop) return;
        
        final navigator = Navigator.of(context);
        setState(() => _isHandlingPop = true);
        await _adapter.flushPendingChanges();
        await _coordinator.flush();
        navigator.pop(result);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: PageHeader(
            page: page,
            focusTitle: widget.focusTitle,
            onTitleChanged: widget.onTitleChanged,
            onIconChanged: widget.onIconChanged,
          ),
        ),
        Expanded(
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                _adapter.flushPendingChanges();
              }
            },
            onKeyEvent: (node, event) {
               if (event is KeyDownEvent) {
                  final hardwareKeyboard = HardwareKeyboard.instance;
                  final isMetaPressed = hardwareKeyboard.isMetaPressed || hardwareKeyboard.isControlPressed;
                  
                  if (event.logicalKey == LogicalKeyboardKey.keyZ && isMetaPressed) {
                    final historyController = ref.read(editorHistoryControllerProvider(widget.pageId));
                    if (hardwareKeyboard.isShiftPressed) {
                      historyController?.redo();
                    } else {
                      historyController?.undo();
                    }
                    return KeyEventResult.handled;
                  }

                  if (_slashController.handleKeyEvent(event)) {
                     return KeyEventResult.handled;
                  }
               }
               return KeyEventResult.ignored;
            },
            child: SuperEditor(
              editor: _editor,
              focusNode: _focusNode,
              stylesheet: (Theme.of(context).brightness == Brightness.dark 
                  ? defaultStylesheet.copyWith(
                      addRulesAfter: [
                        StyleRule(
                          BlockSelector.all,
                          (doc, docNode) {
                            return {
                              'textStyle': const TextStyle(
                                color: Color(0xFFCCCCCC),
                                height: 1.4,
                              ),
                            };
                          },
                        ),
                        StyleRule(
                          const BlockSelector('paragraph'),
                          (doc, docNode) {
                            return {
                              'textStyle': const TextStyle(
                                fontSize: 18,
                              ),
                            };
                          },
                        ),
                        StyleRule(
                          const BlockSelector('header1'),
                          (doc, docNode) {
                            return {
                              'textStyle': const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            };
                          },
                        ),
                        StyleRule(
                          const BlockSelector('header2'),
                          (doc, docNode) {
                            return {
                              'textStyle': const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            };
                          },
                        ),
                        StyleRule(
                          const BlockSelector('header3'),
                          (doc, docNode) {
                            return {
                              'textStyle': const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            };
                          },
                        ),
                        StyleRule(
                          const BlockSelector('listItem'),
                          (doc, docNode) {
                            return {
                              'textStyle': const TextStyle(
                                fontSize: 18,
                              ),
                            };
                          },
                        ),
                        StyleRule(
                          const BlockSelector('task'),
                          (doc, docNode) {
                            return {
                              'textStyle': const TextStyle(
                                fontSize: 18,
                              ),
                            };
                          },
                        ),
                      ],
                    )
                  : defaultStylesheet).copyWith(
                addRulesAfter: [
                  StyleRule(
                    const BlockSelector('task'),
                    (doc, docNode) {
                      return {
                        'padding': const CascadingPadding.only(top: 0, bottom: 0),
                      };
                    },
                  ),
                  StyleRule(
                    const BlockSelector('blockquote'),
                    (doc, docNode) {
                      return {
                        'padding': const CascadingPadding.only(
                          top: 8,
                          bottom: 8,
                          left: 16,
                        ),
                        'textStyle': const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      };
                    },
                  ),
                ],
                documentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              ),
              componentBuilders: [
                KetionTaskComponentBuilder(_editor),
                ...defaultComponentBuilders,
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }
}
