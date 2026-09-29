import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../../domain/commands/change_paragraph_metadata.dart';
import 'slash_command_menu.dart';
import 'super_editor_slash_command.dart';
import '../../domain/models/media_nodes.dart';
import '../table/ketion_table_node.dart';
import 'package:uuid/uuid.dart';

import '../../domain/commands/insert_reminder_request.dart';

class KetionSlashCommand extends SuperEditorSlashCommandOption {
  final List<EditRequest> Function(String nodeId, Document document)? getRequestsWithDoc;

  KetionSlashCommand({
    required super.title,
    required super.subtitle,
    required super.icon,
    required super.category,
    super.aliases,
    super.isSupported = true,
    this.getRequestsWithDoc,
  }) : super(
          getEditRequests: (nodeId) => [], // We will override this behavior in the controller
        );

  List<EditRequest> getEditRequestsWithDoc(String nodeId, Document document) {
    if (!isSupported || getRequestsWithDoc == null) return [];
    return getRequestsWithDoc!(nodeId, document);
  }
}

class KetionSlashCommandRegistry {
  static final List<KetionSlashCommand> _commands = [
    KetionSlashCommand(
      title: 'Heading 1',
      subtitle: 'Large section heading',
      icon: Icons.title,
      category: SlashCommandCategory.basic,
      aliases: const ['h1', 'title', 'header1'],
      getRequestsWithDoc: (nodeId, doc) => _getParagraphTypeRequests(nodeId, doc, header1Attribution),
    ),
    KetionSlashCommand(
      title: 'Heading 2',
      subtitle: 'Medium section heading',
      icon: Icons.title,
      category: SlashCommandCategory.basic,
      aliases: const ['h2', 'subtitle', 'header2'],
      getRequestsWithDoc: (nodeId, doc) => _getParagraphTypeRequests(nodeId, doc, header2Attribution),
    ),
    KetionSlashCommand(
      title: 'Heading 3',
      subtitle: 'Small section heading',
      icon: Icons.title,
      category: SlashCommandCategory.basic,
      aliases: const ['h3', 'header3'],
      getRequestsWithDoc: (nodeId, doc) => _getParagraphTypeRequests(nodeId, doc, header3Attribution),
    ),
    KetionSlashCommand(
      title: 'Quote',
      subtitle: 'Capture a quote',
      icon: Icons.format_quote,
      category: SlashCommandCategory.basic,
      aliases: const ['quote', 'blockquote', '>'],
      getRequestsWithDoc: (nodeId, doc) => _getParagraphTypeRequests(nodeId, doc, blockquoteAttribution),
    ),
    KetionSlashCommand(
      title: 'Divider',
      subtitle: 'Visually divide blocks',
      icon: Icons.horizontal_rule,
      category: SlashCommandCategory.basic,
      aliases: const ['divider', 'hr', 'line', '---'],
      getRequestsWithDoc: (nodeId, doc) => [
        InsertNodeBeforeNodeRequest(
          existingNodeId: nodeId,
          newNode: HorizontalRuleNode(id: Editor.createNodeId()),
        ),
      ],
    ),
    KetionSlashCommand(
      title: 'Code Block',
      subtitle: 'Capture a code snippet',
      icon: Icons.code,
      category: SlashCommandCategory.basic,
      aliases: const ['code', '```'],
      getRequestsWithDoc: (nodeId, doc) => _getParagraphTypeRequests(nodeId, doc, codeAttribution),
    ),
    KetionSlashCommand(
      title: 'Checklist',
      subtitle: 'Track tasks with a to-do list',
      icon: Icons.check_box_outlined,
      category: SlashCommandCategory.list,
      aliases: const ['todo', 'checkbox', 'task'],
      getRequestsWithDoc: (nodeId, doc) => _getListRequests(nodeId, doc, 'checklist'),
    ),
    KetionSlashCommand(
      title: 'Bulleted List',
      subtitle: 'Create a simple bulleted list',
      icon: Icons.format_list_bulleted,
      category: SlashCommandCategory.list,
      aliases: const ['bullet', 'unordered'],
      getRequestsWithDoc: (nodeId, doc) => _getListRequests(nodeId, doc, 'bullet'),
    ),
    KetionSlashCommand(
      title: 'Numbered List',
      subtitle: 'Create a list with numbering',
      icon: Icons.format_list_numbered,
      category: SlashCommandCategory.list,
      aliases: const ['number', 'ordered', '1.'],
      getRequestsWithDoc: (nodeId, doc) => _getListRequests(nodeId, doc, 'numbered'),
    ),
    
    // Future unsupported commands from the plan
    KetionSlashCommand(
      title: 'Callout',
      subtitle: 'Make text stand out',
      icon: Icons.lightbulb_outline,
      category: SlashCommandCategory.basic,
      aliases: const ['callout', 'info', 'alert'],
      getRequestsWithDoc: (nodeId, doc) {
        return _getParagraphMetadataRequests(nodeId, doc, {
          'blockType': const NamedAttribution('callout'),
          'icon': '💡',
          'color': 'grey',
        });
      },
    ),
    KetionSlashCommand(
      title: 'Toggle List',
      subtitle: 'Toggles can hide and show content inside',
      icon: Icons.arrow_right,
      category: SlashCommandCategory.basic,
      aliases: const ['toggle', 'expand'],
      isSupported: false,
      getRequestsWithDoc: (nodeId, doc) {
        return _getParagraphMetadataRequests(nodeId, doc, {
          'blockType': const NamedAttribution('toggle'),
          'isExpanded': true,
        });
      },
    ),
    KetionSlashCommand(
      title: 'Image',
      subtitle: 'Upload or embed with a link',
      icon: Icons.image_outlined,
      category: SlashCommandCategory.media,
      aliases: const ['image', 'picture', 'photo'],
      isSupported: false,
      getRequestsWithDoc: (nodeId, doc) => [
        InsertNodeAfterNodeRequest(
          existingNodeId: nodeId,
          newNode: ImageNode(id: Editor.createNodeId(), imageUrl: ''),
        ),
      ],
    ),
    KetionSlashCommand(
      title: 'Video',
      subtitle: 'Embed from YouTube, Vimeo...',
      icon: Icons.play_circle_outline,
      category: SlashCommandCategory.media,
      aliases: const ['video', 'movie'],
      isSupported: false,
      getRequestsWithDoc: (nodeId, doc) => [
        InsertNodeAfterNodeRequest(
          existingNodeId: nodeId,
          newNode: KetionVideoNode(id: Editor.createNodeId(), attachmentId: ''),
        ),
      ],
    ),
    KetionSlashCommand(
      title: 'Audio',
      subtitle: 'Embed from SoundCloud, Spotify...',
      icon: Icons.audiotrack,
      category: SlashCommandCategory.media,
      aliases: const ['audio', 'music', 'sound'],
      isSupported: false,
      getRequestsWithDoc: (nodeId, doc) => [
        InsertNodeAfterNodeRequest(
          existingNodeId: nodeId,
          newNode: KetionAudioNode(id: Editor.createNodeId(), attachmentId: ''),
        ),
      ],
    ),
    KetionSlashCommand(
      title: 'PDF',
      subtitle: 'Embed a PDF',
      icon: Icons.picture_as_pdf_outlined,
      category: SlashCommandCategory.media,
      aliases: const ['pdf', 'document'],
      isSupported: false,
      getRequestsWithDoc: (nodeId, doc) => [
        InsertNodeAfterNodeRequest(
          existingNodeId: nodeId,
          newNode: KetionPdfNode(id: Editor.createNodeId(), attachmentId: ''),
        ),
      ],
    ),
    KetionSlashCommand(
      title: 'File',
      subtitle: 'Upload a file',
      icon: Icons.attach_file,
      category: SlashCommandCategory.media,
      aliases: const ['file', 'attachment'],
      isSupported: false,
      getRequestsWithDoc: (nodeId, doc) => [
        InsertNodeAfterNodeRequest(
          existingNodeId: nodeId,
          newNode: KetionFileNode(id: Editor.createNodeId(), attachmentId: ''),
        ),
      ],
    ),
    KetionSlashCommand(
      title: 'Bookmark',
      subtitle: 'Save a link as a visual bookmark',
      icon: Icons.bookmark_border,
      category: SlashCommandCategory.media,
      aliases: const ['bookmark', 'link'],
      isSupported: false,
      getRequestsWithDoc: (nodeId, doc) => [
        InsertNodeAfterNodeRequest(
          existingNodeId: nodeId,
          newNode: KetionBookmarkNode(id: Editor.createNodeId(), url: ''),
        ),
      ],
    ),
    KetionSlashCommand(
      title: 'Table',
      subtitle: 'Add a table to your page',
      icon: Icons.table_chart_outlined,
      category: SlashCommandCategory.basic,
      aliases: const ['table', 'grid'],
      isSupported: true,
      getRequestsWithDoc: (nodeId, doc) {
        return [
          InsertNodeBeforeNodeRequest(
            existingNodeId: nodeId,
            newNode: KetionTableNode(
              id: Editor.createNodeId(),
              metadata: {
                'columnCount': 3,
                'rows': [
                  {
                    'id': const Uuid().v4(),
                    'cells': [
                      {'id': const Uuid().v4(), 'spans': const <dynamic>[]},
                      {'id': const Uuid().v4(), 'spans': const <dynamic>[]},
                      {'id': const Uuid().v4(), 'spans': const <dynamic>[]},
                    ],
                  },
                  {
                    'id': const Uuid().v4(),
                    'cells': [
                      {'id': const Uuid().v4(), 'spans': const <dynamic>[]},
                      {'id': const Uuid().v4(), 'spans': const <dynamic>[]},
                      {'id': const Uuid().v4(), 'spans': const <dynamic>[]},
                    ],
                  },
                  {
                    'id': const Uuid().v4(),
                    'cells': [
                      {'id': const Uuid().v4(), 'spans': const <dynamic>[]},
                      {'id': const Uuid().v4(), 'spans': const <dynamic>[]},
                      {'id': const Uuid().v4(), 'spans': const <dynamic>[]},
                    ],
                  }
                ],
              },
            ),
          ),
        ];
      },
    ),
    KetionSlashCommand(
      title: 'Link to page',
      subtitle: 'Link to another page',
      icon: Icons.insert_link,
      category: SlashCommandCategory.basic,
      aliases: const ['page', 'link'],
      isSupported: false,
      getRequestsWithDoc: (nodeId, doc) => [
        InsertNodeAfterNodeRequest(
          existingNodeId: nodeId,
          newNode: KetionPageLinkNode(id: Editor.createNodeId(), pageId: ''),
        ),
      ],
    ),
    KetionSlashCommand(
      title: 'Web Bookmark',
      subtitle: 'Save a visual link',
      icon: Icons.public,
      category: SlashCommandCategory.media,
      aliases: const ['web', 'bookmark', 'link'],
      isSupported: false,
      getRequestsWithDoc: (nodeId, doc) => [
        InsertNodeAfterNodeRequest(
          existingNodeId: nodeId,
          newNode: KetionWebLinkNode(id: Editor.createNodeId(), url: ''),
        ),
      ],
    ),
    KetionSlashCommand(
      title: 'Reminder',
      subtitle: 'Remind me later',
      icon: Icons.access_time,
      category: SlashCommandCategory.basic,
      aliases: const ['remind', 'date', 'time'],
      isSupported: true,
      getRequestsWithDoc: (nodeId, doc) => [
        InsertReminderRequest(nodeId: nodeId),
      ],
    ),
  ];

