// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drop_intent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DropIntent {
  String get targetBlockId => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String targetBlockId) before,
    required TResult Function(String targetBlockId) after,
    required TResult Function(String targetBlockId) child,
    required TResult Function(String targetBlockId) unnest,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String targetBlockId)? before,
    TResult? Function(String targetBlockId)? after,
    TResult? Function(String targetBlockId)? child,
    TResult? Function(String targetBlockId)? unnest,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String targetBlockId)? before,
    TResult Function(String targetBlockId)? after,
    TResult Function(String targetBlockId)? child,
    TResult Function(String targetBlockId)? unnest,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DropIntentBefore value) before,
    required TResult Function(DropIntentAfter value) after,
    required TResult Function(DropIntentChild value) child,
    required TResult Function(DropIntentUnnest value) unnest,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DropIntentBefore value)? before,
    TResult? Function(DropIntentAfter value)? after,
    TResult? Function(DropIntentChild value)? child,
    TResult? Function(DropIntentUnnest value)? unnest,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DropIntentBefore value)? before,
    TResult Function(DropIntentAfter value)? after,
    TResult Function(DropIntentChild value)? child,
    TResult Function(DropIntentUnnest value)? unnest,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DropIntentCopyWith<DropIntent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DropIntentCopyWith<$Res> {
  factory $DropIntentCopyWith(
          DropIntent value, $Res Function(DropIntent) then) =
      _$DropIntentCopyWithImpl<$Res, DropIntent>;
  @useResult
  $Res call({String targetBlockId});
}

/// @nodoc
class _$DropIntentCopyWithImpl<$Res, $Val extends DropIntent>
    implements $DropIntentCopyWith<$Res> {
  _$DropIntentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetBlockId = null,
  }) {
    return _then(_value.copyWith(
      targetBlockId: null == targetBlockId
          ? _value.targetBlockId
          : targetBlockId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DropIntentBeforeImplCopyWith<$Res>
    implements $DropIntentCopyWith<$Res> {
  factory _$$DropIntentBeforeImplCopyWith(_$DropIntentBeforeImpl value,
          $Res Function(_$DropIntentBeforeImpl) then) =
      __$$DropIntentBeforeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String targetBlockId});
}

/// @nodoc
class __$$DropIntentBeforeImplCopyWithImpl<$Res>
    extends _$DropIntentCopyWithImpl<$Res, _$DropIntentBeforeImpl>
    implements _$$DropIntentBeforeImplCopyWith<$Res> {
  __$$DropIntentBeforeImplCopyWithImpl(_$DropIntentBeforeImpl _value,
      $Res Function(_$DropIntentBeforeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetBlockId = null,
  }) {
    return _then(_$DropIntentBeforeImpl(
      null == targetBlockId
          ? _value.targetBlockId
          : targetBlockId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DropIntentBeforeImpl implements DropIntentBefore {
  const _$DropIntentBeforeImpl(this.targetBlockId);

  @override
  final String targetBlockId;

  @override
  String toString() {
    return 'DropIntent.before(targetBlockId: $targetBlockId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DropIntentBeforeImpl &&
            (identical(other.targetBlockId, targetBlockId) ||
                other.targetBlockId == targetBlockId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, targetBlockId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DropIntentBeforeImplCopyWith<_$DropIntentBeforeImpl> get copyWith =>
      __$$DropIntentBeforeImplCopyWithImpl<_$DropIntentBeforeImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String targetBlockId) before,
    required TResult Function(String targetBlockId) after,
    required TResult Function(String targetBlockId) child,
    required TResult Function(String targetBlockId) unnest,
  }) {
    return before(targetBlockId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String targetBlockId)? before,
    TResult? Function(String targetBlockId)? after,
    TResult? Function(String targetBlockId)? child,
    TResult? Function(String targetBlockId)? unnest,
  }) {
    return before?.call(targetBlockId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String targetBlockId)? before,
    TResult Function(String targetBlockId)? after,
    TResult Function(String targetBlockId)? child,
    TResult Function(String targetBlockId)? unnest,
    required TResult orElse(),
  }) {
    if (before != null) {
      return before(targetBlockId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DropIntentBefore value) before,
    required TResult Function(DropIntentAfter value) after,
    required TResult Function(DropIntentChild value) child,
    required TResult Function(DropIntentUnnest value) unnest,
  }) {
    return before(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DropIntentBefore value)? before,
    TResult? Function(DropIntentAfter value)? after,
    TResult? Function(DropIntentChild value)? child,
    TResult? Function(DropIntentUnnest value)? unnest,
  }) {
    return before?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DropIntentBefore value)? before,
    TResult Function(DropIntentAfter value)? after,
    TResult Function(DropIntentChild value)? child,
    TResult Function(DropIntentUnnest value)? unnest,
    required TResult orElse(),
  }) {
    if (before != null) {
      return before(this);
    }
    return orElse();
  }
}

abstract class DropIntentBefore implements DropIntent {
  const factory DropIntentBefore(final String targetBlockId) =
      _$DropIntentBeforeImpl;

