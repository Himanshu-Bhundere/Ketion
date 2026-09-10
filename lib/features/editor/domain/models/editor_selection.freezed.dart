// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_selection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TextSelection {
  String get blockId => throw _privateConstructorUsedError;
  int get start => throw _privateConstructorUsedError;
  int get end => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TextSelectionCopyWith<TextSelection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TextSelectionCopyWith<$Res> {
  factory $TextSelectionCopyWith(
          TextSelection value, $Res Function(TextSelection) then) =
      _$TextSelectionCopyWithImpl<$Res, TextSelection>;
  @useResult
  $Res call({String blockId, int start, int end});
}

/// @nodoc
class _$TextSelectionCopyWithImpl<$Res, $Val extends TextSelection>
    implements $TextSelectionCopyWith<$Res> {
  _$TextSelectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? blockId = null,
    Object? start = null,
    Object? end = null,
  }) {
    return _then(_value.copyWith(
      blockId: null == blockId
          ? _value.blockId
          : blockId // ignore: cast_nullable_to_non_nullable
              as String,
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as int,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TextSelectionImplCopyWith<$Res>
    implements $TextSelectionCopyWith<$Res> {
  factory _$$TextSelectionImplCopyWith(
          _$TextSelectionImpl value, $Res Function(_$TextSelectionImpl) then) =
      __$$TextSelectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String blockId, int start, int end});
}

/// @nodoc
class __$$TextSelectionImplCopyWithImpl<$Res>
    extends _$TextSelectionCopyWithImpl<$Res, _$TextSelectionImpl>
    implements _$$TextSelectionImplCopyWith<$Res> {
  __$$TextSelectionImplCopyWithImpl(
      _$TextSelectionImpl _value, $Res Function(_$TextSelectionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? blockId = null,
    Object? start = null,
    Object? end = null,
  }) {
    return _then(_$TextSelectionImpl(
      blockId: null == blockId
          ? _value.blockId
          : blockId // ignore: cast_nullable_to_non_nullable
              as String,
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as int,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$TextSelectionImpl implements _TextSelection {
  const _$TextSelectionImpl(
      {required this.blockId, required this.start, required this.end});

  @override
  final String blockId;
  @override
  final int start;
  @override
  final int end;

  @override
  String toString() {
    return 'TextSelection(blockId: $blockId, start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TextSelectionImpl &&
            (identical(other.blockId, blockId) || other.blockId == blockId) &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end));
  }

  @override
  int get hashCode => Object.hash(runtimeType, blockId, start, end);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TextSelectionImplCopyWith<_$TextSelectionImpl> get copyWith =>
      __$$TextSelectionImplCopyWithImpl<_$TextSelectionImpl>(this, _$identity);
}

abstract class _TextSelection implements TextSelection {
  const factory _TextSelection(
      {required final String blockId,
      required final int start,
      required final int end}) = _$TextSelectionImpl;

  @override
  String get blockId;
  @override
  int get start;
  @override
  int get end;
  @override
  @JsonKey(ignore: true)
  _$$TextSelectionImplCopyWith<_$TextSelectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DocumentSelection {
  String get startBlockId => throw _privateConstructorUsedError;
  int get startOffset => throw _privateConstructorUsedError;
  String get endBlockId => throw _privateConstructorUsedError;
  int get endOffset => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DocumentSelectionCopyWith<DocumentSelection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocumentSelectionCopyWith<$Res> {
  factory $DocumentSelectionCopyWith(
          DocumentSelection value, $Res Function(DocumentSelection) then) =
      _$DocumentSelectionCopyWithImpl<$Res, DocumentSelection>;
  @useResult
  $Res call(
      {String startBlockId, int startOffset, String endBlockId, int endOffset});
}

/// @nodoc
class _$DocumentSelectionCopyWithImpl<$Res, $Val extends DocumentSelection>
    implements $DocumentSelectionCopyWith<$Res> {
  _$DocumentSelectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startBlockId = null,
    Object? startOffset = null,
    Object? endBlockId = null,
    Object? endOffset = null,
  }) {
    return _then(_value.copyWith(
      startBlockId: null == startBlockId
          ? _value.startBlockId
          : startBlockId // ignore: cast_nullable_to_non_nullable
              as String,
      startOffset: null == startOffset
          ? _value.startOffset
          : startOffset // ignore: cast_nullable_to_non_nullable
              as int,
      endBlockId: null == endBlockId
          ? _value.endBlockId
          : endBlockId // ignore: cast_nullable_to_non_nullable
              as String,
      endOffset: null == endOffset
          ? _value.endOffset
          : endOffset // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DocumentSelectionImplCopyWith<$Res>
    implements $DocumentSelectionCopyWith<$Res> {
  factory _$$DocumentSelectionImplCopyWith(_$DocumentSelectionImpl value,
          $Res Function(_$DocumentSelectionImpl) then) =
      __$$DocumentSelectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String startBlockId, int startOffset, String endBlockId, int endOffset});
}

/// @nodoc
class __$$DocumentSelectionImplCopyWithImpl<$Res>
    extends _$DocumentSelectionCopyWithImpl<$Res, _$DocumentSelectionImpl>
    implements _$$DocumentSelectionImplCopyWith<$Res> {
  __$$DocumentSelectionImplCopyWithImpl(_$DocumentSelectionImpl _value,
      $Res Function(_$DocumentSelectionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startBlockId = null,
    Object? startOffset = null,
    Object? endBlockId = null,
    Object? endOffset = null,
  }) {
    return _then(_$DocumentSelectionImpl(
      startBlockId: null == startBlockId
          ? _value.startBlockId
          : startBlockId // ignore: cast_nullable_to_non_nullable
              as String,
      startOffset: null == startOffset
          ? _value.startOffset
          : startOffset // ignore: cast_nullable_to_non_nullable
              as int,
      endBlockId: null == endBlockId
          ? _value.endBlockId
          : endBlockId // ignore: cast_nullable_to_non_nullable
              as String,
      endOffset: null == endOffset
          ? _value.endOffset
          : endOffset // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$DocumentSelectionImpl implements _DocumentSelection {
  const _$DocumentSelectionImpl(
      {required this.startBlockId,
      required this.startOffset,
      required this.endBlockId,
      required this.endOffset});

  @override
  final String startBlockId;
  @override
  final int startOffset;
  @override
  final String endBlockId;
  @override
  final int endOffset;

  @override
  String toString() {
    return 'DocumentSelection(startBlockId: $startBlockId, startOffset: $startOffset, endBlockId: $endBlockId, endOffset: $endOffset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocumentSelectionImpl &&
            (identical(other.startBlockId, startBlockId) ||
                other.startBlockId == startBlockId) &&
            (identical(other.startOffset, startOffset) ||
                other.startOffset == startOffset) &&
            (identical(other.endBlockId, endBlockId) ||
                other.endBlockId == endBlockId) &&
            (identical(other.endOffset, endOffset) ||
                other.endOffset == endOffset));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, startBlockId, startOffset, endBlockId, endOffset);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DocumentSelectionImplCopyWith<_$DocumentSelectionImpl> get copyWith =>
      __$$DocumentSelectionImplCopyWithImpl<_$DocumentSelectionImpl>(
          this, _$identity);
}

abstract class _DocumentSelection implements DocumentSelection {
  const factory _DocumentSelection(
      {required final String startBlockId,
      required final int startOffset,
      required final String endBlockId,
      required final int endOffset}) = _$DocumentSelectionImpl;

  @override
  String get startBlockId;
  @override
  int get startOffset;
  @override
  String get endBlockId;
  @override
  int get endOffset;
  @override
  @JsonKey(ignore: true)
  _$$DocumentSelectionImplCopyWith<_$DocumentSelectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EditorSelection {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TextSelection selection) text,
    required TResult Function(DocumentSelection selection) document,
    required TResult Function(List<String> blockIds) block,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TextSelection selection)? text,
    TResult? Function(DocumentSelection selection)? document,
    TResult? Function(List<String> blockIds)? block,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TextSelection selection)? text,
    TResult Function(DocumentSelection selection)? document,
    TResult Function(List<String> blockIds)? block,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EditorTextSelection value) text,
    required TResult Function(EditorDocumentSelection value) document,
    required TResult Function(EditorBlockSelection value) block,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EditorTextSelection value)? text,
    TResult? Function(EditorDocumentSelection value)? document,
    TResult? Function(EditorBlockSelection value)? block,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EditorTextSelection value)? text,
    TResult Function(EditorDocumentSelection value)? document,
    TResult Function(EditorBlockSelection value)? block,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditorSelectionCopyWith<$Res> {
  factory $EditorSelectionCopyWith(
          EditorSelection value, $Res Function(EditorSelection) then) =
      _$EditorSelectionCopyWithImpl<$Res, EditorSelection>;
}

/// @nodoc
class _$EditorSelectionCopyWithImpl<$Res, $Val extends EditorSelection>
    implements $EditorSelectionCopyWith<$Res> {
  _$EditorSelectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$EditorTextSelectionImplCopyWith<$Res> {
  factory _$$EditorTextSelectionImplCopyWith(_$EditorTextSelectionImpl value,
          $Res Function(_$EditorTextSelectionImpl) then) =
      __$$EditorTextSelectionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({TextSelection selection});

  $TextSelectionCopyWith<$Res> get selection;
}

/// @nodoc
class __$$EditorTextSelectionImplCopyWithImpl<$Res>
    extends _$EditorSelectionCopyWithImpl<$Res, _$EditorTextSelectionImpl>
    implements _$$EditorTextSelectionImplCopyWith<$Res> {
  __$$EditorTextSelectionImplCopyWithImpl(_$EditorTextSelectionImpl _value,
      $Res Function(_$EditorTextSelectionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selection = null,
  }) {
    return _then(_$EditorTextSelectionImpl(
      null == selection
          ? _value.selection
          : selection // ignore: cast_nullable_to_non_nullable
              as TextSelection,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $TextSelectionCopyWith<$Res> get selection {
    return $TextSelectionCopyWith<$Res>(_value.selection, (value) {
      return _then(_value.copyWith(selection: value));
    });
  }
}

/// @nodoc

class _$EditorTextSelectionImpl implements EditorTextSelection {
  const _$EditorTextSelectionImpl(this.selection);

  @override
  final TextSelection selection;

  @override
  String toString() {
    return 'EditorSelection.text(selection: $selection)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditorTextSelectionImpl &&
            (identical(other.selection, selection) ||
                other.selection == selection));
  }

  @override
  int get hashCode => Object.hash(runtimeType, selection);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EditorTextSelectionImplCopyWith<_$EditorTextSelectionImpl> get copyWith =>
      __$$EditorTextSelectionImplCopyWithImpl<_$EditorTextSelectionImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TextSelection selection) text,
    required TResult Function(DocumentSelection selection) document,
    required TResult Function(List<String> blockIds) block,
  }) {
    return text(selection);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TextSelection selection)? text,
    TResult? Function(DocumentSelection selection)? document,
    TResult? Function(List<String> blockIds)? block,
  }) {
    return text?.call(selection);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TextSelection selection)? text,
    TResult Function(DocumentSelection selection)? document,
    TResult Function(List<String> blockIds)? block,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(selection);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EditorTextSelection value) text,
    required TResult Function(EditorDocumentSelection value) document,
    required TResult Function(EditorBlockSelection value) block,
  }) {
    return text(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EditorTextSelection value)? text,
    TResult? Function(EditorDocumentSelection value)? document,
    TResult? Function(EditorBlockSelection value)? block,
  }) {
    return text?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EditorTextSelection value)? text,
    TResult Function(EditorDocumentSelection value)? document,
    TResult Function(EditorBlockSelection value)? block,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(this);
    }
    return orElse();
  }
}

