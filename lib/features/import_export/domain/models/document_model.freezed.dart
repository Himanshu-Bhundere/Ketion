// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ExportDocument {
  String get title => throw _privateConstructorUsedError;
  List<DocumentNode> get nodes => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ExportDocumentCopyWith<ExportDocument> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportDocumentCopyWith<$Res> {
  factory $ExportDocumentCopyWith(
          ExportDocument value, $Res Function(ExportDocument) then) =
      _$ExportDocumentCopyWithImpl<$Res, ExportDocument>;
  @useResult
  $Res call(
      {String title,
      List<DocumentNode> nodes,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$ExportDocumentCopyWithImpl<$Res, $Val extends ExportDocument>
    implements $ExportDocumentCopyWith<$Res> {
  _$ExportDocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? nodes = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      nodes: null == nodes
          ? _value.nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<DocumentNode>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExportDocumentImplCopyWith<$Res>
    implements $ExportDocumentCopyWith<$Res> {
  factory _$$ExportDocumentImplCopyWith(_$ExportDocumentImpl value,
          $Res Function(_$ExportDocumentImpl) then) =
      __$$ExportDocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String title,
      List<DocumentNode> nodes,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$ExportDocumentImplCopyWithImpl<$Res>
    extends _$ExportDocumentCopyWithImpl<$Res, _$ExportDocumentImpl>
    implements _$$ExportDocumentImplCopyWith<$Res> {
  __$$ExportDocumentImplCopyWithImpl(
      _$ExportDocumentImpl _value, $Res Function(_$ExportDocumentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? nodes = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ExportDocumentImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      nodes: null == nodes
          ? _value._nodes
          : nodes // ignore: cast_nullable_to_non_nullable
              as List<DocumentNode>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$ExportDocumentImpl implements _ExportDocument {
  const _$ExportDocumentImpl(
      {required this.title,
      required final List<DocumentNode> nodes,
      this.createdAt,
      this.updatedAt})
      : _nodes = nodes;

  @override
  final String title;
  final List<DocumentNode> _nodes;
  @override
  List<DocumentNode> get nodes {
    if (_nodes is EqualUnmodifiableListView) return _nodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nodes);
  }

  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ExportDocument(title: $title, nodes: $nodes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportDocumentImpl &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._nodes, _nodes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, title,
      const DeepCollectionEquality().hash(_nodes), createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportDocumentImplCopyWith<_$ExportDocumentImpl> get copyWith =>
      __$$ExportDocumentImplCopyWithImpl<_$ExportDocumentImpl>(
          this, _$identity);
}

abstract class _ExportDocument implements ExportDocument {
  const factory _ExportDocument(
      {required final String title,
      required final List<DocumentNode> nodes,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$ExportDocumentImpl;

  @override
  String get title;
  @override
  List<DocumentNode> get nodes;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ExportDocumentImplCopyWith<_$ExportDocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DocumentNode {
  int get depth => throw _privateConstructorUsedError;
  String? get parentKey => throw _privateConstructorUsedError;
  bool get isNestedUnderToggle => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)
        paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)
        heading,
    required TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        list,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        image,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        file,
    required TResult Function(
            String icon,
            String color,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        callout,
    required TResult Function(int columnCount, List<List<String>> rows,
            int depth, String? parentKey, bool isNestedUnderToggle)
        table,
    required TResult Function(
            int depth, String? parentKey, bool isNestedUnderToggle)
        divider,
    required TResult Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)
        code,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult? Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult? Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult? Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult? Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult? Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        code,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult Function(String code, String language, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        code,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DocParagraph value) paragraph,
    required TResult Function(DocHeading value) heading,
    required TResult Function(DocList value) list,
    required TResult Function(DocImage value) image,
    required TResult Function(DocFile value) file,
    required TResult Function(DocCallout value) callout,
    required TResult Function(DocTable value) table,
    required TResult Function(DocDivider value) divider,
    required TResult Function(DocCode value) code,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DocParagraph value)? paragraph,
    TResult? Function(DocHeading value)? heading,
    TResult? Function(DocList value)? list,
    TResult? Function(DocImage value)? image,
    TResult? Function(DocFile value)? file,
    TResult? Function(DocCallout value)? callout,
    TResult? Function(DocTable value)? table,
    TResult? Function(DocDivider value)? divider,
    TResult? Function(DocCode value)? code,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DocParagraph value)? paragraph,
    TResult Function(DocHeading value)? heading,
    TResult Function(DocList value)? list,
    TResult Function(DocImage value)? image,
    TResult Function(DocFile value)? file,
    TResult Function(DocCallout value)? callout,
    TResult Function(DocTable value)? table,
    TResult Function(DocDivider value)? divider,
    TResult Function(DocCode value)? code,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DocumentNodeCopyWith<DocumentNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocumentNodeCopyWith<$Res> {
  factory $DocumentNodeCopyWith(
          DocumentNode value, $Res Function(DocumentNode) then) =
      _$DocumentNodeCopyWithImpl<$Res, DocumentNode>;
  @useResult
  $Res call({int depth, String? parentKey, bool isNestedUnderToggle});
}

/// @nodoc
class _$DocumentNodeCopyWithImpl<$Res, $Val extends DocumentNode>
    implements $DocumentNodeCopyWith<$Res> {
  _$DocumentNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? depth = null,
    Object? parentKey = freezed,
    Object? isNestedUnderToggle = null,
  }) {
    return _then(_value.copyWith(
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      parentKey: freezed == parentKey
          ? _value.parentKey
          : parentKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isNestedUnderToggle: null == isNestedUnderToggle
          ? _value.isNestedUnderToggle
          : isNestedUnderToggle // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DocParagraphImplCopyWith<$Res>
    implements $DocumentNodeCopyWith<$Res> {
  factory _$$DocParagraphImplCopyWith(
          _$DocParagraphImpl value, $Res Function(_$DocParagraphImpl) then) =
      __$$DocParagraphImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<DocumentTextSpan> spans,
      int depth,
      String? parentKey,
      bool isNestedUnderToggle});
}

/// @nodoc
class __$$DocParagraphImplCopyWithImpl<$Res>
    extends _$DocumentNodeCopyWithImpl<$Res, _$DocParagraphImpl>
    implements _$$DocParagraphImplCopyWith<$Res> {
  __$$DocParagraphImplCopyWithImpl(
      _$DocParagraphImpl _value, $Res Function(_$DocParagraphImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? spans = null,
    Object? depth = null,
    Object? parentKey = freezed,
    Object? isNestedUnderToggle = null,
  }) {
    return _then(_$DocParagraphImpl(
      spans: null == spans
          ? _value._spans
          : spans // ignore: cast_nullable_to_non_nullable
              as List<DocumentTextSpan>,
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      parentKey: freezed == parentKey
          ? _value.parentKey
          : parentKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isNestedUnderToggle: null == isNestedUnderToggle
          ? _value.isNestedUnderToggle
          : isNestedUnderToggle // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DocParagraphImpl implements DocParagraph {
  const _$DocParagraphImpl(
      {required final List<DocumentTextSpan> spans,
      this.depth = 0,
      this.parentKey,
      this.isNestedUnderToggle = false})
      : _spans = spans;

  final List<DocumentTextSpan> _spans;
  @override
  List<DocumentTextSpan> get spans {
    if (_spans is EqualUnmodifiableListView) return _spans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_spans);
  }

  @override
  @JsonKey()
  final int depth;
  @override
  final String? parentKey;
  @override
  @JsonKey()
  final bool isNestedUnderToggle;

  @override
  String toString() {
    return 'DocumentNode.paragraph(spans: $spans, depth: $depth, parentKey: $parentKey, isNestedUnderToggle: $isNestedUnderToggle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocParagraphImpl &&
            const DeepCollectionEquality().equals(other._spans, _spans) &&
            (identical(other.depth, depth) || other.depth == depth) &&
            (identical(other.parentKey, parentKey) ||
                other.parentKey == parentKey) &&
            (identical(other.isNestedUnderToggle, isNestedUnderToggle) ||
                other.isNestedUnderToggle == isNestedUnderToggle));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_spans),
      depth,
      parentKey,
      isNestedUnderToggle);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocParagraphImplCopyWith<_$DocParagraphImpl> get copyWith =>
      __$$DocParagraphImplCopyWithImpl<_$DocParagraphImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)
        paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)
        heading,
    required TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        list,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        image,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        file,
    required TResult Function(
            String icon,
            String color,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        callout,
    required TResult Function(int columnCount, List<List<String>> rows,
            int depth, String? parentKey, bool isNestedUnderToggle)
        table,
    required TResult Function(
            int depth, String? parentKey, bool isNestedUnderToggle)
        divider,
    required TResult Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)
        code,
  }) {
    return paragraph(spans, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult? Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult? Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult? Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult? Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult? Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        code,
  }) {
    return paragraph?.call(spans, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult Function(String code, String language, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        code,
    required TResult orElse(),
  }) {
    if (paragraph != null) {
      return paragraph(spans, depth, parentKey, isNestedUnderToggle);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DocParagraph value) paragraph,
    required TResult Function(DocHeading value) heading,
    required TResult Function(DocList value) list,
    required TResult Function(DocImage value) image,
    required TResult Function(DocFile value) file,
    required TResult Function(DocCallout value) callout,
    required TResult Function(DocTable value) table,
    required TResult Function(DocDivider value) divider,
    required TResult Function(DocCode value) code,
  }) {
    return paragraph(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DocParagraph value)? paragraph,
    TResult? Function(DocHeading value)? heading,
    TResult? Function(DocList value)? list,
    TResult? Function(DocImage value)? image,
    TResult? Function(DocFile value)? file,
    TResult? Function(DocCallout value)? callout,
    TResult? Function(DocTable value)? table,
    TResult? Function(DocDivider value)? divider,
    TResult? Function(DocCode value)? code,
  }) {
    return paragraph?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DocParagraph value)? paragraph,
    TResult Function(DocHeading value)? heading,
    TResult Function(DocList value)? list,
    TResult Function(DocImage value)? image,
    TResult Function(DocFile value)? file,
    TResult Function(DocCallout value)? callout,
    TResult Function(DocTable value)? table,
    TResult Function(DocDivider value)? divider,
    TResult Function(DocCode value)? code,
    required TResult orElse(),
  }) {
    if (paragraph != null) {
      return paragraph(this);
    }
    return orElse();
  }
}

abstract class DocParagraph implements DocumentNode {
  const factory DocParagraph(
      {required final List<DocumentTextSpan> spans,
      final int depth,
      final String? parentKey,
      final bool isNestedUnderToggle}) = _$DocParagraphImpl;

  List<DocumentTextSpan> get spans;
  @override
  int get depth;
  @override
  String? get parentKey;
  @override
  bool get isNestedUnderToggle;
  @override
  @JsonKey(ignore: true)
  _$$DocParagraphImplCopyWith<_$DocParagraphImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocHeadingImplCopyWith<$Res>
    implements $DocumentNodeCopyWith<$Res> {
  factory _$$DocHeadingImplCopyWith(
          _$DocHeadingImpl value, $Res Function(_$DocHeadingImpl) then) =
      __$$DocHeadingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int level,
      List<DocumentTextSpan> spans,
      int depth,
      String? parentKey,
      bool isNestedUnderToggle});
}

