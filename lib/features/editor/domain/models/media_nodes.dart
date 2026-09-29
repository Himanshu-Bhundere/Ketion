import 'package:super_editor/super_editor.dart';

class KetionVideoNode extends BlockNode {
  KetionVideoNode({
    required this.id,
    required this.attachmentId,
    this.metadata = const {},
  });

  @override
  final String id;
  final String attachmentId;
  @override
  final Map<String, dynamic> metadata;

  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is KetionVideoNode && other.attachmentId == attachmentId;
  }

  @override
  BlockNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return KetionVideoNode(
      id: id,
      attachmentId: attachmentId,
      metadata: newMetadata,
    );
  }

  @override
  BlockNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    return KetionVideoNode(
      id: id,
      attachmentId: attachmentId,
      metadata: {
        ...metadata,
        ...newProperties,
      },
    );
  }

  @override
  String? copyContent(NodeSelection selection) {
    return null;
  }
}

class KetionAudioNode extends BlockNode {
  KetionAudioNode({
    required this.id,
    required this.attachmentId,
    this.metadata = const {},
  });

  @override
  final String id;
  final String attachmentId;
  @override
  final Map<String, dynamic> metadata;

  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is KetionAudioNode && other.attachmentId == attachmentId;
  }

  @override
  BlockNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return KetionAudioNode(
      id: id,
      attachmentId: attachmentId,
      metadata: newMetadata,
    );
  }

  @override
  BlockNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    return KetionAudioNode(
      id: id,
      attachmentId: attachmentId,
      metadata: {
        ...metadata,
        ...newProperties,
      },
    );
  }

  @override
  String? copyContent(NodeSelection selection) {
    return null;
  }
}

class KetionPdfNode extends BlockNode {
  KetionPdfNode({
    required this.id,
    required this.attachmentId,
    this.metadata = const {},
  });

  @override
  final String id;
  final String attachmentId;
  @override
  final Map<String, dynamic> metadata;

  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is KetionPdfNode && other.attachmentId == attachmentId;
  }

  @override
  BlockNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return KetionPdfNode(
      id: id,
      attachmentId: attachmentId,
      metadata: newMetadata,
    );
  }

  @override
  BlockNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    return KetionPdfNode(
      id: id,
      attachmentId: attachmentId,
      metadata: {
        ...metadata,
        ...newProperties,
      },
    );
  }

  @override
  String? copyContent(NodeSelection selection) {
    return null;
  }
}

class KetionFileNode extends BlockNode {
  KetionFileNode({
    required this.id,
    required this.attachmentId,
    this.metadata = const {},
  });

  @override
  final String id;
  final String attachmentId;
  @override
  final Map<String, dynamic> metadata;

  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is KetionFileNode && other.attachmentId == attachmentId;
  }

  @override
  BlockNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return KetionFileNode(
      id: id,
      attachmentId: attachmentId,
      metadata: newMetadata,
    );
  }

  @override
  BlockNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    return KetionFileNode(
      id: id,
      attachmentId: attachmentId,
      metadata: {
        ...metadata,
        ...newProperties,
      },
    );
  }

  @override
  String? copyContent(NodeSelection selection) {
    return null;
  }
}

class KetionBookmarkNode extends BlockNode {
  KetionBookmarkNode({
    required this.id,
    required this.url,
    this.metadata = const {},
  });

  @override
  final String id;
  final String url;
  @override
  final Map<String, dynamic> metadata;

  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is KetionBookmarkNode && other.url == url;
  }

  @override
  BlockNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return KetionBookmarkNode(
      id: id,
      url: url,
      metadata: newMetadata,
    );
  }

  @override
  BlockNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    return KetionBookmarkNode(
      id: id,
      url: url,
      metadata: {
        ...metadata,
        ...newProperties,
      },
    );
  }

  @override
  String? copyContent(NodeSelection selection) {
    return null;
  }
}


class KetionPageLinkNode extends BlockNode {
  KetionPageLinkNode({
    required this.id,
    required this.pageId,
    this.metadata = const {},
  });

  @override
  final String id;
  final String pageId;
  @override
  final Map<String, dynamic> metadata;

  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is KetionPageLinkNode && other.pageId == pageId;
  }

  @override
  BlockNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return KetionPageLinkNode(
      id: id,
      pageId: pageId,
      metadata: newMetadata,
    );
  }

  @override
  BlockNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    return KetionPageLinkNode(
      id: id,
      pageId: pageId,
      metadata: {
        ...metadata,
        ...newProperties,
      },
    );
  }

  @override
  String? copyContent(NodeSelection selection) {
    return null;
  }
}

class KetionWebLinkNode extends BlockNode {
  KetionWebLinkNode({
    required this.id,
    required this.url,
    this.metadata = const {},
  });

  @override
  final String id;
  final String url;
  @override
  final Map<String, dynamic> metadata;

  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is KetionWebLinkNode && other.url == url;
  }

  @override
  BlockNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return KetionWebLinkNode(
      id: id,
      url: url,
      metadata: newMetadata,
    );
  }

  @override
  BlockNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    return KetionWebLinkNode(
      id: id,
      url: url,
      metadata: {
        ...metadata,
        ...newProperties,
      },
    );
  }

  @override
  String? copyContent(NodeSelection selection) {
    return null;
  }
}

class KetionReminderNode extends BlockNode {
  KetionReminderNode({
    required this.id,
    this.title = '',
    required this.dueAt,
    this.timezone = 'UTC',
    this.recurrenceRule,
    this.completed = false,
    this.metadata = const {},
  });

  @override
  final String id;
  
  final String title;
  final String dueAt;
  final String timezone;
  final String? recurrenceRule;
  final bool completed;
  
  @override
  final Map<String, dynamic> metadata;

  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is KetionReminderNode && 
           other.title == title &&
           other.dueAt == dueAt && 
           other.timezone == timezone && 
           other.recurrenceRule == recurrenceRule &&
           other.completed == completed;
  }

  @override
  BlockNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return KetionReminderNode(
      id: id,
      title: title,
      dueAt: dueAt,
      timezone: timezone,
      recurrenceRule: recurrenceRule,
      completed: completed,
      metadata: newMetadata,
    );
  }

  @override
  BlockNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    return KetionReminderNode(
      id: id,
      title: title,
      dueAt: dueAt,
      timezone: timezone,
      recurrenceRule: recurrenceRule,
      completed: completed,
      metadata: {
        ...metadata,
        ...newProperties,
      },
    );
  }

  @override
  String? copyContent(NodeSelection selection) {
    return null;
  }
}
