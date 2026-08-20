import 'package:freezed_annotation/freezed_annotation.dart';

part 'page.freezed.dart';
part 'page.g.dart';

@freezed
class Page with _$Page {
  const factory Page({
    required String id,
    String? parentPageId,
    required String title,
    String? icon,
    String? coverImage,
    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool deleted,
    @Default(1) int version,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Page;

  factory Page.fromJson(Map<String, dynamic> json) => _$PageFromJson(json);
}
