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
    };

_$TextBlockDataImpl _$$TextBlockDataImplFromJson(Map<String, dynamic> json) =>
    _$TextBlockDataImpl(
      spans: (json['spans'] as List<dynamic>?)
              ?.map((e) => TextSpanData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      headingLevel: (json['headingLevel'] as num?)?.toInt() ?? 0,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$TextBlockDataImplToJson(_$TextBlockDataImpl instance) =>
    <String, dynamic>{
      'spans': instance.spans,
      'headingLevel': instance.headingLevel,
      'runtimeType': instance.$type,
    };

_$ListBlockDataImpl _$$ListBlockDataImplFromJson(Map<String, dynamic> json) =>
    _$ListBlockDataImpl(
      spans: (json['spans'] as List<dynamic>?)
              ?.map((e) => TextSpanData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      checked: json['checked'] as bool? ?? false,
      listType: json['listType'] as String? ?? 'bullet',
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ListBlockDataImplToJson(_$ListBlockDataImpl instance) =>
    <String, dynamic>{
      'spans': instance.spans,
      'checked': instance.checked,
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