  @override
  String get targetBlockId;
  @override
  @JsonKey(ignore: true)
  _$$DropIntentBeforeImplCopyWith<_$DropIntentBeforeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DropIntentAfterImplCopyWith<$Res>
    implements $DropIntentCopyWith<$Res> {
  factory _$$DropIntentAfterImplCopyWith(_$DropIntentAfterImpl value,
          $Res Function(_$DropIntentAfterImpl) then) =
      __$$DropIntentAfterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String targetBlockId});
}

/// @nodoc
class __$$DropIntentAfterImplCopyWithImpl<$Res>
    extends _$DropIntentCopyWithImpl<$Res, _$DropIntentAfterImpl>
    implements _$$DropIntentAfterImplCopyWith<$Res> {
  __$$DropIntentAfterImplCopyWithImpl(
      _$DropIntentAfterImpl _value, $Res Function(_$DropIntentAfterImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetBlockId = null,
  }) {
    return _then(_$DropIntentAfterImpl(
      null == targetBlockId
          ? _value.targetBlockId
          : targetBlockId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DropIntentAfterImpl implements DropIntentAfter {
  const _$DropIntentAfterImpl(this.targetBlockId);

  @override
  final String targetBlockId;

  @override
  String toString() {
    return 'DropIntent.after(targetBlockId: $targetBlockId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DropIntentAfterImpl &&
            (identical(other.targetBlockId, targetBlockId) ||
                other.targetBlockId == targetBlockId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, targetBlockId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DropIntentAfterImplCopyWith<_$DropIntentAfterImpl> get copyWith =>
      __$$DropIntentAfterImplCopyWithImpl<_$DropIntentAfterImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String targetBlockId) before,
    required TResult Function(String targetBlockId) after,
    required TResult Function(String targetBlockId) child,
    required TResult Function(String targetBlockId) unnest,
  }) {
    return after(targetBlockId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String targetBlockId)? before,
    TResult? Function(String targetBlockId)? after,
    TResult? Function(String targetBlockId)? child,
    TResult? Function(String targetBlockId)? unnest,
  }) {
    return after?.call(targetBlockId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String targetBlockId)? before,
    TResult Function(String targetBlockId)? after,
    TResult Function(String targetBlockId)? child,
    TResult Function(String targetBlockId)? unnest,
    required TResult orElse(),
  }) {
    if (after != null) {
      return after(targetBlockId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DropIntentBefore value) before,
    required TResult Function(DropIntentAfter value) after,
    required TResult Function(DropIntentChild value) child,
    required TResult Function(DropIntentUnnest value) unnest,
  }) {
    return after(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DropIntentBefore value)? before,
    TResult? Function(DropIntentAfter value)? after,
    TResult? Function(DropIntentChild value)? child,
    TResult? Function(DropIntentUnnest value)? unnest,
  }) {
    return after?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DropIntentBefore value)? before,
    TResult Function(DropIntentAfter value)? after,
    TResult Function(DropIntentChild value)? child,
    TResult Function(DropIntentUnnest value)? unnest,
    required TResult orElse(),
  }) {
    if (after != null) {
      return after(this);
    }
    return orElse();
  }
}

abstract class DropIntentAfter implements DropIntent {
  const factory DropIntentAfter(final String targetBlockId) =
      _$DropIntentAfterImpl;

  @override
  String get targetBlockId;
  @override
  @JsonKey(ignore: true)
  _$$DropIntentAfterImplCopyWith<_$DropIntentAfterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DropIntentChildImplCopyWith<$Res>
    implements $DropIntentCopyWith<$Res> {
  factory _$$DropIntentChildImplCopyWith(_$DropIntentChildImpl value,
          $Res Function(_$DropIntentChildImpl) then) =
      __$$DropIntentChildImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String targetBlockId});
}

