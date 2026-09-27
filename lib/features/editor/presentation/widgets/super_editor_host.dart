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
import '../../domain/commands/change_paragraph_metadata.dart';
import 'ketion_edit_listener.dart';
import 'super_editor_slash_command.dart';
import 'package:ketion/features/editor/presentation/widgets/slash_command_menu.dart';
import 'package:ketion/features/editor/presentation/widgets/page_header.dart';
import '../../../reminders/presentation/providers/reminder_providers.dart';
import '../../../reminders/presentation/widgets/reminder_picker_sheet.dart';
import '../../domain/models/editor_open_target.dart';
import '../../services/editor_persistence_snapshot.dart';
import 'editor_history_controller.dart';
import '../../services/editor_persistence_coordinator.dart';
import 'ketion_slash_command_registry.dart';
import '../../services/editor_persistence_gateway.dart';
import '../../../../core/presentation/widgets/url_input_dialog.dart';
import '../../../pages/presentation/widgets/page_picker_sheet.dart';
import '../../../pages/domain/entities/page.dart' as ketion_pages;
import 'ketion_edit_requests.dart';
import '../../domain/models/media_nodes.dart';
import 'ketion_task_component.dart';
import 'ketion_toggle_component.dart';
import 'ketion_callout_component.dart';
import 'ketion_callout_keyboard_actions.dart';
import 'ketion_toggle_keyboard_actions.dart';
import 'ketion_image_component.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_media_components.dart';
import '../table/ketion_table_component.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../media/data/repositories/attachment_repository_impl.dart';
import 'depth_wrapping_component_builder.dart';

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
  EditorHistoryController get historyController => _historyController;

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
        gateway:
            RepositoryEditorPersistenceGateway(repository: blockRepository),
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
      final snapshot =
          EditorPersistenceSnapshot(widget.pageId, initialSnapshotMap);

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
        onReminderInserted: (pageId, node) {
          final createReminder = ref.read(createReminderUseCaseProvider);
          final blockId = _adapter.registry.blockIdForNode(node.id);
          createReminder
              .execute(
            pageId: pageId,
            blockId: blockId,
            title: node.title,
            reminderTime: DateTime.parse(node.dueAt),
            timezone: node.timezone,
            recurrenceRule: node.recurrenceRule,
          )
              .then(
            (_) {},
            onError: (Object e) {
              debugPrint('Failed to create reminder: $e');
            },
          );
        },
      );

      _editor = Editor(
        editables: {
          Editor.documentKey: _document,
          Editor.composerKey: _composer,
        },
        requestHandlers: <EditRequestHandler>[
          executeCommandRequestHandler,
          ketionHandler,
          changeParagraphMetadataRequestHandler,
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
        onReminderSlashSelected: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (context) => ReminderPickerSheet(pageId: widget.pageId),
          );
        },
        onBookmarkSlashSelected: _handleBookmarkSlashSelected,
        onWebBookmarkSlashSelected: _handleWebBookmarkSlashSelected,
        onLinkToPageSlashSelected: _handleLinkToPageSlashSelected,
        onImageSlashSelected: _handleImageSlashSelected,
        onVideoSlashSelected: _handleVideoSlashSelected,
        onAudioSlashSelected: _handleAudioSlashSelected,
        onFileSlashSelected: _handleFileSlashSelected,
        onPdfSlashSelected: _handlePdfSlashSelected,
      );

      _historyController = EditorHistoryController(
        editor: _editor,
        document: _document,
        registry: _adapter.registry,
      );

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(editorHistoryControllerProvider(widget.pageId).notifier)
                .state = _historyController;
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

  void _replaceSlashWithNode(SlashCommandTarget target, DocumentNode newNode) {
    final emptyParagraph = ParagraphNode(id: Editor.createNodeId(), text: AttributedText());
    _editor.execute([
      InsertNodeAfterNodeRequest(
        existingNodeId: target.nodeId,
        newNode: newNode,
      ),
      InsertNodeAfterNodeRequest(
        existingNodeId: newNode.id,
        newNode: emptyParagraph,
      ),
      DeleteNodeRequest(nodeId: target.nodeId),
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: emptyParagraph.id,
            nodePosition: emptyParagraph.beginningPosition,
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
  }

  Future<void> _handleBookmarkSlashSelected(SlashCommandTarget target) async {
    final url = await UrlInputDialog.show(context, title: 'Add Bookmark');
    if (url != null && mounted) {
      _replaceSlashWithNode(target, KetionBookmarkNode(id: Editor.createNodeId(), url: url));
      _focusNode.requestFocus();
    }
  }

  Future<void> _handleWebBookmarkSlashSelected(SlashCommandTarget target) async {
    final url = await UrlInputDialog.show(context, title: 'Add Web Bookmark');
    if (url != null && mounted) {
      _replaceSlashWithNode(target, KetionWebLinkNode(id: Editor.createNodeId(), url: url));
      _focusNode.requestFocus();
    }
  }

  Future<void> _handleLinkToPageSlashSelected(SlashCommandTarget target) async {
    final page = await showModalBottomSheet<ketion_pages.Page>(
      context: context,
      builder: (context) => const PagePickerSheet(),
    );
    if (page != null && mounted) {
      _replaceSlashWithNode(target, KetionPageLinkNode(id: Editor.createNodeId(), pageId: page.id));
      _focusNode.requestFocus();
    }
  }

  Future<void> _handleMediaSlashSelected(SlashCommandTarget target, FileType fileType, String mimePrefix, BlockNode Function(String, String) nodeBuilder, {List<String>? allowedExtensions}) async {
    final result = await FilePicker.platform.pickFiles(type: fileType, allowedExtensions: allowedExtensions);
    if (result != null && result.files.isNotEmpty && mounted) {
      final file = result.files.first;
      if (file.path == null) return;
      
      final newNodeId = Editor.createNodeId();
      final newBlockId = const Uuid().v7();
      
      // Pre-register so the delegating command doesn't overwrite it
      _adapter.registry.registerPendingMapping(nodeId: newNodeId, blockId: newBlockId);

      final attachment = await ref.read(attachmentRepositoryProvider).saveAttachment(
        pageId: widget.pageId,
        blockId: newBlockId,
        sourceFile: file,
        mimeType: '$mimePrefix/${file.extension}',
      );
      
      if (mounted) {
        _replaceSlashWithNode(target, nodeBuilder(newNodeId, attachment.id));
        _focusNode.requestFocus();
      }
    } else if (mounted) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _handleImageSlashSelected(SlashCommandTarget target) async {
    return _handleMediaSlashSelected(target, FileType.image, 'image', (id, attachmentId) => ImageNode(id: id, imageUrl: attachmentId));
  }

  Future<void> _handleVideoSlashSelected(SlashCommandTarget target) async {
    return _handleMediaSlashSelected(target, FileType.video, 'video', (id, attachmentId) => KetionVideoNode(id: id, attachmentId: attachmentId));
  }

  Future<void> _handleAudioSlashSelected(SlashCommandTarget target) async {
    return _handleMediaSlashSelected(target, FileType.audio, 'audio', (id, attachmentId) => KetionAudioNode(id: id, attachmentId: attachmentId));
  }

  Future<void> _handleFileSlashSelected(SlashCommandTarget target) async {
    return _handleMediaSlashSelected(target, FileType.any, 'application', (id, attachmentId) {
      return KetionFileNode(id: id, attachmentId: attachmentId);
    });
  }

  Future<void> _handlePdfSlashSelected(SlashCommandTarget target) async {
    return _handleMediaSlashSelected(target, FileType.custom, 'application/pdf', (id, attachmentId) {
      return KetionPdfNode(id: id, attachmentId: attachmentId);
    }, allowedExtensions: ['pdf'],);
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
      _coordinator.close();
    }
    _focusNode.dispose();

    _composer.dispose();

    super.dispose();

  }

  @visibleForTesting
  List<SlashCommandOption> getSlashOptionsForTesting(String query) =>
      _slashOptionsFor(query);

  @visibleForTesting
  SuperEditorSlashCommandController get slashCommandController =>
      _slashController;

  List<SlashCommandOption> _slashOptionsFor(String query) {
    return KetionSlashCommandRegistry.getOptionsForQuery(query);
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
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                  final isMetaPressed = hardwareKeyboard.isMetaPressed ||
                      hardwareKeyboard.isControlPressed;

                  if (event.logicalKey == LogicalKeyboardKey.keyZ &&
                      isMetaPressed) {
                    final historyController = ref
                        .read(editorHistoryControllerProvider(widget.pageId));
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
                        : defaultStylesheet)
                    .copyWith(
                  addRulesAfter: [
                    StyleRule(
                      const BlockSelector('task'),
                      (doc, docNode) {
                        return {
                          'padding':
                              const CascadingPadding.only(top: 0, bottom: 0),
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
                    StyleRule(
                      const BlockSelector('code'),
                      (doc, docNode) {
                        return {
                          'padding': const CascadingPadding.all(16),
                          'textStyle': const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                          ),
                        };
                      },
                    ),
                  ],
                  documentPadding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0,),
                ),
                componentBuilders: [
                  KetionToggleComponentBuilder(_editor),
                  const KetionCalloutComponentBuilder(),
                  KetionTaskComponentBuilder(_editor),
                  const KetionImageComponentBuilder(),
                  const KetionVideoComponentBuilder(),
                  const KetionAudioComponentBuilder(),
                  const KetionPdfComponentBuilder(),
                  const KetionFileComponentBuilder(),
                  const KetionBookmarkComponentBuilder(),
                  KetionTableComponentBuilder(_editor),
                  const KetionPageLinkComponentBuilder(),
                  const KetionWebLinkComponentBuilder(),
                  KetionReminderComponentBuilder(_editor),
                  ...defaultComponentBuilders,
                ].map((b) => DepthWrappingComponentBuilder(b, _editor.document)).toList(),
                keyboardActions: [
                  indentParagraphWhenTabPressed,
                  unindentParagraphWhenShiftTabPressed,
                  unindentParagraphWhenBackspacePressed,
                  splitToggleWhenEnterPressed,
                  splitCalloutWhenEnterPressed,
                  convertCalloutToParagraphWhenBackspacePressed,
                  ...defaultKeyboardActions,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