/// @nodoc
class __$$DocHeadingImplCopyWithImpl<$Res>
    extends _$DocumentNodeCopyWithImpl<$Res, _$DocHeadingImpl>
    implements _$$DocHeadingImplCopyWith<$Res> {
  __$$DocHeadingImplCopyWithImpl(
      _$DocHeadingImpl _value, $Res Function(_$DocHeadingImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? spans = null,
    Object? depth = null,
    Object? parentKey = freezed,
    Object? isNestedUnderToggle = null,
  }) {
    return _then(_$DocHeadingImpl(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      spans: null == spans
          ? _value._spans
          : spans // ignore: cast_nullable_to_non_nullable
              as List<DocumentTextSpan>,
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      parentKey: freezed == parentKey
          ? _value.parentKey
          : parentKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isNestedUnderToggle: null == isNestedUnderToggle
          ? _value.isNestedUnderToggle
          : isNestedUnderToggle // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DocHeadingImpl implements DocHeading {
  const _$DocHeadingImpl(
      {required this.level,
      required final List<DocumentTextSpan> spans,
      this.depth = 0,
      this.parentKey,
      this.isNestedUnderToggle = false})
      : _spans = spans;

  @override
  final int level;
  final List<DocumentTextSpan> _spans;
  @override
  List<DocumentTextSpan> get spans {
    if (_spans is EqualUnmodifiableListView) return _spans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_spans);
  }

  @override
  @JsonKey()
  final int depth;
  @override
  final String? parentKey;
  @override
  @JsonKey()
  final bool isNestedUnderToggle;

  @override
  String toString() {
    return 'DocumentNode.heading(level: $level, spans: $spans, depth: $depth, parentKey: $parentKey, isNestedUnderToggle: $isNestedUnderToggle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocHeadingImpl &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality().equals(other._spans, _spans) &&
            (identical(other.depth, depth) || other.depth == depth) &&
            (identical(other.parentKey, parentKey) ||
                other.parentKey == parentKey) &&
            (identical(other.isNestedUnderToggle, isNestedUnderToggle) ||
                other.isNestedUnderToggle == isNestedUnderToggle));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      level,
      const DeepCollectionEquality().hash(_spans),
      depth,
      parentKey,
      isNestedUnderToggle);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocHeadingImplCopyWith<_$DocHeadingImpl> get copyWith =>
      __$$DocHeadingImplCopyWithImpl<_$DocHeadingImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)
        paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)
        heading,
    required TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        list,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        image,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        file,
    required TResult Function(
            String icon,
            String color,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        callout,
    required TResult Function(int columnCount, List<List<String>> rows,
            int depth, String? parentKey, bool isNestedUnderToggle)
        table,
    required TResult Function(
            int depth, String? parentKey, bool isNestedUnderToggle)
        divider,
    required TResult Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)
        code,
  }) {
    return heading(level, spans, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult? Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult? Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult? Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult? Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult? Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        code,
  }) {
    return heading?.call(level, spans, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult Function(String code, String language, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        code,
    required TResult orElse(),
  }) {
    if (heading != null) {
      return heading(level, spans, depth, parentKey, isNestedUnderToggle);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DocParagraph value) paragraph,
    required TResult Function(DocHeading value) heading,
    required TResult Function(DocList value) list,
    required TResult Function(DocImage value) image,
    required TResult Function(DocFile value) file,
    required TResult Function(DocCallout value) callout,
    required TResult Function(DocTable value) table,
    required TResult Function(DocDivider value) divider,
    required TResult Function(DocCode value) code,
  }) {
    return heading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DocParagraph value)? paragraph,
    TResult? Function(DocHeading value)? heading,
    TResult? Function(DocList value)? list,
    TResult? Function(DocImage value)? image,
    TResult? Function(DocFile value)? file,
    TResult? Function(DocCallout value)? callout,
    TResult? Function(DocTable value)? table,
    TResult? Function(DocDivider value)? divider,
    TResult? Function(DocCode value)? code,
  }) {
    return heading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DocParagraph value)? paragraph,
    TResult Function(DocHeading value)? heading,
    TResult Function(DocList value)? list,
    TResult Function(DocImage value)? image,
    TResult Function(DocFile value)? file,
    TResult Function(DocCallout value)? callout,
    TResult Function(DocTable value)? table,
    TResult Function(DocDivider value)? divider,
    TResult Function(DocCode value)? code,
    required TResult orElse(),
  }) {
    if (heading != null) {
      return heading(this);
    }
    return orElse();
  }
}

