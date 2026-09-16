// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_state_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SyncStateEntity _$SyncStateEntityFromJson(Map<String, dynamic> json) {
  return _SyncStateEntity.fromJson(json);
}

/// @nodoc
mixin _$SyncStateEntity {
  String get deviceId => throw _privateConstructorUsedError;
  String get provider => throw _privateConstructorUsedError;
  int get lastAppliedGeneration => throw _privateConstructorUsedError;
  String? get pageCursor => throw _privateConstructorUsedError;
  DateTime? get lastSyncTime => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SyncStateEntityCopyWith<SyncStateEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncStateEntityCopyWith<$Res> {
  factory $SyncStateEntityCopyWith(
          SyncStateEntity value, $Res Function(SyncStateEntity) then) =
      _$SyncStateEntityCopyWithImpl<$Res, SyncStateEntity>;
  @useResult
  $Res call(
      {String deviceId,
      String provider,
      int lastAppliedGeneration,
      String? pageCursor,
      DateTime? lastSyncTime});
}

/// @nodoc
class _$SyncStateEntityCopyWithImpl<$Res, $Val extends SyncStateEntity>
    implements $SyncStateEntityCopyWith<$Res> {
  _$SyncStateEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? provider = null,
    Object? lastAppliedGeneration = null,
    Object? pageCursor = freezed,
    Object? lastSyncTime = freezed,
  }) {
    return _then(_value.copyWith(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String,
      lastAppliedGeneration: null == lastAppliedGeneration
          ? _value.lastAppliedGeneration
          : lastAppliedGeneration // ignore: cast_nullable_to_non_nullable
              as int,
      pageCursor: freezed == pageCursor
          ? _value.pageCursor
          : pageCursor // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSyncTime: freezed == lastSyncTime
          ? _value.lastSyncTime
          : lastSyncTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncStateEntityImplCopyWith<$Res>
    implements $SyncStateEntityCopyWith<$Res> {
  factory _$$SyncStateEntityImplCopyWith(_$SyncStateEntityImpl value,
          $Res Function(_$SyncStateEntityImpl) then) =
      __$$SyncStateEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String deviceId,
      String provider,
      int lastAppliedGeneration,
      String? pageCursor,
      DateTime? lastSyncTime});
}

/// @nodoc
class __$$SyncStateEntityImplCopyWithImpl<$Res>
    extends _$SyncStateEntityCopyWithImpl<$Res, _$SyncStateEntityImpl>
    implements _$$SyncStateEntityImplCopyWith<$Res> {
  __$$SyncStateEntityImplCopyWithImpl(
      _$SyncStateEntityImpl _value, $Res Function(_$SyncStateEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? provider = null,
    Object? lastAppliedGeneration = null,
    Object? pageCursor = freezed,
    Object? lastSyncTime = freezed,
  }) {
    return _then(_$SyncStateEntityImpl(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String,
      lastAppliedGeneration: null == lastAppliedGeneration
          ? _value.lastAppliedGeneration
          : lastAppliedGeneration // ignore: cast_nullable_to_non_nullable
              as int,
      pageCursor: freezed == pageCursor
          ? _value.pageCursor
          : pageCursor // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSyncTime: freezed == lastSyncTime
          ? _value.lastSyncTime
          : lastSyncTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncStateEntityImpl implements _SyncStateEntity {
  const _$SyncStateEntityImpl(
      {required this.deviceId,
      required this.provider,
      this.lastAppliedGeneration = 0,
      this.pageCursor,
      this.lastSyncTime});

  factory _$SyncStateEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncStateEntityImplFromJson(json);

  @override
  final String deviceId;
  @override
  final String provider;
  @override
  @JsonKey()
  final int lastAppliedGeneration;
  @override
  final String? pageCursor;
  @override
  final DateTime? lastSyncTime;

  @override
  String toString() {
    return 'SyncStateEntity(deviceId: $deviceId, provider: $provider, lastAppliedGeneration: $lastAppliedGeneration, pageCursor: $pageCursor, lastSyncTime: $lastSyncTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncStateEntityImpl &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.lastAppliedGeneration, lastAppliedGeneration) ||
                other.lastAppliedGeneration == lastAppliedGeneration) &&
            (identical(other.pageCursor, pageCursor) ||
                other.pageCursor == pageCursor) &&
            (identical(other.lastSyncTime, lastSyncTime) ||
                other.lastSyncTime == lastSyncTime));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, deviceId, provider,
      lastAppliedGeneration, pageCursor, lastSyncTime);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncStateEntityImplCopyWith<_$SyncStateEntityImpl> get copyWith =>
      __$$SyncStateEntityImplCopyWithImpl<_$SyncStateEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncStateEntityImplToJson(
      this,
    );
  }
}

abstract class _SyncStateEntity implements SyncStateEntity {
  const factory _SyncStateEntity(
      {required final String deviceId,
      required final String provider,
      final int lastAppliedGeneration,
      final String? pageCursor,
      final DateTime? lastSyncTime}) = _$SyncStateEntityImpl;

  factory _SyncStateEntity.fromJson(Map<String, dynamic> json) =
      _$SyncStateEntityImpl.fromJson;

  @override
  String get deviceId;
  @override
  String get provider;
  @override
  int get lastAppliedGeneration;
  @override
  String? get pageCursor;
  @override
  DateTime? get lastSyncTime;
  @override
  @JsonKey(ignore: true)
  _$$SyncStateEntityImplCopyWith<_$SyncStateEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
