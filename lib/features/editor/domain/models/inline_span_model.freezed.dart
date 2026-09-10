// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inline_span_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InlineSpanModel _$InlineSpanModelFromJson(Map<String, dynamic> json) {
  return _InlineSpanModel.fromJson(json);
}

/// @nodoc
mixin _$InlineSpanModel {
  int get offset => throw _privateConstructorUsedError;
  int get length => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get value => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InlineSpanModelCopyWith<InlineSpanModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InlineSpanModelCopyWith<$Res> {
  factory $InlineSpanModelCopyWith(
          InlineSpanModel value, $Res Function(InlineSpanModel) then) =
      _$InlineSpanModelCopyWithImpl<$Res, InlineSpanModel>;
  @useResult
  $Res call({int offset, int length, String type, String? value});
}

/// @nodoc
class _$InlineSpanModelCopyWithImpl<$Res, $Val extends InlineSpanModel>
    implements $InlineSpanModelCopyWith<$Res> {
  _$InlineSpanModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? offset = null,
    Object? length = null,
    Object? type = null,
    Object? value = freezed,
  }) {
    return _then(_value.copyWith(
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      length: null == length
          ? _value.length
          : length // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InlineSpanModelImplCopyWith<$Res>
    implements $InlineSpanModelCopyWith<$Res> {
  factory _$$InlineSpanModelImplCopyWith(_$InlineSpanModelImpl value,
          $Res Function(_$InlineSpanModelImpl) then) =
      __$$InlineSpanModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int offset, int length, String type, String? value});
}

/// @nodoc
class __$$InlineSpanModelImplCopyWithImpl<$Res>
    extends _$InlineSpanModelCopyWithImpl<$Res, _$InlineSpanModelImpl>
    implements _$$InlineSpanModelImplCopyWith<$Res> {
  __$$InlineSpanModelImplCopyWithImpl(
      _$InlineSpanModelImpl _value, $Res Function(_$InlineSpanModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? offset = null,
    Object? length = null,
    Object? type = null,
    Object? value = freezed,
  }) {
    return _then(_$InlineSpanModelImpl(
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      length: null == length
          ? _value.length
          : length // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InlineSpanModelImpl implements _InlineSpanModel {
  const _$InlineSpanModelImpl(
      {required this.offset,
      required this.length,
      required this.type,
      this.value});

  factory _$InlineSpanModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$InlineSpanModelImplFromJson(json);

  @override
  final int offset;
  @override
  final int length;
  @override
  final String type;
  @override
  final String? value;

  @override
  String toString() {
    return 'InlineSpanModel(offset: $offset, length: $length, type: $type, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InlineSpanModelImpl &&
            (identical(other.offset, offset) || other.offset == offset) &&
            (identical(other.length, length) || other.length == length) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, offset, length, type, value);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InlineSpanModelImplCopyWith<_$InlineSpanModelImpl> get copyWith =>
      __$$InlineSpanModelImplCopyWithImpl<_$InlineSpanModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InlineSpanModelImplToJson(
      this,
    );
  }
}

abstract class _InlineSpanModel implements InlineSpanModel {
  const factory _InlineSpanModel(
      {required final int offset,
      required final int length,
      required final String type,
      final String? value}) = _$InlineSpanModelImpl;

  factory _InlineSpanModel.fromJson(Map<String, dynamic> json) =
      _$InlineSpanModelImpl.fromJson;

  @override
  int get offset;
  @override
  int get length;
  @override
  String get type;
  @override
  String? get value;
  @override
  @JsonKey(ignore: true)
  _$$InlineSpanModelImplCopyWith<_$InlineSpanModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