abstract class DocHeading implements DocumentNode {
  const factory DocHeading(
      {required final int level,
      required final List<DocumentTextSpan> spans,
      final int depth,
      final String? parentKey,
      final bool isNestedUnderToggle}) = _$DocHeadingImpl;

  int get level;
  List<DocumentTextSpan> get spans;
  @override
  int get depth;
  @override
  String? get parentKey;
  @override
  bool get isNestedUnderToggle;
  @override
  @JsonKey(ignore: true)
  _$$DocHeadingImplCopyWith<_$DocHeadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocListImplCopyWith<$Res>
    implements $DocumentNodeCopyWith<$Res> {
  factory _$$DocListImplCopyWith(
          _$DocListImpl value, $Res Function(_$DocListImpl) then) =
      __$$DocListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String listType,
      bool checked,
      List<DocumentTextSpan> spans,
      int depth,
      String? parentKey,
      bool isNestedUnderToggle});
}

/// @nodoc
class __$$DocListImplCopyWithImpl<$Res>
    extends _$DocumentNodeCopyWithImpl<$Res, _$DocListImpl>
    implements _$$DocListImplCopyWith<$Res> {
  __$$DocListImplCopyWithImpl(
      _$DocListImpl _value, $Res Function(_$DocListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? listType = null,
    Object? checked = null,
    Object? spans = null,
    Object? depth = null,
    Object? parentKey = freezed,
    Object? isNestedUnderToggle = null,
  }) {
    return _then(_$DocListImpl(
      listType: null == listType
          ? _value.listType
          : listType // ignore: cast_nullable_to_non_nullable
              as String,
      checked: null == checked
          ? _value.checked
          : checked // ignore: cast_nullable_to_non_nullable
              as bool,
      spans: null == spans
          ? _value._spans
          : spans // ignore: cast_nullable_to_non_nullable
              as List<DocumentTextSpan>,
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      parentKey: freezed == parentKey
          ? _value.parentKey
          : parentKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isNestedUnderToggle: null == isNestedUnderToggle
          ? _value.isNestedUnderToggle
          : isNestedUnderToggle // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DocListImpl implements DocList {
  const _$DocListImpl(
      {required this.listType,
      required this.checked,
      required final List<DocumentTextSpan> spans,
      this.depth = 0,
      this.parentKey,
      this.isNestedUnderToggle = false})
      : _spans = spans;

  @override
  final String listType;
// 'bullet', 'numbered', 'checklist', 'toggle'
  @override
  final bool checked;
  final List<DocumentTextSpan> _spans;
  @override
  List<DocumentTextSpan> get spans {
    if (_spans is EqualUnmodifiableListView) return _spans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_spans);
  }

  @override
  @JsonKey()
  final int depth;
  @override
  final String? parentKey;
  @override
  @JsonKey()
  final bool isNestedUnderToggle;

  @override
  String toString() {
    return 'DocumentNode.list(listType: $listType, checked: $checked, spans: $spans, depth: $depth, parentKey: $parentKey, isNestedUnderToggle: $isNestedUnderToggle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocListImpl &&
            (identical(other.listType, listType) ||
                other.listType == listType) &&
            (identical(other.checked, checked) || other.checked == checked) &&
            const DeepCollectionEquality().equals(other._spans, _spans) &&
            (identical(other.depth, depth) || other.depth == depth) &&
            (identical(other.parentKey, parentKey) ||
                other.parentKey == parentKey) &&
            (identical(other.isNestedUnderToggle, isNestedUnderToggle) ||
                other.isNestedUnderToggle == isNestedUnderToggle));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      listType,
      checked,
      const DeepCollectionEquality().hash(_spans),
      depth,
      parentKey,
      isNestedUnderToggle);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocListImplCopyWith<_$DocListImpl> get copyWith =>
      __$$DocListImplCopyWithImpl<_$DocListImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)
        paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)
        heading,
    required TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        list,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        image,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        file,
    required TResult Function(
            String icon,
            String color,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        callout,
    required TResult Function(int columnCount, List<List<String>> rows,
            int depth, String? parentKey, bool isNestedUnderToggle)
        table,
    required TResult Function(
            int depth, String? parentKey, bool isNestedUnderToggle)
        divider,
    required TResult Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)
        code,
  }) {
    return list(
        listType, checked, spans, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult? Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult? Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult? Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult? Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult? Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        code,
  }) {
    return list?.call(
        listType, checked, spans, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult Function(String code, String language, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        code,
    required TResult orElse(),
  }) {
    if (list != null) {
      return list(
          listType, checked, spans, depth, parentKey, isNestedUnderToggle);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DocParagraph value) paragraph,
    required TResult Function(DocHeading value) heading,
    required TResult Function(DocList value) list,
    required TResult Function(DocImage value) image,
    required TResult Function(DocFile value) file,
    required TResult Function(DocCallout value) callout,
    required TResult Function(DocTable value) table,
    required TResult Function(DocDivider value) divider,
    required TResult Function(DocCode value) code,
  }) {
    return list(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DocParagraph value)? paragraph,
    TResult? Function(DocHeading value)? heading,
    TResult? Function(DocList value)? list,
    TResult? Function(DocImage value)? image,
    TResult? Function(DocFile value)? file,
    TResult? Function(DocCallout value)? callout,
    TResult? Function(DocTable value)? table,
    TResult? Function(DocDivider value)? divider,
    TResult? Function(DocCode value)? code,
  }) {
    return list?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DocParagraph value)? paragraph,
    TResult Function(DocHeading value)? heading,
    TResult Function(DocList value)? list,
    TResult Function(DocImage value)? image,
    TResult Function(DocFile value)? file,
    TResult Function(DocCallout value)? callout,
    TResult Function(DocTable value)? table,
    TResult Function(DocDivider value)? divider,
    TResult Function(DocCode value)? code,
    required TResult orElse(),
  }) {
    if (list != null) {
      return list(this);
    }
    return orElse();
  }
}

abstract class DocList implements DocumentNode {
  const factory DocList(
      {required final String listType,
      required final bool checked,
      required final List<DocumentTextSpan> spans,
      final int depth,
      final String? parentKey,
      final bool isNestedUnderToggle}) = _$DocListImpl;

  String get listType; // 'bullet', 'numbered', 'checklist', 'toggle'
  bool get checked;
  List<DocumentTextSpan> get spans;
  @override
  int get depth;
  @override
  String? get parentKey;
  @override
  bool get isNestedUnderToggle;
  @override
  @JsonKey(ignore: true)
  _$$DocListImplCopyWith<_$DocListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocImageImplCopyWith<$Res>
    implements $DocumentNodeCopyWith<$Res> {
  factory _$$DocImageImplCopyWith(
          _$DocImageImpl value, $Res Function(_$DocImageImpl) then) =
      __$$DocImageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String attachmentId,
      String? caption,
      String? fileName,
      Uint8List? imageBytes,
      bool isAvailable,
      int depth,
      String? parentKey,
      bool isNestedUnderToggle});
}

