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
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans) paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans) heading,
    required TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)
        list,
    required TResult Function(String attachmentId, String? caption) image,
    required TResult Function(String attachmentId, String? caption) file,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans)? paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult? Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult? Function(String attachmentId, String? caption)? image,
    TResult? Function(String attachmentId, String? caption)? file,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans)? paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult Function(String attachmentId, String? caption)? image,
    TResult Function(String attachmentId, String? caption)? file,
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
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DocParagraph value)? paragraph,
    TResult? Function(DocHeading value)? heading,
    TResult? Function(DocList value)? list,
    TResult? Function(DocImage value)? image,
    TResult? Function(DocFile value)? file,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DocParagraph value)? paragraph,
    TResult Function(DocHeading value)? heading,
    TResult Function(DocList value)? list,
    TResult Function(DocImage value)? image,
    TResult Function(DocFile value)? file,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocumentNodeCopyWith<$Res> {
  factory $DocumentNodeCopyWith(
          DocumentNode value, $Res Function(DocumentNode) then) =
      _$DocumentNodeCopyWithImpl<$Res, DocumentNode>;
}

/// @nodoc
class _$DocumentNodeCopyWithImpl<$Res, $Val extends DocumentNode>
    implements $DocumentNodeCopyWith<$Res> {
  _$DocumentNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$DocParagraphImplCopyWith<$Res> {
  factory _$$DocParagraphImplCopyWith(
          _$DocParagraphImpl value, $Res Function(_$DocParagraphImpl) then) =
      __$$DocParagraphImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<DocumentTextSpan> spans});
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
  }) {
    return _then(_$DocParagraphImpl(
      spans: null == spans
          ? _value._spans
          : spans // ignore: cast_nullable_to_non_nullable
              as List<DocumentTextSpan>,
    ));
  }
}

/// @nodoc

class _$DocParagraphImpl implements DocParagraph {
  const _$DocParagraphImpl({required final List<DocumentTextSpan> spans})
      : _spans = spans;

  final List<DocumentTextSpan> _spans;
  @override
  List<DocumentTextSpan> get spans {
    if (_spans is EqualUnmodifiableListView) return _spans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_spans);
  }

  @override
  String toString() {
    return 'DocumentNode.paragraph(spans: $spans)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocParagraphImpl &&
            const DeepCollectionEquality().equals(other._spans, _spans));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_spans));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocParagraphImplCopyWith<_$DocParagraphImpl> get copyWith =>
      __$$DocParagraphImplCopyWithImpl<_$DocParagraphImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans) paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans) heading,
    required TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)
        list,
    required TResult Function(String attachmentId, String? caption) image,
    required TResult Function(String attachmentId, String? caption) file,
  }) {
    return paragraph(spans);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans)? paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult? Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult? Function(String attachmentId, String? caption)? image,
    TResult? Function(String attachmentId, String? caption)? file,
  }) {
    return paragraph?.call(spans);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans)? paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult Function(String attachmentId, String? caption)? image,
    TResult Function(String attachmentId, String? caption)? file,
    required TResult orElse(),
  }) {
    if (paragraph != null) {
      return paragraph(spans);
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
    required TResult orElse(),
  }) {
    if (paragraph != null) {
      return paragraph(this);
    }
    return orElse();
  }
}

abstract class DocParagraph implements DocumentNode {
  const factory DocParagraph({required final List<DocumentTextSpan> spans}) =
      _$DocParagraphImpl;

  List<DocumentTextSpan> get spans;
  @JsonKey(ignore: true)
  _$$DocParagraphImplCopyWith<_$DocParagraphImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocHeadingImplCopyWith<$Res> {
  factory _$$DocHeadingImplCopyWith(
          _$DocHeadingImpl value, $Res Function(_$DocHeadingImpl) then) =
      __$$DocHeadingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int level, List<DocumentTextSpan> spans});
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
    ));
  }
}

/// @nodoc

class _$DocHeadingImpl implements DocHeading {
  const _$DocHeadingImpl(
      {required this.level, required final List<DocumentTextSpan> spans})
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
  String toString() {
    return 'DocumentNode.heading(level: $level, spans: $spans)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocHeadingImpl &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality().equals(other._spans, _spans));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, level, const DeepCollectionEquality().hash(_spans));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocHeadingImplCopyWith<_$DocHeadingImpl> get copyWith =>
      __$$DocHeadingImplCopyWithImpl<_$DocHeadingImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans) paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans) heading,
    required TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)
        list,
    required TResult Function(String attachmentId, String? caption) image,
    required TResult Function(String attachmentId, String? caption) file,
  }) {
    return heading(level, spans);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans)? paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult? Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult? Function(String attachmentId, String? caption)? image,
    TResult? Function(String attachmentId, String? caption)? file,
  }) {
    return heading?.call(level, spans);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans)? paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult Function(String attachmentId, String? caption)? image,
    TResult Function(String attachmentId, String? caption)? file,
    required TResult orElse(),
  }) {
    if (heading != null) {
      return heading(level, spans);
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
      required final List<DocumentTextSpan> spans}) = _$DocHeadingImpl;

  int get level;
  List<DocumentTextSpan> get spans;
  @JsonKey(ignore: true)
  _$$DocHeadingImplCopyWith<_$DocHeadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocListImplCopyWith<$Res> {
  factory _$$DocListImplCopyWith(
          _$DocListImpl value, $Res Function(_$DocListImpl) then) =
      __$$DocListImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String listType, bool checked, List<DocumentTextSpan> spans});
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
    ));
  }
}

/// @nodoc

