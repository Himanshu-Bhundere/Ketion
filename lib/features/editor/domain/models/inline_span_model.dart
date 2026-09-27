import 'package:freezed_annotation/freezed_annotation.dart';

part 'inline_span_model.freezed.dart';
part 'inline_span_model.g.dart';

@freezed
class InlineSpanModel with _$InlineSpanModel {
  const factory InlineSpanModel({
    required int offset,
    required int length,
    required String type,
    String? value, // e.g. for link URL or color hex
  }) = _InlineSpanModel;

  factory InlineSpanModel.fromJson(Map<String, dynamic> json) =>
      _$InlineSpanModelFromJson(json);
}