/// @nodoc
class __$$DocImageImplCopyWithImpl<$Res>
    extends _$DocumentNodeCopyWithImpl<$Res, _$DocImageImpl>
    implements _$$DocImageImplCopyWith<$Res> {
  __$$DocImageImplCopyWithImpl(
      _$DocImageImpl _value, $Res Function(_$DocImageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? attachmentId = null,
    Object? caption = freezed,
    Object? fileName = freezed,
    Object? imageBytes = freezed,
    Object? isAvailable = null,
    Object? depth = null,
    Object? parentKey = freezed,
    Object? isNestedUnderToggle = null,
  }) {
    return _then(_$DocImageImpl(
      attachmentId: null == attachmentId
          ? _value.attachmentId
          : attachmentId // ignore: cast_nullable_to_non_nullable
              as String,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      imageBytes: freezed == imageBytes
          ? _value.imageBytes
          : imageBytes // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      parentKey: freezed == parentKey
          ? _value.parentKey
          : parentKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isNestedUnderToggle: null == isNestedUnderToggle
          ? _value.isNestedUnderToggle
          : isNestedUnderToggle // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DocImageImpl implements DocImage {
  const _$DocImageImpl(
      {required this.attachmentId,
      this.caption,
      this.fileName,
      this.imageBytes,
      this.isAvailable = true,
      this.depth = 0,
      this.parentKey,
      this.isNestedUnderToggle = false});

  @override
  final String attachmentId;
  @override
  final String? caption;
  @override
  final String? fileName;
  @override
  final Uint8List? imageBytes;
  @override
  @JsonKey()
  final bool isAvailable;
  @override
  @JsonKey()
  final int depth;
  @override
  final String? parentKey;
  @override
  @JsonKey()
  final bool isNestedUnderToggle;

  @override
  String toString() {
    return 'DocumentNode.image(attachmentId: $attachmentId, caption: $caption, fileName: $fileName, imageBytes: $imageBytes, isAvailable: $isAvailable, depth: $depth, parentKey: $parentKey, isNestedUnderToggle: $isNestedUnderToggle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocImageImpl &&
            (identical(other.attachmentId, attachmentId) ||
                other.attachmentId == attachmentId) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            const DeepCollectionEquality()
                .equals(other.imageBytes, imageBytes) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.depth, depth) || other.depth == depth) &&
            (identical(other.parentKey, parentKey) ||
                other.parentKey == parentKey) &&
            (identical(other.isNestedUnderToggle, isNestedUnderToggle) ||
                other.isNestedUnderToggle == isNestedUnderToggle));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      attachmentId,
      caption,
      fileName,
      const DeepCollectionEquality().hash(imageBytes),
      isAvailable,
      depth,
      parentKey,
      isNestedUnderToggle);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocImageImplCopyWith<_$DocImageImpl> get copyWith =>
      __$$DocImageImplCopyWithImpl<_$DocImageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)
        paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)
        heading,
    required TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        list,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        image,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        file,
    required TResult Function(
            String icon,
            String color,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        callout,
    required TResult Function(int columnCount, List<List<String>> rows,
            int depth, String? parentKey, bool isNestedUnderToggle)
        table,
    required TResult Function(
            int depth, String? parentKey, bool isNestedUnderToggle)
        divider,
    required TResult Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)
        code,
  }) {
    return image(attachmentId, caption, fileName, imageBytes, isAvailable,
        depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult? Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult? Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult? Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult? Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult? Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        code,
  }) {
    return image?.call(attachmentId, caption, fileName, imageBytes, isAvailable,
        depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult Function(String code, String language, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        code,
    required TResult orElse(),
  }) {
    if (image != null) {
      return image(attachmentId, caption, fileName, imageBytes, isAvailable,
          depth, parentKey, isNestedUnderToggle);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DocParagraph value) paragraph,
    required TResult Function(DocHeading value) heading,
    required TResult Function(DocList value) list,
    required TResult Function(DocImage value) image,
    required TResult Function(DocFile value) file,
    required TResult Function(DocCallout value) callout,
    required TResult Function(DocTable value) table,
    required TResult Function(DocDivider value) divider,
    required TResult Function(DocCode value) code,
  }) {
    return image(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DocParagraph value)? paragraph,
    TResult? Function(DocHeading value)? heading,
    TResult? Function(DocList value)? list,
    TResult? Function(DocImage value)? image,
    TResult? Function(DocFile value)? file,
    TResult? Function(DocCallout value)? callout,
    TResult? Function(DocTable value)? table,
    TResult? Function(DocDivider value)? divider,
    TResult? Function(DocCode value)? code,
  }) {
    return image?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DocParagraph value)? paragraph,
    TResult Function(DocHeading value)? heading,
    TResult Function(DocList value)? list,
    TResult Function(DocImage value)? image,
    TResult Function(DocFile value)? file,
    TResult Function(DocCallout value)? callout,
    TResult Function(DocTable value)? table,
    TResult Function(DocDivider value)? divider,
    TResult Function(DocCode value)? code,
    required TResult orElse(),
  }) {
    if (image != null) {
      return image(this);
    }
    return orElse();
  }
}

abstract class DocImage implements DocumentNode {
  const factory DocImage(
      {required final String attachmentId,
      final String? caption,
      final String? fileName,
      final Uint8List? imageBytes,
      final bool isAvailable,
      final int depth,
      final String? parentKey,
      final bool isNestedUnderToggle}) = _$DocImageImpl;

  String get attachmentId;
  String? get caption;
  String? get fileName;
  Uint8List? get imageBytes;
  bool get isAvailable;
  @override
  int get depth;
  @override
  String? get parentKey;
  @override
  bool get isNestedUnderToggle;
  @override
  @JsonKey(ignore: true)
  _$$DocImageImplCopyWith<_$DocImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocFileImplCopyWith<$Res>
    implements $DocumentNodeCopyWith<$Res> {
  factory _$$DocFileImplCopyWith(
          _$DocFileImpl value, $Res Function(_$DocFileImpl) then) =
      __$$DocFileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String attachmentId,
      String? caption,
      String? fileName,
      String? mimeType,
      int? fileSize,
      String fileTypeLabel,
      bool isAvailable,
      int depth,
      String? parentKey,
      bool isNestedUnderToggle});
}

