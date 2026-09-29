import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import '../../../../core/utils/result.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import '../providers/editor_state_provider.dart';
import 'super_editor_adapter.dart';
import 'super_editor_slash_command.dart';
import 'slash_command_menu.dart';
import 'page_header.dart';

class SuperEditorHost extends ConsumerStatefulWidget {
  final String pageId;
  final bool focusTitle;
  final Future<Result<void>> Function(String) onTitleChanged;
  final Future<Result<void>> Function(String) onIconChanged;

  const SuperEditorHost({
    super.key,
    required this.pageId,
    required this.onTitleChanged,
    required this.onIconChanged,
    this.focusTitle = false,
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
  late final FocusNode _focusNode;
  bool _isInitialized = false;

  @visibleForTesting
  MutableDocument get document => _document;
  
  @visibleForTesting
  Editor get editor => _editor;

  @override
  void initState() {
    super.initState();
    _composer = MutableDocumentComposer();
    _focusNode = FocusNode();
    _initEditor();
  }
  
  Future<void> _initEditor() async {
    final blocks = await ref.read(editorStateProvider(widget.pageId).future);
    
    _adapter = KetionSuperEditorAdapter(
      pageId: widget.pageId,
      ref: ref,
    );
    
    _document = _adapter.createDocument(blocks);
    _editor = createDefaultDocumentEditor(document: _document, composer: _composer, isHistoryEnabled: true);
    
    _adapter.bind(_document, _editor);
    
    _slashController = SuperEditorSlashCommandController(
      document: _document,
      composer: _composer,
      editor: _editor,
      context: () => context,
      optionsBuilder: _slashOptionsFor,
      onDismiss: () => _focusNode.requestFocus(),
    );
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _slashController.dispose();
    _focusNode.dispose();
    _adapter.dispose();
    _composer.dispose();
    super.dispose();
  }

  List<SlashCommandOption> _slashOptionsFor(String query) {
    final allOptions = [
      SlashCommandOption(
        title: 'Heading 1',
        subtitle: 'Large section heading',
        icon: Icons.title,
        onSelected: () => _convertToHeading(1),
      ),
      SlashCommandOption(
        title: 'Heading 2',
        subtitle: 'Medium section heading',
        icon: Icons.title,
        onSelected: () => _convertToHeading(2),
      ),
      SlashCommandOption(
        title: 'Heading 3',
        subtitle: 'Small section heading',
        icon: Icons.title,
        onSelected: () => _convertToHeading(3),
      ),
      SlashCommandOption(
        title: 'Checklist',
        subtitle: 'Track tasks with a to-do list',
        icon: Icons.check_box_outlined,
        onSelected: () => _convertToList('checklist'),
      ),
      SlashCommandOption(
        title: 'Bulleted List',
        subtitle: 'Create a simple bulleted list',
        icon: Icons.format_list_bulleted,
        onSelected: () => _convertToList('bullet'),
      ),
      SlashCommandOption(
        title: 'Numbered List',
        subtitle: 'Create a list with numbering',
        icon: Icons.format_list_numbered,
        onSelected: () => _convertToList('numbered'),
      ),
    ];
    
    final normalizedQuery = query.toLowerCase();
    return allOptions.where((option) {
      return normalizedQuery.isEmpty ||
          option.title.toLowerCase().contains(normalizedQuery) ||
          option.subtitle.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  void _convertToHeading(int level) {
    if (_slashController.nodeId == null) return;
    
    Attribution blockType;
    if (level == 1) {
      blockType = header1Attribution;
    } else if (level == 2) {
      blockType = header2Attribution;
    } else {
      blockType = header3Attribution;
    }
    
    _editor.execute([
      ChangeParagraphBlockTypeRequest(nodeId: _slashController.nodeId!, blockType: blockType),
    ]);
  }

  void _convertToList(String listType) {
    if (_slashController.nodeId == null) return;
    
    if (listType == 'bullet') {
      _editor.execute([
        ConvertParagraphToListItemRequest(nodeId: _slashController.nodeId!, type: ListItemType.unordered),
      ]);
    } else if (listType == 'numbered') {
      _editor.execute([
        ConvertParagraphToListItemRequest(nodeId: _slashController.nodeId!, type: ListItemType.ordered),
      ]);
    } else if (listType == 'checklist') {
      _editor.execute([
        ConvertParagraphToTaskRequest(nodeId: _slashController.nodeId!),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final pageAsync = ref.watch(pageProvider(widget.pageId));
    final page = pageAsync.valueOrNull;
    if (page == null) return const SizedBox.shrink();
    
    return Column(
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
            onKeyEvent: (node, event) {
               if (event is KeyDownEvent) {
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
                              ),
                            };
                          },
                        ),
                      ],
                    )
                  : defaultStylesheet).copyWith(
                documentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