  static List<KetionSlashCommand> get allCommands => _commands;

  static List<KetionSlashCommand> getSupportedCommands() {
    return _commands.where((c) => c.isSupported).toList();
  }

  static List<KetionSlashCommand> getOptionsForQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    
    final filteredOptions = _commands.where((option) {
      if (normalizedQuery.isEmpty) return true;
      
      final matchesTitleOrSubtitle = option.title.toLowerCase().contains(normalizedQuery) ||
          option.subtitle.toLowerCase().contains(normalizedQuery);
          
      final matchesAlias = option.aliases.any((alias) => alias.toLowerCase().contains(normalizedQuery));
      
      return matchesTitleOrSubtitle || matchesAlias;
    }).toList();

    filteredOptions.sort((a, b) => a.category.index.compareTo(b.category.index));
    
    return filteredOptions;
  }

  static List<EditRequest> _getListRequests(String nodeId, Document document, String listType) {
    final node = document.getNodeById(nodeId);

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

  static List<EditRequest> _getParagraphTypeRequests(String nodeId, Document document, NamedAttribution blockType) {
    final node = document.getNodeById(nodeId);
    if (node == null) return [];
    
    if (node is ParagraphNode) {
      return [
        ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: blockType),
      ];
    }
    
    if (node is ListItemNode) {
      return [
        ConvertListItemToParagraphRequest(nodeId: nodeId),
        ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: blockType),
      ];
    }
    
    if (node is TaskNode) {
      return [
        ConvertTaskToParagraphRequest(nodeId: nodeId),
        ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: blockType),
      ];
    }
    
    return [];
  }

  static List<EditRequest> _getParagraphMetadataRequests(String nodeId, Document document, Map<String, dynamic> metadataOverrides) {
    final node = document.getNodeById(nodeId);
    if (node == null) return [];
    
    List<EditRequest> preConversion = [];
    if (node is ListItemNode) {
      preConversion = [ConvertListItemToParagraphRequest(nodeId: nodeId)];
    } else if (node is TaskNode) {
      preConversion = [ConvertTaskToParagraphRequest(nodeId: nodeId)];
    } else if (node is! ParagraphNode) {
      return []; // unsupported
    }
    
    final currentMetadata = node is ParagraphNode ? Map<String, dynamic>.from(node.metadata) : <String, dynamic>{};
    final newMetadata = {
      ...currentMetadata,
      ...metadataOverrides,
    };
    
    return [
      ...preConversion,
      ChangeParagraphMetadataRequest(nodeId: nodeId, metadata: newMetadata),
    ];
  }
}
