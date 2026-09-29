// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_data_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TextSpanDataImpl _$$TextSpanDataImplFromJson(Map<String, dynamic> json) =>
    _$TextSpanDataImpl(
      text: json['text'] as String,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      underline: json['underline'] as bool? ?? false,
      strikethrough: json['strikethrough'] as bool? ?? false,
      code: json['code'] as bool? ?? false,
      link: json['link'] as String?,
      pageLink: json['pageLink'] as String?,
      pageLinkTitle: json['pageLinkTitle'] as String?,
    );

Map<String, dynamic> _$$TextSpanDataImplToJson(_$TextSpanDataImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'bold': instance.bold,
      'italic': instance.italic,
      'underline': instance.underline,
      'strikethrough': instance.strikethrough,
      'code': instance.code,
      'link': instance.link,
      'pageLink': instance.pageLink,
      'pageLinkTitle': instance.pageLinkTitle,
    };

_$TableCellDataImpl _$$TableCellDataImplFromJson(Map<String, dynamic> json) =>
    _$TableCellDataImpl(
      id: json['id'] as String,
      spans: (json['spans'] as List<dynamic>?)
              ?.map((e) => TextSpanData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$TableCellDataImplToJson(_$TableCellDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'spans': instance.spans.map((e) => e.toJson()).toList(),
    };

_$TableRowDataImpl _$$TableRowDataImplFromJson(Map<String, dynamic> json) =>
    _$TableRowDataImpl(
      id: json['id'] as String,
      cells: (json['cells'] as List<dynamic>?)
              ?.map((e) => TableCellData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$TableRowDataImplToJson(_$TableRowDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cells': instance.cells.map((e) => e.toJson()).toList(),
    };

_$TextBlockDataImpl _$$TextBlockDataImplFromJson(Map<String, dynamic> json) =>
    _$TextBlockDataImpl(
      spans: (json['spans'] as List<dynamic>?)
              ?.map((e) => TextSpanData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      headingLevel: (json['headingLevel'] as num?)?.toInt() ?? 0,
      quote: json['quote'] as bool? ?? false,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$TextBlockDataImplToJson(_$TextBlockDataImpl instance) =>
    <String, dynamic>{
      'spans': instance.spans.map((e) => e.toJson()).toList(),
      'headingLevel': instance.headingLevel,
      'quote': instance.quote,
      'runtimeType': instance.$type,
    };

_$ListBlockDataImpl _$$ListBlockDataImplFromJson(Map<String, dynamic> json) =>
    _$ListBlockDataImpl(
      spans: (json['spans'] as List<dynamic>?)
              ?.map((e) => TextSpanData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      checked: json['checked'] as bool? ?? false,
      isExpanded: json['isExpanded'] as bool? ?? false,
      listType: json['listType'] as String? ?? 'bullet',
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ListBlockDataImplToJson(_$ListBlockDataImpl instance) =>
    <String, dynamic>{
      'spans': instance.spans.map((e) => e.toJson()).toList(),
      'checked': instance.checked,
      'isExpanded': instance.isExpanded,
      'listType': instance.listType,
      'runtimeType': instance.$type,
    };

_$UnknownBlockDataImpl _$$UnknownBlockDataImplFromJson(
        Map<String, dynamic> json) =>
    _$UnknownBlockDataImpl(
      rawData: json['rawData'] as Map<String, dynamic>? ?? const {},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$UnknownBlockDataImplToJson(
        _$UnknownBlockDataImpl instance) =>
    <String, dynamic>{
      'rawData': instance.rawData,
      'runtimeType': instance.$type,
    };

_$CalloutBlockDataImpl _$$CalloutBlockDataImplFromJson(
        Map<String, dynamic> json) =>
    _$CalloutBlockDataImpl(
      spans: (json['spans'] as List<dynamic>?)
              ?.map((e) => TextSpanData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      icon: json['icon'] as String? ?? '💡',
      color: json['color'] as String? ?? 'grey',
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$CalloutBlockDataImplToJson(
        _$CalloutBlockDataImpl instance) =>
    <String, dynamic>{
      'spans': instance.spans.map((e) => e.toJson()).toList(),
      'icon': instance.icon,
      'color': instance.color,
      'runtimeType': instance.$type,
    };

_$ImageBlockDataImpl _$$ImageBlockDataImplFromJson(Map<String, dynamic> json) =>
    _$ImageBlockDataImpl(
      attachmentId: json['attachmentId'] as String,
      caption: json['caption'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ImageBlockDataImplToJson(
        _$ImageBlockDataImpl instance) =>
    <String, dynamic>{
      'attachmentId': instance.attachmentId,
      'caption': instance.caption,
      'runtimeType': instance.$type,
    };

_$VideoBlockDataImpl _$$VideoBlockDataImplFromJson(Map<String, dynamic> json) =>
    _$VideoBlockDataImpl(
      attachmentId: json['attachmentId'] as String,
      caption: json['caption'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$VideoBlockDataImplToJson(
        _$VideoBlockDataImpl instance) =>
    <String, dynamic>{
      'attachmentId': instance.attachmentId,
      'caption': instance.caption,
      'runtimeType': instance.$type,
    };

_$AudioBlockDataImpl _$$AudioBlockDataImplFromJson(Map<String, dynamic> json) =>
    _$AudioBlockDataImpl(
      attachmentId: json['attachmentId'] as String,
      caption: json['caption'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$AudioBlockDataImplToJson(
        _$AudioBlockDataImpl instance) =>
    <String, dynamic>{
      'attachmentId': instance.attachmentId,
      'caption': instance.caption,
      'runtimeType': instance.$type,
    };

_$PdfBlockDataImpl _$$PdfBlockDataImplFromJson(Map<String, dynamic> json) =>
    _$PdfBlockDataImpl(
      attachmentId: json['attachmentId'] as String,
      caption: json['caption'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PdfBlockDataImplToJson(_$PdfBlockDataImpl instance) =>
    <String, dynamic>{
      'attachmentId': instance.attachmentId,
      'caption': instance.caption,
      'runtimeType': instance.$type,
    };

_$FileBlockDataImpl _$$FileBlockDataImplFromJson(Map<String, dynamic> json) =>
    _$FileBlockDataImpl(
      attachmentId: json['attachmentId'] as String,
      caption: json['caption'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$FileBlockDataImplToJson(_$FileBlockDataImpl instance) =>
    <String, dynamic>{
      'attachmentId': instance.attachmentId,
      'caption': instance.caption,
      'runtimeType': instance.$type,
    };

_$BookmarkBlockDataImpl _$$BookmarkBlockDataImplFromJson(
        Map<String, dynamic> json) =>
    _$BookmarkBlockDataImpl(
      url: json['url'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$BookmarkBlockDataImplToJson(
        _$BookmarkBlockDataImpl instance) =>
    <String, dynamic>{
      'url': instance.url,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'runtimeType': instance.$type,
    };

_$TableBlockDataImpl _$$TableBlockDataImplFromJson(Map<String, dynamic> json) =>
    _$TableBlockDataImpl(
      columnCount: (json['columnCount'] as num?)?.toInt() ?? 0,
      rows: (json['rows'] as List<dynamic>?)
              ?.map((e) => TableRowData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$TableBlockDataImplToJson(
        _$TableBlockDataImpl instance) =>
    <String, dynamic>{
      'columnCount': instance.columnCount,
      'rows': instance.rows.map((e) => e.toJson()).toList(),
      'runtimeType': instance.$type,
    };

_$PageLinkBlockDataImpl _$$PageLinkBlockDataImplFromJson(
        Map<String, dynamic> json) =>
    _$PageLinkBlockDataImpl(
      pageId: json['pageId'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PageLinkBlockDataImplToJson(
        _$PageLinkBlockDataImpl instance) =>
    <String, dynamic>{
      'pageId': instance.pageId,
      'runtimeType': instance.$type,
    };

_$WebLinkBlockDataImpl _$$WebLinkBlockDataImplFromJson(
        Map<String, dynamic> json) =>
    _$WebLinkBlockDataImpl(
      url: json['url'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$WebLinkBlockDataImplToJson(
        _$WebLinkBlockDataImpl instance) =>
    <String, dynamic>{
      'url': instance.url,
      'runtimeType': instance.$type,
    };

_$ReminderBlockDataImpl _$$ReminderBlockDataImplFromJson(
        Map<String, dynamic> json) =>
    _$ReminderBlockDataImpl(
      title: json['title'] as String? ?? '',
      dueAt: json['dueAt'] as String,
      timezone: json['timezone'] as String? ?? 'UTC',
      recurrenceRule: json['recurrenceRule'] as String?,
      completed: json['completed'] as bool? ?? false,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ReminderBlockDataImplToJson(
        _$ReminderBlockDataImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'dueAt': instance.dueAt,
      'timezone': instance.timezone,
      'recurrenceRule': instance.recurrenceRule,
      'completed': instance.completed,
      'runtimeType': instance.$type,
    };

_$DividerBlockDataImpl _$$DividerBlockDataImplFromJson(
        Map<String, dynamic> json) =>
    _$DividerBlockDataImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$DividerBlockDataImplToJson(
        _$DividerBlockDataImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$CodeBlockDataImpl _$$CodeBlockDataImplFromJson(Map<String, dynamic> json) =>
    _$CodeBlockDataImpl(
      code: json['code'] as String? ?? '',
      language: json['language'] as String? ?? 'plaintext',
      showLineNumbers: json['showLineNumbers'] as bool? ?? false,
      wrapLines: json['wrapLines'] as bool? ?? true,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$CodeBlockDataImplToJson(_$CodeBlockDataImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'language': instance.language,
      'showLineNumbers': instance.showLineNumbers,
      'wrapLines': instance.wrapLines,
      'runtimeType': instance.$type,
    };