abstract class EditorTextSelection implements EditorSelection {
  const factory EditorTextSelection(final TextSelection selection) =
      _$EditorTextSelectionImpl;

  TextSelection get selection;
  @JsonKey(ignore: true)
  _$$EditorTextSelectionImplCopyWith<_$EditorTextSelectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EditorDocumentSelectionImplCopyWith<$Res> {
  factory _$$EditorDocumentSelectionImplCopyWith(
          _$EditorDocumentSelectionImpl value,
          $Res Function(_$EditorDocumentSelectionImpl) then) =
      __$$EditorDocumentSelectionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({DocumentSelection selection});

  $DocumentSelectionCopyWith<$Res> get selection;
}

/// @nodoc
class __$$EditorDocumentSelectionImplCopyWithImpl<$Res>
    extends _$EditorSelectionCopyWithImpl<$Res, _$EditorDocumentSelectionImpl>
    implements _$$EditorDocumentSelectionImplCopyWith<$Res> {
  __$$EditorDocumentSelectionImplCopyWithImpl(
      _$EditorDocumentSelectionImpl _value,
      $Res Function(_$EditorDocumentSelectionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selection = null,
  }) {
    return _then(_$EditorDocumentSelectionImpl(
      null == selection
          ? _value.selection
          : selection // ignore: cast_nullable_to_non_nullable
              as DocumentSelection,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $DocumentSelectionCopyWith<$Res> get selection {
    return $DocumentSelectionCopyWith<$Res>(_value.selection, (value) {
      return _then(_value.copyWith(selection: value));
    });
  }
}

/// @nodoc

class _$EditorDocumentSelectionImpl implements EditorDocumentSelection {
  const _$EditorDocumentSelectionImpl(this.selection);

  @override
  final DocumentSelection selection;

  @override
  String toString() {
    return 'EditorSelection.document(selection: $selection)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditorDocumentSelectionImpl &&
            (identical(other.selection, selection) ||
                other.selection == selection));
  }

  @override
  int get hashCode => Object.hash(runtimeType, selection);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EditorDocumentSelectionImplCopyWith<_$EditorDocumentSelectionImpl>
      get copyWith => __$$EditorDocumentSelectionImplCopyWithImpl<
          _$EditorDocumentSelectionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TextSelection selection) text,
    required TResult Function(DocumentSelection selection) document,
    required TResult Function(List<String> blockIds) block,
  }) {
    return document(selection);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TextSelection selection)? text,
    TResult? Function(DocumentSelection selection)? document,
    TResult? Function(List<String> blockIds)? block,
  }) {
    return document?.call(selection);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TextSelection selection)? text,
    TResult Function(DocumentSelection selection)? document,
    TResult Function(List<String> blockIds)? block,
    required TResult orElse(),
  }) {
    if (document != null) {
      return document(selection);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EditorTextSelection value) text,
    required TResult Function(EditorDocumentSelection value) document,
    required TResult Function(EditorBlockSelection value) block,
  }) {
    return document(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EditorTextSelection value)? text,
    TResult? Function(EditorDocumentSelection value)? document,
    TResult? Function(EditorBlockSelection value)? block,
  }) {
    return document?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EditorTextSelection value)? text,
    TResult Function(EditorDocumentSelection value)? document,
    TResult Function(EditorBlockSelection value)? block,
    required TResult orElse(),
  }) {
    if (document != null) {
      return document(this);
    }
    return orElse();
  }
}