class _$DocListImpl implements DocList {
  const _$DocListImpl(
      {required this.listType,
      required this.checked,
      required final List<DocumentTextSpan> spans})
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
  String toString() {
    return 'DocumentNode.list(listType: $listType, checked: $checked, spans: $spans)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocListImpl &&
            (identical(other.listType, listType) ||
                other.listType == listType) &&
            (identical(other.checked, checked) || other.checked == checked) &&
            const DeepCollectionEquality().equals(other._spans, _spans));
  }

  @override
  int get hashCode => Object.hash(runtimeType, listType, checked,
      const DeepCollectionEquality().hash(_spans));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocListImplCopyWith<_$DocListImpl> get copyWith =>
      __$$DocListImplCopyWithImpl<_$DocListImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans) paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans) heading,
    required TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)
        list,
    required TResult Function(String attachmentId, String? caption) image,
    required TResult Function(String attachmentId, String? caption) file,
  }) {
    return list(listType, checked, spans);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans)? paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult? Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult? Function(String attachmentId, String? caption)? image,
    TResult? Function(String attachmentId, String? caption)? file,
  }) {
    return list?.call(listType, checked, spans);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans)? paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult Function(String attachmentId, String? caption)? image,
    TResult Function(String attachmentId, String? caption)? file,
    required TResult orElse(),
  }) {
    if (list != null) {
      return list(listType, checked, spans);
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
      required final List<DocumentTextSpan> spans}) = _$DocListImpl;

  String get listType; // 'bullet', 'numbered', 'checklist', 'toggle'
  bool get checked;
  List<DocumentTextSpan> get spans;
  @JsonKey(ignore: true)
  _$$DocListImplCopyWith<_$DocListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocImageImplCopyWith<$Res> {
  factory _$$DocImageImplCopyWith(
          _$DocImageImpl value, $Res Function(_$DocImageImpl) then) =
      __$$DocImageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String attachmentId, String? caption});
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
    ));
  }
}

/// @nodoc

class _$DocImageImpl implements DocImage {
  const _$DocImageImpl({required this.attachmentId, this.caption});

  @override
  final String attachmentId;
  @override
  final String? caption;

  @override
  String toString() {
    return 'DocumentNode.image(attachmentId: $attachmentId, caption: $caption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocImageImpl &&
            (identical(other.attachmentId, attachmentId) ||
                other.attachmentId == attachmentId) &&
            (identical(other.caption, caption) || other.caption == caption));
  }

  @override
  int get hashCode => Object.hash(runtimeType, attachmentId, caption);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocImageImplCopyWith<_$DocImageImpl> get copyWith =>
      __$$DocImageImplCopyWithImpl<_$DocImageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans) paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans) heading,
    required TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)
        list,
    required TResult Function(String attachmentId, String? caption) image,
    required TResult Function(String attachmentId, String? caption) file,
  }) {
    return image(attachmentId, caption);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans)? paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult? Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult? Function(String attachmentId, String? caption)? image,
    TResult? Function(String attachmentId, String? caption)? file,
  }) {
    return image?.call(attachmentId, caption);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans)? paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult Function(String attachmentId, String? caption)? image,
    TResult Function(String attachmentId, String? caption)? file,
    required TResult orElse(),
  }) {
    if (image != null) {
      return image(attachmentId, caption);
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
      final String? caption}) = _$DocImageImpl;

  String get attachmentId;
  String? get caption;
  @JsonKey(ignore: true)
  _$$DocImageImplCopyWith<_$DocImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DocFileImplCopyWith<$Res> {
  factory _$$DocFileImplCopyWith(
          _$DocFileImpl value, $Res Function(_$DocFileImpl) then) =
      __$$DocFileImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String attachmentId, String? caption});
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
    ));
  }
}

/// @nodoc

class _$DocFileImpl implements DocFile {
  const _$DocFileImpl({required this.attachmentId, this.caption});

  @override
  final String attachmentId;
  @override
  final String? caption;

  @override
  String toString() {
    return 'DocumentNode.file(attachmentId: $attachmentId, caption: $caption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocFileImpl &&
            (identical(other.attachmentId, attachmentId) ||
                other.attachmentId == attachmentId) &&
            (identical(other.caption, caption) || other.caption == caption));
  }

  @override
  int get hashCode => Object.hash(runtimeType, attachmentId, caption);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocFileImplCopyWith<_$DocFileImpl> get copyWith =>
      __$$DocFileImplCopyWithImpl<_$DocFileImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DocumentTextSpan> spans) paragraph,
    required TResult Function(int level, List<DocumentTextSpan> spans) heading,
    required TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)
        list,
    required TResult Function(String attachmentId, String? caption) image,
    required TResult Function(String attachmentId, String? caption) file,
  }) {
    return file(attachmentId, caption);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DocumentTextSpan> spans)? paragraph,
    TResult? Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult? Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult? Function(String attachmentId, String? caption)? image,
    TResult? Function(String attachmentId, String? caption)? file,
  }) {
    return file?.call(attachmentId, caption);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DocumentTextSpan> spans)? paragraph,
    TResult Function(int level, List<DocumentTextSpan> spans)? heading,
    TResult Function(
            String listType, bool checked, List<DocumentTextSpan> spans)?
        list,
    TResult Function(String attachmentId, String? caption)? image,
    TResult Function(String attachmentId, String? caption)? file,
    required TResult orElse(),
  }) {
    if (file != null) {
      return file(attachmentId, caption);
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
      final String? caption}) = _$DocFileImpl;

  String get attachmentId;
  String? get caption;
  @JsonKey(ignore: true)
  _$$DocFileImplCopyWith<_$DocFileImpl> get copyWith =>
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