/// @nodoc
class __$$DocFileImplCopyWithImpl<$Res>
    extends _$DocumentNodeCopyWithImpl<$Res, _$DocFileImpl>
    implements _$$DocFileImplCopyWith<$Res> {
  __$$DocFileImplCopyWithImpl(
      _$DocFileImpl _value, $Res Function(_$DocFileImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? attachmentId = null,
    Object? caption = freezed,
    Object? fileName = freezed,
    Object? mimeType = freezed,
    Object? fileSize = freezed,
    Object? fileTypeLabel = null,
    Object? isAvailable = null,
    Object? depth = null,
    Object? parentKey = freezed,
    Object? isNestedUnderToggle = null,
  }) {
    return _then(_$DocFileImpl(
      attachmentId: null == attachmentId
          ? _value.attachmentId
          : attachmentId // ignore: cast_nullable_to_non_nullable
              as String,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      mimeType: freezed == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      fileTypeLabel: null == fileTypeLabel
          ? _value.fileTypeLabel
          : fileTypeLabel // ignore: cast_nullable_to_non_nullable
              as String,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      parentKey: freezed == parentKey
          ? _value.parentKey
          : parentKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isNestedUnderToggle: null == isNestedUnderToggle
          ? _value.isNestedUnderToggle
          : isNestedUnderToggle // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DocFileImpl implements DocFile {
  const _$DocFileImpl(
      {required this.attachmentId,
      this.caption,
      this.fileName,
      this.mimeType,
      this.fileSize,
      this.fileTypeLabel = 'File',
      this.isAvailable = true,
      this.depth = 0,
      this.parentKey,
      this.isNestedUnderToggle = false});

  @override
  final String attachmentId;
  @override
  final String? caption;
  @override
  final String? fileName;
  @override
  final String? mimeType;
  @override
  final int? fileSize;
  @override
  @JsonKey()
  final String fileTypeLabel;
  @override
  @JsonKey()
  final bool isAvailable;
  @override
  @JsonKey()
  final int depth;
  @override
  final String? parentKey;
  @override
  @JsonKey()
  final bool isNestedUnderToggle;

  @override
  String toString() {
    return 'DocumentNode.file(attachmentId: $attachmentId, caption: $caption, fileName: $fileName, mimeType: $mimeType, fileSize: $fileSize, fileTypeLabel: $fileTypeLabel, isAvailable: $isAvailable, depth: $depth, parentKey: $parentKey, isNestedUnderToggle: $isNestedUnderToggle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocFileImpl &&
            (identical(other.attachmentId, attachmentId) ||
                other.attachmentId == attachmentId) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.fileTypeLabel, fileTypeLabel) ||
                other.fileTypeLabel == fileTypeLabel) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.depth, depth) || other.depth == depth) &&
            (identical(other.parentKey, parentKey) ||
                other.parentKey == parentKey) &&
            (identical(other.isNestedUnderToggle, isNestedUnderToggle) ||
                other.isNestedUnderToggle == isNestedUnderToggle));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      attachmentId,
      caption,
      fileName,
      mimeType,
      fileSize,
      fileTypeLabel,
      isAvailable,
      depth,
      parentKey,
      isNestedUnderToggle);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocFileImplCopyWith<_$DocFileImpl> get copyWith =>
      __$$DocFileImplCopyWithImpl<_$DocFileImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)
        paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)
        heading,
    required TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        list,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        image,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        file,
    required TResult Function(
            String icon,
            String color,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        callout,
    required TResult Function(int columnCount, List<List<String>> rows,
            int depth, String? parentKey, bool isNestedUnderToggle)
        table,
    required TResult Function(
            int depth, String? parentKey, bool isNestedUnderToggle)
        divider,
    required TResult Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)
        code,
  }) {
    return file(attachmentId, caption, fileName, mimeType, fileSize,
        fileTypeLabel, isAvailable, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult? Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult? Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult? Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult? Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult? Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        code,
  }) {
    return file?.call(attachmentId, caption, fileName, mimeType, fileSize,
        fileTypeLabel, isAvailable, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult Function(String code, String language, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        code,
    required TResult orElse(),
  }) {
    if (file != null) {
      return file(attachmentId, caption, fileName, mimeType, fileSize,
          fileTypeLabel, isAvailable, depth, parentKey, isNestedUnderToggle);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DocParagraph value) paragraph,
    required TResult Function(DocHeading value) heading,
    required TResult Function(DocList value) list,
    required TResult Function(DocImage value) image,
    required TResult Function(DocFile value) file,
    required TResult Function(DocCallout value) callout,
    required TResult Function(DocTable value) table,
    required TResult Function(DocDivider value) divider,
    required TResult Function(DocCode value) code,
  }) {
    return file(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DocParagraph value)? paragraph,
    TResult? Function(DocHeading value)? heading,
    TResult? Function(DocList value)? list,
    TResult? Function(DocImage value)? image,
    TResult? Function(DocFile value)? file,
    TResult? Function(DocCallout value)? callout,
    TResult? Function(DocTable value)? table,
    TResult? Function(DocDivider value)? divider,
    TResult? Function(DocCode value)? code,
  }) {
    return file?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DocParagraph value)? paragraph,
    TResult Function(DocHeading value)? heading,
    TResult Function(DocList value)? list,
    TResult Function(DocImage value)? image,
    TResult Function(DocFile value)? file,
    TResult Function(DocCallout value)? callout,
    TResult Function(DocTable value)? table,
    TResult Function(DocDivider value)? divider,
    TResult Function(DocCode value)? code,
    required TResult orElse(),
  }) {
    if (file != null) {
      return file(this);
    }
    return orElse();
  }
}

abstract class DocFile implements DocumentNode {
  const factory DocFile(
      {required final String attachmentId,
      final String? caption,
      final String? fileName,
      final String? mimeType,
      final int? fileSize,
      final String fileTypeLabel,
      final bool isAvailable,
      final int depth,
      final String? parentKey,
      final bool isNestedUnderToggle}) = _$DocFileImpl;

  String get attachmentId;
  String? get caption;
  String? get fileName;
  String? get mimeType;
  int? get fileSize;
  String get fileTypeLabel;
  bool get isAvailable;
  @override
  int get depth;
  @override
  String? get parentKey;
  @override
  bool get isNestedUnderToggle;
  @override
  @JsonKey(ignore: true)
  _$$DocFileImplCopyWith<_$DocFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocCalloutImplCopyWith<$Res>
    implements $DocumentNodeCopyWith<$Res> {
  factory _$$DocCalloutImplCopyWith(
          _$DocCalloutImpl value, $Res Function(_$DocCalloutImpl) then) =
      __$$DocCalloutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String icon,
      String color,
      List<DocumentTextSpan> spans,
      int depth,
      String? parentKey,
      bool isNestedUnderToggle});
}

/// @nodoc
class __$$DocCalloutImplCopyWithImpl<$Res>
    extends _$DocumentNodeCopyWithImpl<$Res, _$DocCalloutImpl>
    implements _$$DocCalloutImplCopyWith<$Res> {
  __$$DocCalloutImplCopyWithImpl(
      _$DocCalloutImpl _value, $Res Function(_$DocCalloutImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? icon = null,
    Object? color = null,
    Object? spans = null,
    Object? depth = null,
    Object? parentKey = freezed,
    Object? isNestedUnderToggle = null,
  }) {
    return _then(_$DocCalloutImpl(
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      spans: null == spans
          ? _value._spans
          : spans // ignore: cast_nullable_to_non_nullable
              as List<DocumentTextSpan>,
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      parentKey: freezed == parentKey
          ? _value.parentKey
          : parentKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isNestedUnderToggle: null == isNestedUnderToggle
          ? _value.isNestedUnderToggle
          : isNestedUnderToggle // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DocCalloutImpl implements DocCallout {
  const _$DocCalloutImpl(
      {required this.icon,
      required this.color,
      required final List<DocumentTextSpan> spans,
      this.depth = 0,
      this.parentKey,
      this.isNestedUnderToggle = false})
      : _spans = spans;

  @override
  final String icon;
  @override
  final String color;
  final List<DocumentTextSpan> _spans;
  @override
  List<DocumentTextSpan> get spans {
    if (_spans is EqualUnmodifiableListView) return _spans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_spans);
  }

  @override
  @JsonKey()
  final int depth;
  @override
  final String? parentKey;
  @override
  @JsonKey()
  final bool isNestedUnderToggle;

  @override
  String toString() {
    return 'DocumentNode.callout(icon: $icon, color: $color, spans: $spans, depth: $depth, parentKey: $parentKey, isNestedUnderToggle: $isNestedUnderToggle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocCalloutImpl &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.color, color) || other.color == color) &&
            const DeepCollectionEquality().equals(other._spans, _spans) &&
            (identical(other.depth, depth) || other.depth == depth) &&
            (identical(other.parentKey, parentKey) ||
                other.parentKey == parentKey) &&
            (identical(other.isNestedUnderToggle, isNestedUnderToggle) ||
                other.isNestedUnderToggle == isNestedUnderToggle));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      icon,
      color,
      const DeepCollectionEquality().hash(_spans),
      depth,
      parentKey,
      isNestedUnderToggle);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocCalloutImplCopyWith<_$DocCalloutImpl> get copyWith =>
      __$$DocCalloutImplCopyWithImpl<_$DocCalloutImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)
        paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)
        heading,
    required TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        list,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        image,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        file,
    required TResult Function(
            String icon,
            String color,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        callout,
    required TResult Function(int columnCount, List<List<String>> rows,
            int depth, String? parentKey, bool isNestedUnderToggle)
        table,
    required TResult Function(
            int depth, String? parentKey, bool isNestedUnderToggle)
        divider,
    required TResult Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)
        code,
  }) {
    return callout(icon, color, spans, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult? Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult? Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult? Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult? Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult? Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        code,
  }) {
    return callout?.call(
        icon, color, spans, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult Function(String code, String language, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        code,
    required TResult orElse(),
  }) {
    if (callout != null) {
      return callout(icon, color, spans, depth, parentKey, isNestedUnderToggle);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DocParagraph value) paragraph,
    required TResult Function(DocHeading value) heading,
    required TResult Function(DocList value) list,
    required TResult Function(DocImage value) image,
    required TResult Function(DocFile value) file,
    required TResult Function(DocCallout value) callout,
    required TResult Function(DocTable value) table,
    required TResult Function(DocDivider value) divider,
    required TResult Function(DocCode value) code,
  }) {
    return callout(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DocParagraph value)? paragraph,
    TResult? Function(DocHeading value)? heading,
    TResult? Function(DocList value)? list,
    TResult? Function(DocImage value)? image,
    TResult? Function(DocFile value)? file,
    TResult? Function(DocCallout value)? callout,
    TResult? Function(DocTable value)? table,
    TResult? Function(DocDivider value)? divider,
    TResult? Function(DocCode value)? code,
  }) {
    return callout?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DocParagraph value)? paragraph,
    TResult Function(DocHeading value)? heading,
    TResult Function(DocList value)? list,
    TResult Function(DocImage value)? image,
    TResult Function(DocFile value)? file,
    TResult Function(DocCallout value)? callout,
    TResult Function(DocTable value)? table,
    TResult Function(DocDivider value)? divider,
    TResult Function(DocCode value)? code,
    required TResult orElse(),
  }) {
    if (callout != null) {
      return callout(this);
    }
    return orElse();
  }
}

