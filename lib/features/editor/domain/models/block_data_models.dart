import 'package:freezed_annotation/freezed_annotation.dart';

part 'block_data_models.freezed.dart';
part 'block_data_models.g.dart';

@freezed
class TextSpanData with _$TextSpanData {
  const factory TextSpanData({
    required String text,
    @Default(false) bool bold,
    @Default(false) bool italic,
    @Default(false) bool underline,
    @Default(false) bool strikethrough,
    @Default(false) bool code,
    String? link,
    String? pageLink,
    String? pageLinkTitle,
  }) = _TextSpanData;

  factory TextSpanData.fromJson(Map<String, dynamic> json) =>
      _$TextSpanDataFromJson(json);
}

@freezed
sealed class BlockDataModel with _$BlockDataModel {
  const factory BlockDataModel.text({
    @Default([]) List<TextSpanData> spans,
    @Default(0) int headingLevel, // 0 for paragraph, 1, 2, 3 for H1, H2, H3
  }) = TextBlockData;

  const factory BlockDataModel.list({
    @Default([]) List<TextSpanData> spans,
    @Default(false) bool checked,
    @Default('bullet')
    String listType, // 'bullet', 'numbered', 'checklist', 'toggle'
  }) = ListBlockData;

  const factory BlockDataModel.unknown({
    @Default({}) Map<String, dynamic> rawData,
  }) = UnknownBlockData;

  const factory BlockDataModel.image({
    required String attachmentId,
    String? caption,
  }) = ImageBlockData;

  const factory BlockDataModel.file({
    required String attachmentId,
    String? caption,
  }) = FileBlockData;

  factory BlockDataModel.fromJson(Map<String, dynamic> json) =>
      _$BlockDataModelFromJson(json);
}
