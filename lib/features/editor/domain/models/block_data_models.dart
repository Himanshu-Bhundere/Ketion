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
class TableCellData with _$TableCellData {
  const factory TableCellData({
    required String id,
    @Default([]) List<TextSpanData> spans,
  }) = _TableCellData;

  factory TableCellData.fromJson(Map<String, dynamic> json) =>
      _$TableCellDataFromJson(json);
}

@freezed
class TableRowData with _$TableRowData {
  const factory TableRowData({
    required String id,
    @Default([]) List<TableCellData> cells,
  }) = _TableRowData;

  factory TableRowData.fromJson(Map<String, dynamic> json) =>
      _$TableRowDataFromJson(json);
}

@freezed
sealed class BlockDataModel with _$BlockDataModel {
  const BlockDataModel._();

  const factory BlockDataModel.text({
    @Default([]) List<TextSpanData> spans,
    @Default(0) int headingLevel, // 0 for paragraph, 1, 2, 3 for H1, H2, H3
    @Default(false) bool quote,
  }) = TextBlockData;

  const factory BlockDataModel.list({
    @Default([]) List<TextSpanData> spans,
    @Default(false) bool checked,
    @Default(false) bool isExpanded,
    @Default('bullet')
    String listType, // 'bullet', 'numbered', 'checklist', 'toggle'
  }) = ListBlockData;

  const factory BlockDataModel.unknown({
    @Default({}) Map<String, dynamic> rawData,
  }) = UnknownBlockData;

  const factory BlockDataModel.callout({
    @Default([]) List<TextSpanData> spans,
    @Default('💡') String icon,
    @Default('grey') String color,
  }) = CalloutBlockData;

  const factory BlockDataModel.image({
    required String attachmentId,
    String? caption,
  }) = ImageBlockData;

  const factory BlockDataModel.video({
    required String attachmentId,
    String? caption,
  }) = VideoBlockData;

  const factory BlockDataModel.audio({
    required String attachmentId,
    String? caption,
  }) = AudioBlockData;

  const factory BlockDataModel.pdf({
    required String attachmentId,
    String? caption,
  }) = PdfBlockData;

  const factory BlockDataModel.file({
    required String attachmentId,
    String? caption,
  }) = FileBlockData;

  const factory BlockDataModel.bookmark({
    required String url,
    String? title,
    String? description,
    String? imageUrl,
  }) = BookmarkBlockData;

  const factory BlockDataModel.table({
    @Default(0) int columnCount,
    @Default([]) List<TableRowData> rows,
  }) = TableBlockData;

  const factory BlockDataModel.pageLink({
    required String pageId,
  }) = PageLinkBlockData;

  const factory BlockDataModel.webLink({
    required String url,
  }) = WebLinkBlockData;

  const factory BlockDataModel.reminder({
    @Default('') String title,
    required String dueAt,
    @Default('UTC') String timezone,
    String? recurrenceRule,
    @Default(false) bool completed,
  }) = ReminderBlockData;

  const factory BlockDataModel.divider() = DividerBlockData;

  const factory BlockDataModel.code({
    @Default('') String code,
    @Default('plaintext') String language,
    @Default(false) bool showLineNumbers,
    @Default(true) bool wrapLines,
  }) = CodeBlockData;

  factory BlockDataModel.fromJson(Map<String, dynamic> json) =>
      _$BlockDataModelFromJson(json);

  String get searchableText {
    return map(
      text: (t) => t.spans.map((s) => s.text).join(' '),
      list: (l) => l.spans.map((s) => s.text).join(' '),
      unknown: (_) => '',
      callout: (c) => c.spans.map((s) => s.text).join(' '),
      image: (i) => i.caption ?? '',
      video: (v) => v.caption ?? '',
      audio: (a) => a.caption ?? '',
      pdf: (p) => p.caption ?? '',
      file: (f) => f.caption ?? '',
      bookmark: (b) => '${b.title ?? ''} ${b.description ?? ''} ${b.url}',
      table: (t) => t.rows.expand((r) => r.cells).expand((c) => c.spans).map((s) => s.text).join(' '),
      pageLink: (PageLinkBlockData p) => p.pageId,
      webLink: (WebLinkBlockData w) => w.url,
      reminder: (ReminderBlockData r) => r.title,
      divider: (_) => '',
      code: (c) => c.code,
    );
  }
}