abstract class DocCallout implements DocumentNode {
  const factory DocCallout(
      {required final String icon,
      required final String color,
      required final List<DocumentTextSpan> spans,
      final int depth,
      final String? parentKey,
      final bool isNestedUnderToggle}) = _$DocCalloutImpl;

  String get icon;
  String get color;
  List<DocumentTextSpan> get spans;
  @override
  int get depth;
  @override
  String? get parentKey;
  @override
  bool get isNestedUnderToggle;
  @override
  @JsonKey(ignore: true)
  _$$DocCalloutImplCopyWith<_$DocCalloutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocTableImplCopyWith<$Res>
    implements $DocumentNodeCopyWith<$Res> {
  factory _$$DocTableImplCopyWith(
          _$DocTableImpl value, $Res Function(_$DocTableImpl) then) =
      __$$DocTableImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int columnCount,
      List<List<String>> rows,
      int depth,
      String? parentKey,
      bool isNestedUnderToggle});
}

/// @nodoc
class __$$DocTableImplCopyWithImpl<$Res>
    extends _$DocumentNodeCopyWithImpl<$Res, _$DocTableImpl>
    implements _$$DocTableImplCopyWith<$Res> {
  __$$DocTableImplCopyWithImpl(
      _$DocTableImpl _value, $Res Function(_$DocTableImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? columnCount = null,
    Object? rows = null,
    Object? depth = null,
    Object? parentKey = freezed,
    Object? isNestedUnderToggle = null,
  }) {
    return _then(_$DocTableImpl(
      columnCount: null == columnCount
          ? _value.columnCount
          : columnCount // ignore: cast_nullable_to_non_nullable
              as int,
      rows: null == rows
          ? _value._rows
          : rows // ignore: cast_nullable_to_non_nullable
              as List<List<String>>,
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      parentKey: freezed == parentKey
          ? _value.parentKey
          : parentKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isNestedUnderToggle: null == isNestedUnderToggle
          ? _value.isNestedUnderToggle
          : isNestedUnderToggle // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DocTableImpl implements DocTable {
  const _$DocTableImpl(
      {required this.columnCount,
      required final List<List<String>> rows,
      this.depth = 0,
      this.parentKey,
      this.isNestedUnderToggle = false})
      : _rows = rows;

  @override
  final int columnCount;
  final List<List<String>> _rows;
  @override
  List<List<String>> get rows {
    if (_rows is EqualUnmodifiableListView) return _rows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rows);
  }

  @override
  @JsonKey()
  final int depth;
  @override
  final String? parentKey;
  @override
  @JsonKey()
  final bool isNestedUnderToggle;

  @override
  String toString() {
    return 'DocumentNode.table(columnCount: $columnCount, rows: $rows, depth: $depth, parentKey: $parentKey, isNestedUnderToggle: $isNestedUnderToggle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocTableImpl &&
            (identical(other.columnCount, columnCount) ||
                other.columnCount == columnCount) &&
            const DeepCollectionEquality().equals(other._rows, _rows) &&
            (identical(other.depth, depth) || other.depth == depth) &&
            (identical(other.parentKey, parentKey) ||
                other.parentKey == parentKey) &&
            (identical(other.isNestedUnderToggle, isNestedUnderToggle) ||
                other.isNestedUnderToggle == isNestedUnderToggle));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      columnCount,
      const DeepCollectionEquality().hash(_rows),
      depth,
      parentKey,
      isNestedUnderToggle);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocTableImplCopyWith<_$DocTableImpl> get copyWith =>
      __$$DocTableImplCopyWithImpl<_$DocTableImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)
        paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)
        heading,
    required TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        list,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        image,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        file,
    required TResult Function(
            String icon,
            String color,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        callout,
    required TResult Function(int columnCount, List<List<String>> rows,
            int depth, String? parentKey, bool isNestedUnderToggle)
        table,
    required TResult Function(
            int depth, String? parentKey, bool isNestedUnderToggle)
        divider,
    required TResult Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)
        code,
  }) {
    return table(columnCount, rows, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult? Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult? Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult? Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult? Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult? Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        code,
  }) {
    return table?.call(
        columnCount, rows, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult Function(String code, String language, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        code,
    required TResult orElse(),
  }) {
    if (table != null) {
      return table(columnCount, rows, depth, parentKey, isNestedUnderToggle);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DocParagraph value) paragraph,
    required TResult Function(DocHeading value) heading,
    required TResult Function(DocList value) list,
    required TResult Function(DocImage value) image,
    required TResult Function(DocFile value) file,
    required TResult Function(DocCallout value) callout,
    required TResult Function(DocTable value) table,
    required TResult Function(DocDivider value) divider,
    required TResult Function(DocCode value) code,
  }) {
    return table(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DocParagraph value)? paragraph,
    TResult? Function(DocHeading value)? heading,
    TResult? Function(DocList value)? list,
    TResult? Function(DocImage value)? image,
    TResult? Function(DocFile value)? file,
    TResult? Function(DocCallout value)? callout,
    TResult? Function(DocTable value)? table,
    TResult? Function(DocDivider value)? divider,
    TResult? Function(DocCode value)? code,
  }) {
    return table?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DocParagraph value)? paragraph,
    TResult Function(DocHeading value)? heading,
    TResult Function(DocList value)? list,
    TResult Function(DocImage value)? image,
    TResult Function(DocFile value)? file,
    TResult Function(DocCallout value)? callout,
    TResult Function(DocTable value)? table,
    TResult Function(DocDivider value)? divider,
    TResult Function(DocCode value)? code,
    required TResult orElse(),
  }) {
    if (table != null) {
      return table(this);
    }
    return orElse();
  }
}

abstract class DocTable implements DocumentNode {
  const factory DocTable(
      {required final int columnCount,
      required final List<List<String>> rows,
      final int depth,
      final String? parentKey,
      final bool isNestedUnderToggle}) = _$DocTableImpl;

  int get columnCount;
  List<List<String>> get rows;
  @override
  int get depth;
  @override
  String? get parentKey;
  @override
  bool get isNestedUnderToggle;
  @override
  @JsonKey(ignore: true)
  _$$DocTableImplCopyWith<_$DocTableImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocDividerImplCopyWith<$Res>
    implements $DocumentNodeCopyWith<$Res> {
  factory _$$DocDividerImplCopyWith(
          _$DocDividerImpl value, $Res Function(_$DocDividerImpl) then) =
      __$$DocDividerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int depth, String? parentKey, bool isNestedUnderToggle});
}