/// @nodoc
class __$$DropIntentChildImplCopyWithImpl<$Res>
    extends _$DropIntentCopyWithImpl<$Res, _$DropIntentChildImpl>
    implements _$$DropIntentChildImplCopyWith<$Res> {
  __$$DropIntentChildImplCopyWithImpl(
      _$DropIntentChildImpl _value, $Res Function(_$DropIntentChildImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetBlockId = null,
  }) {
    return _then(_$DropIntentChildImpl(
      null == targetBlockId
          ? _value.targetBlockId
          : targetBlockId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DropIntentChildImpl implements DropIntentChild {
  const _$DropIntentChildImpl(this.targetBlockId);

  @override
  final String targetBlockId;

  @override
  String toString() {
    return 'DropIntent.child(targetBlockId: $targetBlockId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DropIntentChildImpl &&
            (identical(other.targetBlockId, targetBlockId) ||
                other.targetBlockId == targetBlockId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, targetBlockId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DropIntentChildImplCopyWith<_$DropIntentChildImpl> get copyWith =>
      __$$DropIntentChildImplCopyWithImpl<_$DropIntentChildImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String targetBlockId) before,
    required TResult Function(String targetBlockId) after,
    required TResult Function(String targetBlockId) child,
    required TResult Function(String targetBlockId) unnest,
  }) {
    return child(targetBlockId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String targetBlockId)? before,
    TResult? Function(String targetBlockId)? after,
    TResult? Function(String targetBlockId)? child,
    TResult? Function(String targetBlockId)? unnest,
  }) {
    return child?.call(targetBlockId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String targetBlockId)? before,
    TResult Function(String targetBlockId)? after,
    TResult Function(String targetBlockId)? child,
    TResult Function(String targetBlockId)? unnest,
    required TResult orElse(),
  }) {
    if (child != null) {
      return child(targetBlockId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DropIntentBefore value) before,
    required TResult Function(DropIntentAfter value) after,
    required TResult Function(DropIntentChild value) child,
    required TResult Function(DropIntentUnnest value) unnest,
  }) {
    return child(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DropIntentBefore value)? before,
    TResult? Function(DropIntentAfter value)? after,
    TResult? Function(DropIntentChild value)? child,
    TResult? Function(DropIntentUnnest value)? unnest,
  }) {
    return child?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DropIntentBefore value)? before,
    TResult Function(DropIntentAfter value)? after,
    TResult Function(DropIntentChild value)? child,
    TResult Function(DropIntentUnnest value)? unnest,
    required TResult orElse(),
  }) {
    if (child != null) {
      return child(this);
    }
    return orElse();
  }
}

abstract class DropIntentChild implements DropIntent {
  const factory DropIntentChild(final String targetBlockId) =
      _$DropIntentChildImpl;

  @override
  String get targetBlockId;
  @override
  @JsonKey(ignore: true)
  _$$DropIntentChildImplCopyWith<_$DropIntentChildImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DropIntentUnnestImplCopyWith<$Res>
    implements $DropIntentCopyWith<$Res> {
  factory _$$DropIntentUnnestImplCopyWith(_$DropIntentUnnestImpl value,
          $Res Function(_$DropIntentUnnestImpl) then) =
      __$$DropIntentUnnestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String targetBlockId});
}

/// @nodoc
class __$$DropIntentUnnestImplCopyWithImpl<$Res>
    extends _$DropIntentCopyWithImpl<$Res, _$DropIntentUnnestImpl>
    implements _$$DropIntentUnnestImplCopyWith<$Res> {
  __$$DropIntentUnnestImplCopyWithImpl(_$DropIntentUnnestImpl _value,
      $Res Function(_$DropIntentUnnestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetBlockId = null,
  }) {
    return _then(_$DropIntentUnnestImpl(
      null == targetBlockId
          ? _value.targetBlockId
          : targetBlockId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DropIntentUnnestImpl implements DropIntentUnnest {
  const _$DropIntentUnnestImpl(this.targetBlockId);

  @override
  final String targetBlockId;

  @override
  String toString() {
    return 'DropIntent.unnest(targetBlockId: $targetBlockId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DropIntentUnnestImpl &&
            (identical(other.targetBlockId, targetBlockId) ||
                other.targetBlockId == targetBlockId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, targetBlockId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DropIntentUnnestImplCopyWith<_$DropIntentUnnestImpl> get copyWith =>
      __$$DropIntentUnnestImplCopyWithImpl<_$DropIntentUnnestImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String targetBlockId) before,
    required TResult Function(String targetBlockId) after,
    required TResult Function(String targetBlockId) child,
    required TResult Function(String targetBlockId) unnest,
  }) {
    return unnest(targetBlockId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String targetBlockId)? before,
    TResult? Function(String targetBlockId)? after,
    TResult? Function(String targetBlockId)? child,
    TResult? Function(String targetBlockId)? unnest,
  }) {
    return unnest?.call(targetBlockId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String targetBlockId)? before,
    TResult Function(String targetBlockId)? after,
    TResult Function(String targetBlockId)? child,
    TResult Function(String targetBlockId)? unnest,
    required TResult orElse(),
  }) {
    if (unnest != null) {
      return unnest(targetBlockId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DropIntentBefore value) before,
    required TResult Function(DropIntentAfter value) after,
    required TResult Function(DropIntentChild value) child,
    required TResult Function(DropIntentUnnest value) unnest,
  }) {
    return unnest(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DropIntentBefore value)? before,
    TResult? Function(DropIntentAfter value)? after,
    TResult? Function(DropIntentChild value)? child,
    TResult? Function(DropIntentUnnest value)? unnest,
  }) {
    return unnest?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DropIntentBefore value)? before,
    TResult Function(DropIntentAfter value)? after,
    TResult Function(DropIntentChild value)? child,
    TResult Function(DropIntentUnnest value)? unnest,
    required TResult orElse(),
  }) {
    if (unnest != null) {
      return unnest(this);
    }
    return orElse();
  }
}

abstract class DropIntentUnnest implements DropIntent {
  const factory DropIntentUnnest(final String targetBlockId) =
      _$DropIntentUnnestImpl;

  @override
  String get targetBlockId;
  @override
  @JsonKey(ignore: true)
  _$$DropIntentUnnestImplCopyWith<_$DropIntentUnnestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
