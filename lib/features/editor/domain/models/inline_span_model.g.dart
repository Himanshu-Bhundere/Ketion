// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inline_span_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InlineSpanModelImpl _$$InlineSpanModelImplFromJson(
        Map<String, dynamic> json) =>
    _$InlineSpanModelImpl(
      offset: (json['offset'] as num).toInt(),
      length: (json['length'] as num).toInt(),
      type: json['type'] as String,
      value: json['value'] as String?,
    );

Map<String, dynamic> _$$InlineSpanModelImplToJson(
        _$InlineSpanModelImpl instance) =>
    <String, dynamic>{
      'offset': instance.offset,
      'length': instance.length,
      'type': instance.type,
      'value': instance.value,
    };