/// @nodoc
class __$$DocDividerImplCopyWithImpl<$Res>
    extends _$DocumentNodeCopyWithImpl<$Res, _$DocDividerImpl>
    implements _$$DocDividerImplCopyWith<$Res> {
  __$$DocDividerImplCopyWithImpl(
      _$DocDividerImpl _value, $Res Function(_$DocDividerImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? depth = null,
    Object? parentKey = freezed,
    Object? isNestedUnderToggle = null,
  }) {
    return _then(_$DocDividerImpl(
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      parentKey: freezed == parentKey
          ? _value.parentKey
          : parentKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isNestedUnderToggle: null == isNestedUnderToggle
          ? _value.isNestedUnderToggle
          : isNestedUnderToggle // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DocDividerImpl implements DocDivider {
  const _$DocDividerImpl(
      {this.depth = 0, this.parentKey, this.isNestedUnderToggle = false});

  @override
  @JsonKey()
  final int depth;
  @override
  final String? parentKey;
  @override
  @JsonKey()
  final bool isNestedUnderToggle;

  @override
  String toString() {
    return 'DocumentNode.divider(depth: $depth, parentKey: $parentKey, isNestedUnderToggle: $isNestedUnderToggle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocDividerImpl &&
            (identical(other.depth, depth) || other.depth == depth) &&
            (identical(other.parentKey, parentKey) ||
                other.parentKey == parentKey) &&
            (identical(other.isNestedUnderToggle, isNestedUnderToggle) ||
                other.isNestedUnderToggle == isNestedUnderToggle));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, depth, parentKey, isNestedUnderToggle);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocDividerImplCopyWith<_$DocDividerImpl> get copyWith =>
      __$$DocDividerImplCopyWithImpl<_$DocDividerImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)
        paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)
        heading,
    required TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        list,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        image,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        file,
    required TResult Function(
            String icon,
            String color,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        callout,
    required TResult Function(int columnCount, List<List<String>> rows,
            int depth, String? parentKey, bool isNestedUnderToggle)
        table,
    required TResult Function(
            int depth, String? parentKey, bool isNestedUnderToggle)
        divider,
    required TResult Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)
        code,
  }) {
    return divider(depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult? Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult? Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult? Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult? Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult? Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        code,
  }) {
    return divider?.call(depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult Function(String code, String language, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        code,
    required TResult orElse(),
  }) {
    if (divider != null) {
      return divider(depth, parentKey, isNestedUnderToggle);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DocParagraph value) paragraph,
    required TResult Function(DocHeading value) heading,
    required TResult Function(DocList value) list,
    required TResult Function(DocImage value) image,
    required TResult Function(DocFile value) file,
    required TResult Function(DocCallout value) callout,
    required TResult Function(DocTable value) table,
    required TResult Function(DocDivider value) divider,
    required TResult Function(DocCode value) code,
  }) {
    return divider(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DocParagraph value)? paragraph,
    TResult? Function(DocHeading value)? heading,
    TResult? Function(DocList value)? list,
    TResult? Function(DocImage value)? image,
    TResult? Function(DocFile value)? file,
    TResult? Function(DocCallout value)? callout,
    TResult? Function(DocTable value)? table,
    TResult? Function(DocDivider value)? divider,
    TResult? Function(DocCode value)? code,
  }) {
    return divider?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DocParagraph value)? paragraph,
    TResult Function(DocHeading value)? heading,
    TResult Function(DocList value)? list,
    TResult Function(DocImage value)? image,
    TResult Function(DocFile value)? file,
    TResult Function(DocCallout value)? callout,
    TResult Function(DocTable value)? table,
    TResult Function(DocDivider value)? divider,
    TResult Function(DocCode value)? code,
    required TResult orElse(),
  }) {
    if (divider != null) {
      return divider(this);
    }
    return orElse();
  }
}

abstract class DocDivider implements DocumentNode {
  const factory DocDivider(
      {final int depth,
      final String? parentKey,
      final bool isNestedUnderToggle}) = _$DocDividerImpl;

  @override
  int get depth;
  @override
  String? get parentKey;
  @override
  bool get isNestedUnderToggle;
  @override
  @JsonKey(ignore: true)
  _$$DocDividerImplCopyWith<_$DocDividerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocCodeImplCopyWith<$Res>
    implements $DocumentNodeCopyWith<$Res> {
  factory _$$DocCodeImplCopyWith(
          _$DocCodeImpl value, $Res Function(_$DocCodeImpl) then) =
      __$$DocCodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String code,
      String language,
      int depth,
      String? parentKey,
      bool isNestedUnderToggle});
}

/// @nodoc
class __$$DocCodeImplCopyWithImpl<$Res>
    extends _$DocumentNodeCopyWithImpl<$Res, _$DocCodeImpl>
    implements _$$DocCodeImplCopyWith<$Res> {
  __$$DocCodeImplCopyWithImpl(
      _$DocCodeImpl _value, $Res Function(_$DocCodeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? language = null,
    Object? depth = null,
    Object? parentKey = freezed,
    Object? isNestedUnderToggle = null,
  }) {
    return _then(_$DocCodeImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      parentKey: freezed == parentKey
          ? _value.parentKey
          : parentKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isNestedUnderToggle: null == isNestedUnderToggle
          ? _value.isNestedUnderToggle
          : isNestedUnderToggle // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DocCodeImpl implements DocCode {
  const _$DocCodeImpl(
      {required this.code,
      required this.language,
      this.depth = 0,
      this.parentKey,
      this.isNestedUnderToggle = false});

  @override
  final String code;
  @override
  final String language;
  @override
  @JsonKey()
  final int depth;
  @override
  final String? parentKey;
  @override
  @JsonKey()
  final bool isNestedUnderToggle;

  @override
  String toString() {
    return 'DocumentNode.code(code: $code, language: $language, depth: $depth, parentKey: $parentKey, isNestedUnderToggle: $isNestedUnderToggle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocCodeImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.depth, depth) || other.depth == depth) &&
            (identical(other.parentKey, parentKey) ||
                other.parentKey == parentKey) &&
            (identical(other.isNestedUnderToggle, isNestedUnderToggle) ||
                other.isNestedUnderToggle == isNestedUnderToggle));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, code, language, depth, parentKey, isNestedUnderToggle);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocCodeImplCopyWith<_$DocCodeImpl> get copyWith =>
      __$$DocCodeImplCopyWithImpl<_$DocCodeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)
        paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)
        heading,
    required TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        list,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        image,
    required TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        file,
    required TResult Function(
            String icon,
            String color,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)
        callout,
    required TResult Function(int columnCount, List<List<String>> rows,
            int depth, String? parentKey, bool isNestedUnderToggle)
        table,
    required TResult Function(
            int depth, String? parentKey, bool isNestedUnderToggle)
        divider,
    required TResult Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)
        code,
  }) {
    return code(this.code, language, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult? Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult? Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult? Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult? Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult? Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult? Function(String code, String language, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        code,
  }) {
    return code?.call(
        this.code, language, depth, parentKey, isNestedUnderToggle);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        heading,
    TResult Function(
            String listType,
            bool checked,
            List<DocumentTextSpan> spans,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        list,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            Uint8List? imageBytes,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        image,
    TResult Function(
            String attachmentId,
            String? caption,
            String? fileName,
            String? mimeType,
            int? fileSize,
            String fileTypeLabel,
            bool isAvailable,
            int depth,
            String? parentKey,
            bool isNestedUnderToggle)?
        file,
    TResult Function(String icon, String color, List<DocumentTextSpan> spans,
            int depth, String? parentKey, bool isNestedUnderToggle)?
        callout,
    TResult Function(int columnCount, List<List<String>> rows, int depth,
            String? parentKey, bool isNestedUnderToggle)?
        table,
    TResult Function(int depth, String? parentKey, bool isNestedUnderToggle)?
        divider,
    TResult Function(String code, String language, int depth, String? parentKey,
            bool isNestedUnderToggle)?
        code,
    required TResult orElse(),
  }) {
    if (code != null) {
      return code(this.code, language, depth, parentKey, isNestedUnderToggle);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DocParagraph value) paragraph,
    required TResult Function(DocHeading value) heading,
    required TResult Function(DocList value) list,
    required TResult Function(DocImage value) image,
    required TResult Function(DocFile value) file,
    required TResult Function(DocCallout value) callout,
    required TResult Function(DocTable value) table,
    required TResult Function(DocDivider value) divider,
    required TResult Function(DocCode value) code,
  }) {
    return code(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DocParagraph value)? paragraph,
    TResult? Function(DocHeading value)? heading,
    TResult? Function(DocList value)? list,
    TResult? Function(DocImage value)? image,
    TResult? Function(DocFile value)? file,
    TResult? Function(DocCallout value)? callout,
    TResult? Function(DocTable value)? table,
    TResult? Function(DocDivider value)? divider,
    TResult? Function(DocCode value)? code,
  }) {
    return code?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DocParagraph value)? paragraph,
    TResult Function(DocHeading value)? heading,
    TResult Function(DocList value)? list,
    TResult Function(DocImage value)? image,
    TResult Function(DocFile value)? file,
    TResult Function(DocCallout value)? callout,
    TResult Function(DocTable value)? table,
    TResult Function(DocDivider value)? divider,
    TResult Function(DocCode value)? code,
    required TResult orElse(),
  }) {
    if (code != null) {
      return code(this);
    }
    return orElse();
  }
}

