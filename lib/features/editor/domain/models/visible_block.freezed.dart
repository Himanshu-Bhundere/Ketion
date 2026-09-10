// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'visible_block.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$VisibleBlock {
  Block get block => throw _privateConstructorUsedError;
  int get depth => throw _privateConstructorUsedError;
  bool get hasChildren => throw _privateConstructorUsedError;
  bool get isExpanded => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $VisibleBlockCopyWith<VisibleBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisibleBlockCopyWith<$Res> {
  factory $VisibleBlockCopyWith(
          VisibleBlock value, $Res Function(VisibleBlock) then) =
      _$VisibleBlockCopyWithImpl<$Res, VisibleBlock>;
  @useResult
  $Res call({Block block, int depth, bool hasChildren, bool isExpanded});

  $BlockCopyWith<$Res> get block;
}

/// @nodoc
class _$VisibleBlockCopyWithImpl<$Res, $Val extends VisibleBlock>
    implements $VisibleBlockCopyWith<$Res> {
  _$VisibleBlockCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? block = null,
    Object? depth = null,
    Object? hasChildren = null,
    Object? isExpanded = null,
  }) {
    return _then(_value.copyWith(
      block: null == block
          ? _value.block
          : block // ignore: cast_nullable_to_non_nullable
              as Block,
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      hasChildren: null == hasChildren
          ? _value.hasChildren
          : hasChildren // ignore: cast_nullable_to_non_nullable
              as bool,
      isExpanded: null == isExpanded
          ? _value.isExpanded
          : isExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $BlockCopyWith<$Res> get block {
    return $BlockCopyWith<$Res>(_value.block, (value) {
      return _then(_value.copyWith(block: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VisibleBlockImplCopyWith<$Res>
    implements $VisibleBlockCopyWith<$Res> {
  factory _$$VisibleBlockImplCopyWith(
          _$VisibleBlockImpl value, $Res Function(_$VisibleBlockImpl) then) =
      __$$VisibleBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Block block, int depth, bool hasChildren, bool isExpanded});

  @override
  $BlockCopyWith<$Res> get block;
}

/// @nodoc
class __$$VisibleBlockImplCopyWithImpl<$Res>
    extends _$VisibleBlockCopyWithImpl<$Res, _$VisibleBlockImpl>
    implements _$$VisibleBlockImplCopyWith<$Res> {
  __$$VisibleBlockImplCopyWithImpl(
      _$VisibleBlockImpl _value, $Res Function(_$VisibleBlockImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? block = null,
    Object? depth = null,
    Object? hasChildren = null,
    Object? isExpanded = null,
  }) {
    return _then(_$VisibleBlockImpl(
      block: null == block
          ? _value.block
          : block // ignore: cast_nullable_to_non_nullable
              as Block,
      depth: null == depth
          ? _value.depth
          : depth // ignore: cast_nullable_to_non_nullable
              as int,
      hasChildren: null == hasChildren
          ? _value.hasChildren
          : hasChildren // ignore: cast_nullable_to_non_nullable
              as bool,
      isExpanded: null == isExpanded
          ? _value.isExpanded
          : isExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$VisibleBlockImpl implements _VisibleBlock {
  const _$VisibleBlockImpl(
      {required this.block,
      required this.depth,
      this.hasChildren = false,
      this.isExpanded = true});

  @override
  final Block block;
  @override
  final int depth;
  @override
  @JsonKey()
  final bool hasChildren;
  @override
  @JsonKey()
  final bool isExpanded;

  @override
  String toString() {
    return 'VisibleBlock(block: $block, depth: $depth, hasChildren: $hasChildren, isExpanded: $isExpanded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisibleBlockImpl &&
            (identical(other.block, block) || other.block == block) &&
            (identical(other.depth, depth) || other.depth == depth) &&
            (identical(other.hasChildren, hasChildren) ||
                other.hasChildren == hasChildren) &&
            (identical(other.isExpanded, isExpanded) ||
                other.isExpanded == isExpanded));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, block, depth, hasChildren, isExpanded);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VisibleBlockImplCopyWith<_$VisibleBlockImpl> get copyWith =>
      __$$VisibleBlockImplCopyWithImpl<_$VisibleBlockImpl>(this, _$identity);
}

abstract class _VisibleBlock implements VisibleBlock {
  const factory _VisibleBlock(
      {required final Block block,
      required final int depth,
      final bool hasChildren,
      final bool isExpanded}) = _$VisibleBlockImpl;

  @override
  Block get block;
  @override
  int get depth;
  @override
  bool get hasChildren;
  @override
  bool get isExpanded;
  @override
  @JsonKey(ignore: true)
  _$$VisibleBlockImplCopyWith<_$VisibleBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
