// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PageImpl _$$PageImplFromJson(Map<String, dynamic> json) => _$PageImpl(
      id: json['id'] as String,
      parentPageId: json['parentPageId'] as String?,
      title: json['title'] as String,
      icon: json['icon'] as String?,
      coverImage: json['coverImage'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
      isTemplate: json['isTemplate'] as bool? ?? false,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PageImplToJson(_$PageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parentPageId': instance.parentPageId,
      'title': instance.title,
      'icon': instance.icon,
      'coverImage': instance.coverImage,
      'isFavorite': instance.isFavorite,
      'isArchived': instance.isArchived,
      'deleted': instance.deleted,
      'isTemplate': instance.isTemplate,
      'version': instance.version,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