abstract class DocCode implements DocumentNode {
  const factory DocCode(
      {required final String code,
      required final String language,
      final int depth,
      final String? parentKey,
      final bool isNestedUnderToggle}) = _$DocCodeImpl;

  String get code;
  String get language;
  @override
  int get depth;
  @override
  String? get parentKey;
  @override
  bool get isNestedUnderToggle;
  @override
  @JsonKey(ignore: true)
  _$$DocCodeImplCopyWith<_$DocCodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DocumentTextSpan {
  String get text => throw _privateConstructorUsedError;
  bool get bold => throw _privateConstructorUsedError;
  bool get italic => throw _privateConstructorUsedError;
  bool get underline => throw _privateConstructorUsedError;
  bool get strikethrough => throw _privateConstructorUsedError;
  bool get code => throw _privateConstructorUsedError;
  String? get link => throw _privateConstructorUsedError;
  String? get pageLink => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DocumentTextSpanCopyWith<DocumentTextSpan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocumentTextSpanCopyWith<$Res> {
  factory $DocumentTextSpanCopyWith(
          DocumentTextSpan value, $Res Function(DocumentTextSpan) then) =
      _$DocumentTextSpanCopyWithImpl<$Res, DocumentTextSpan>;
  @useResult
  $Res call(
      {String text,
      bool bold,
      bool italic,
      bool underline,
      bool strikethrough,
      bool code,
      String? link,
      String? pageLink});
}

/// @nodoc
class _$DocumentTextSpanCopyWithImpl<$Res, $Val extends DocumentTextSpan>
    implements $DocumentTextSpanCopyWith<$Res> {
  _$DocumentTextSpanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? bold = null,
    Object? italic = null,
    Object? underline = null,
    Object? strikethrough = null,
    Object? code = null,
    Object? link = freezed,
    Object? pageLink = freezed,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      bold: null == bold
          ? _value.bold
          : bold // ignore: cast_nullable_to_non_nullable
              as bool,
      italic: null == italic
          ? _value.italic
          : italic // ignore: cast_nullable_to_non_nullable
              as bool,
      underline: null == underline
          ? _value.underline
          : underline // ignore: cast_nullable_to_non_nullable
              as bool,
      strikethrough: null == strikethrough
          ? _value.strikethrough
          : strikethrough // ignore: cast_nullable_to_non_nullable
              as bool,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as bool,
      link: freezed == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String?,
      pageLink: freezed == pageLink
          ? _value.pageLink
          : pageLink // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DocumentTextSpanImplCopyWith<$Res>
    implements $DocumentTextSpanCopyWith<$Res> {
  factory _$$DocumentTextSpanImplCopyWith(_$DocumentTextSpanImpl value,
          $Res Function(_$DocumentTextSpanImpl) then) =
      __$$DocumentTextSpanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String text,
      bool bold,
      bool italic,
      bool underline,
      bool strikethrough,
      bool code,
      String? link,
      String? pageLink});
}

/// @nodoc
class __$$DocumentTextSpanImplCopyWithImpl<$Res>
    extends _$DocumentTextSpanCopyWithImpl<$Res, _$DocumentTextSpanImpl>
    implements _$$DocumentTextSpanImplCopyWith<$Res> {
  __$$DocumentTextSpanImplCopyWithImpl(_$DocumentTextSpanImpl _value,
      $Res Function(_$DocumentTextSpanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? bold = null,
    Object? italic = null,
    Object? underline = null,
    Object? strikethrough = null,
    Object? code = null,
    Object? link = freezed,
    Object? pageLink = freezed,
  }) {
    return _then(_$DocumentTextSpanImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      bold: null == bold
          ? _value.bold
          : bold // ignore: cast_nullable_to_non_nullable
              as bool,
      italic: null == italic
          ? _value.italic
          : italic // ignore: cast_nullable_to_non_nullable
              as bool,
      underline: null == underline
          ? _value.underline
          : underline // ignore: cast_nullable_to_non_nullable
              as bool,
      strikethrough: null == strikethrough
          ? _value.strikethrough
          : strikethrough // ignore: cast_nullable_to_non_nullable
              as bool,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as bool,
      link: freezed == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String?,
      pageLink: freezed == pageLink
          ? _value.pageLink
          : pageLink // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$DocumentTextSpanImpl implements _DocumentTextSpan {
  const _$DocumentTextSpanImpl(
      {required this.text,
      this.bold = false,
      this.italic = false,
      this.underline = false,
      this.strikethrough = false,
      this.code = false,
      this.link,
      this.pageLink});

  @override
  final String text;
  @override
  @JsonKey()
  final bool bold;
  @override
  @JsonKey()
  final bool italic;
  @override
  @JsonKey()
  final bool underline;
  @override
  @JsonKey()
  final bool strikethrough;
  @override
  @JsonKey()
  final bool code;
  @override
  final String? link;
  @override
  final String? pageLink;

  @override
  String toString() {
    return 'DocumentTextSpan(text: $text, bold: $bold, italic: $italic, underline: $underline, strikethrough: $strikethrough, code: $code, link: $link, pageLink: $pageLink)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocumentTextSpanImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.bold, bold) || other.bold == bold) &&
            (identical(other.italic, italic) || other.italic == italic) &&
            (identical(other.underline, underline) ||
                other.underline == underline) &&
            (identical(other.strikethrough, strikethrough) ||
                other.strikethrough == strikethrough) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.pageLink, pageLink) ||
                other.pageLink == pageLink));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text, bold, italic, underline,
      strikethrough, code, link, pageLink);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocumentTextSpanImplCopyWith<_$DocumentTextSpanImpl> get copyWith =>
      __$$DocumentTextSpanImplCopyWithImpl<_$DocumentTextSpanImpl>(
          this, _$identity);
}

abstract class _DocumentTextSpan implements DocumentTextSpan {
  const factory _DocumentTextSpan(
      {required final String text,
      final bool bold,
      final bool italic,
      final bool underline,
      final bool strikethrough,
      final bool code,
      final String? link,
      final String? pageLink}) = _$DocumentTextSpanImpl;

  @override
  String get text;
  @override
  bool get bold;
  @override
  bool get italic;
  @override
  bool get underline;
  @override
  bool get strikethrough;
  @override
  bool get code;
  @override
  String? get link;
  @override
  String? get pageLink;
  @override
  @JsonKey(ignore: true)
  _$$DocumentTextSpanImplCopyWith<_$DocumentTextSpanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
