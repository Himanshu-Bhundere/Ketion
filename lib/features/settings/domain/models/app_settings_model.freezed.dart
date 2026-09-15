// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppSettingsModel _$AppSettingsModelFromJson(Map<String, dynamic> json) {
  return _AppSettingsModel.fromJson(json);
}

/// @nodoc
mixin _$AppSettingsModel {
  String get themeMode => throw _privateConstructorUsedError;
  String get syncFrequency => throw _privateConstructorUsedError;
  bool get autoSync => throw _privateConstructorUsedError;
  int get cacheLimitMB => throw _privateConstructorUsedError;
  int get tombstoneRetentionDays => throw _privateConstructorUsedError;
  DateTime? get lastCleanup => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AppSettingsModelCopyWith<AppSettingsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSettingsModelCopyWith<$Res> {
  factory $AppSettingsModelCopyWith(
          AppSettingsModel value, $Res Function(AppSettingsModel) then) =
      _$AppSettingsModelCopyWithImpl<$Res, AppSettingsModel>;
  @useResult
  $Res call(
      {String themeMode,
      String syncFrequency,
      bool autoSync,
      int cacheLimitMB,
      int tombstoneRetentionDays,
      DateTime? lastCleanup});
}

/// @nodoc
class _$AppSettingsModelCopyWithImpl<$Res, $Val extends AppSettingsModel>
    implements $AppSettingsModelCopyWith<$Res> {
  _$AppSettingsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? syncFrequency = null,
    Object? autoSync = null,
    Object? cacheLimitMB = null,
    Object? tombstoneRetentionDays = null,
    Object? lastCleanup = freezed,
  }) {
    return _then(_value.copyWith(
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      syncFrequency: null == syncFrequency
          ? _value.syncFrequency
          : syncFrequency // ignore: cast_nullable_to_non_nullable
              as String,
      autoSync: null == autoSync
          ? _value.autoSync
          : autoSync // ignore: cast_nullable_to_non_nullable
              as bool,
      cacheLimitMB: null == cacheLimitMB
          ? _value.cacheLimitMB
          : cacheLimitMB // ignore: cast_nullable_to_non_nullable
              as int,
      tombstoneRetentionDays: null == tombstoneRetentionDays
          ? _value.tombstoneRetentionDays
          : tombstoneRetentionDays // ignore: cast_nullable_to_non_nullable
              as int,
      lastCleanup: freezed == lastCleanup
          ? _value.lastCleanup
          : lastCleanup // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppSettingsModelImplCopyWith<$Res>
    implements $AppSettingsModelCopyWith<$Res> {
  factory _$$AppSettingsModelImplCopyWith(_$AppSettingsModelImpl value,
          $Res Function(_$AppSettingsModelImpl) then) =
      __$$AppSettingsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String themeMode,
      String syncFrequency,
      bool autoSync,
      int cacheLimitMB,
      int tombstoneRetentionDays,
      DateTime? lastCleanup});
}

/// @nodoc
class __$$AppSettingsModelImplCopyWithImpl<$Res>
    extends _$AppSettingsModelCopyWithImpl<$Res, _$AppSettingsModelImpl>
    implements _$$AppSettingsModelImplCopyWith<$Res> {
  __$$AppSettingsModelImplCopyWithImpl(_$AppSettingsModelImpl _value,
      $Res Function(_$AppSettingsModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? syncFrequency = null,
    Object? autoSync = null,
    Object? cacheLimitMB = null,
    Object? tombstoneRetentionDays = null,
    Object? lastCleanup = freezed,
  }) {
    return _then(_$AppSettingsModelImpl(
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      syncFrequency: null == syncFrequency
          ? _value.syncFrequency
          : syncFrequency // ignore: cast_nullable_to_non_nullable
              as String,
      autoSync: null == autoSync
          ? _value.autoSync
          : autoSync // ignore: cast_nullable_to_non_nullable
              as bool,
      cacheLimitMB: null == cacheLimitMB
          ? _value.cacheLimitMB
          : cacheLimitMB // ignore: cast_nullable_to_non_nullable
              as int,
      tombstoneRetentionDays: null == tombstoneRetentionDays
          ? _value.tombstoneRetentionDays
          : tombstoneRetentionDays // ignore: cast_nullable_to_non_nullable
              as int,
      lastCleanup: freezed == lastCleanup
          ? _value.lastCleanup
          : lastCleanup // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppSettingsModelImpl implements _AppSettingsModel {
  const _$AppSettingsModelImpl(
      {this.themeMode = 'System',
      this.syncFrequency = '15 minutes',
      this.autoSync = true,
      this.cacheLimitMB = 100,
      this.tombstoneRetentionDays = 30,
      this.lastCleanup});

  factory _$AppSettingsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppSettingsModelImplFromJson(json);

  @override
  @JsonKey()
  final String themeMode;
  @override
  @JsonKey()
  final String syncFrequency;
  @override
  @JsonKey()
  final bool autoSync;
  @override
  @JsonKey()
  final int cacheLimitMB;
  @override
  @JsonKey()
  final int tombstoneRetentionDays;
  @override
  final DateTime? lastCleanup;

  @override
  String toString() {
    return 'AppSettingsModel(themeMode: $themeMode, syncFrequency: $syncFrequency, autoSync: $autoSync, cacheLimitMB: $cacheLimitMB, tombstoneRetentionDays: $tombstoneRetentionDays, lastCleanup: $lastCleanup)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppSettingsModelImpl &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.syncFrequency, syncFrequency) ||
                other.syncFrequency == syncFrequency) &&
            (identical(other.autoSync, autoSync) ||
                other.autoSync == autoSync) &&
            (identical(other.cacheLimitMB, cacheLimitMB) ||
                other.cacheLimitMB == cacheLimitMB) &&
            (identical(other.tombstoneRetentionDays, tombstoneRetentionDays) ||
                other.tombstoneRetentionDays == tombstoneRetentionDays) &&
            (identical(other.lastCleanup, lastCleanup) ||
                other.lastCleanup == lastCleanup));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, themeMode, syncFrequency,
      autoSync, cacheLimitMB, tombstoneRetentionDays, lastCleanup);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppSettingsModelImplCopyWith<_$AppSettingsModelImpl> get copyWith =>
      __$$AppSettingsModelImplCopyWithImpl<_$AppSettingsModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppSettingsModelImplToJson(
      this,
    );
  }
}

abstract class _AppSettingsModel implements AppSettingsModel {
  const factory _AppSettingsModel(
      {final String themeMode,
      final String syncFrequency,
      final bool autoSync,
      final int cacheLimitMB,
      final int tombstoneRetentionDays,
      final DateTime? lastCleanup}) = _$AppSettingsModelImpl;

  factory _AppSettingsModel.fromJson(Map<String, dynamic> json) =
      _$AppSettingsModelImpl.fromJson;

  @override
  String get themeMode;
  @override
  String get syncFrequency;
  @override
  bool get autoSync;
  @override
  int get cacheLimitMB;
  @override
  int get tombstoneRetentionDays;
  @override
  DateTime? get lastCleanup;
  @override
  @JsonKey(ignore: true)
  _$$AppSettingsModelImplCopyWith<_$AppSettingsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