abstract class EditorDocumentSelection implements EditorSelection {
  const factory EditorDocumentSelection(final DocumentSelection selection) =
      _$EditorDocumentSelectionImpl;

  DocumentSelection get selection;
  @JsonKey(ignore: true)
  _$$EditorDocumentSelectionImplCopyWith<_$EditorDocumentSelectionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EditorBlockSelectionImplCopyWith<$Res> {
  factory _$$EditorBlockSelectionImplCopyWith(_$EditorBlockSelectionImpl value,
          $Res Function(_$EditorBlockSelectionImpl) then) =
      __$$EditorBlockSelectionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<String> blockIds});
}

/// @nodoc
class __$$EditorBlockSelectionImplCopyWithImpl<$Res>
    extends _$EditorSelectionCopyWithImpl<$Res, _$EditorBlockSelectionImpl>
    implements _$$EditorBlockSelectionImplCopyWith<$Res> {
  __$$EditorBlockSelectionImplCopyWithImpl(_$EditorBlockSelectionImpl _value,
      $Res Function(_$EditorBlockSelectionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? blockIds = null,
  }) {
    return _then(_$EditorBlockSelectionImpl(
      null == blockIds
          ? _value._blockIds
          : blockIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$EditorBlockSelectionImpl implements EditorBlockSelection {
  const _$EditorBlockSelectionImpl(final List<String> blockIds)
      : _blockIds = blockIds;

  final List<String> _blockIds;
  @override
  List<String> get blockIds {
    if (_blockIds is EqualUnmodifiableListView) return _blockIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_blockIds);
  }

  @override
  String toString() {
    return 'EditorSelection.block(blockIds: $blockIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditorBlockSelectionImpl &&
            const DeepCollectionEquality().equals(other._blockIds, _blockIds));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_blockIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EditorBlockSelectionImplCopyWith<_$EditorBlockSelectionImpl>
      get copyWith =>
          __$$EditorBlockSelectionImplCopyWithImpl<_$EditorBlockSelectionImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TextSelection selection) text,
    required TResult Function(DocumentSelection selection) document,
    required TResult Function(List<String> blockIds) block,
  }) {
    return block(blockIds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TextSelection selection)? text,
    TResult? Function(DocumentSelection selection)? document,
    TResult? Function(List<String> blockIds)? block,
  }) {
    return block?.call(blockIds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TextSelection selection)? text,
    TResult Function(DocumentSelection selection)? document,
    TResult Function(List<String> blockIds)? block,
    required TResult orElse(),
  }) {
    if (block != null) {
      return block(blockIds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EditorTextSelection value) text,
    required TResult Function(EditorDocumentSelection value) document,
    required TResult Function(EditorBlockSelection value) block,
  }) {
    return block(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EditorTextSelection value)? text,
    TResult? Function(EditorDocumentSelection value)? document,
    TResult? Function(EditorBlockSelection value)? block,
  }) {
    return block?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EditorTextSelection value)? text,
    TResult Function(EditorDocumentSelection value)? document,
    TResult Function(EditorBlockSelection value)? block,
    required TResult orElse(),
  }) {
    if (block != null) {
      return block(this);
    }
    return orElse();
  }
}

abstract class EditorBlockSelection implements EditorSelection {
  const factory EditorBlockSelection(final List<String> blockIds) =
      _$EditorBlockSelectionImpl;

  List<String> get blockIds;
  @JsonKey(ignore: true)
  _$$EditorBlockSelectionImplCopyWith<_$EditorBlockSelectionImpl>
      get copyWith => throw _privateConstructorUsedError;
}
