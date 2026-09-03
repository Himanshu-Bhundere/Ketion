// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReminderEntity _$ReminderEntityFromJson(Map<String, dynamic> json) {
  return _ReminderEntity.fromJson(json);
}

/// @nodoc
mixin _$ReminderEntity {
  String get id => throw _privateConstructorUsedError;
  String get pageId => throw _privateConstructorUsedError;
  String? get blockId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DateTime get reminderTime => throw _privateConstructorUsedError;
  String get timezone => throw _privateConstructorUsedError;
  String? get recurrenceRule => throw _privateConstructorUsedError;
  DateTime? get snoozeUntil => throw _privateConstructorUsedError;
  bool get completed => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  bool get deleted => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReminderEntityCopyWith<ReminderEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReminderEntityCopyWith<$Res> {
  factory $ReminderEntityCopyWith(
          ReminderEntity value, $Res Function(ReminderEntity) then) =
      _$ReminderEntityCopyWithImpl<$Res, ReminderEntity>;
  @useResult
  $Res call(
      {String id,
      String pageId,
      String? blockId,
      String title,
      DateTime reminderTime,
      String timezone,
      String? recurrenceRule,
      DateTime? snoozeUntil,
      bool completed,
      int version,
      DateTime createdAt,
      DateTime updatedAt,
      bool deleted});
}

/// @nodoc
class _$ReminderEntityCopyWithImpl<$Res, $Val extends ReminderEntity>
    implements $ReminderEntityCopyWith<$Res> {
  _$ReminderEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pageId = null,
    Object? blockId = freezed,
    Object? title = null,
    Object? reminderTime = null,
    Object? timezone = null,
    Object? recurrenceRule = freezed,
    Object? snoozeUntil = freezed,
    Object? completed = null,
    Object? version = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deleted = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      blockId: freezed == blockId
          ? _value.blockId
          : blockId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      reminderTime: null == reminderTime
          ? _value.reminderTime
          : reminderTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
      recurrenceRule: freezed == recurrenceRule
          ? _value.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as String?,
      snoozeUntil: freezed == snoozeUntil
          ? _value.snoozeUntil
          : snoozeUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deleted: null == deleted
          ? _value.deleted
          : deleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReminderEntityImplCopyWith<$Res>
    implements $ReminderEntityCopyWith<$Res> {
  factory _$$ReminderEntityImplCopyWith(_$ReminderEntityImpl value,
          $Res Function(_$ReminderEntityImpl) then) =
      __$$ReminderEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String pageId,
      String? blockId,
      String title,
      DateTime reminderTime,
      String timezone,
      String? recurrenceRule,
      DateTime? snoozeUntil,
      bool completed,
      int version,
      DateTime createdAt,
      DateTime updatedAt,
      bool deleted});
}

/// @nodoc
class __$$ReminderEntityImplCopyWithImpl<$Res>
    extends _$ReminderEntityCopyWithImpl<$Res, _$ReminderEntityImpl>
    implements _$$ReminderEntityImplCopyWith<$Res> {
  __$$ReminderEntityImplCopyWithImpl(
      _$ReminderEntityImpl _value, $Res Function(_$ReminderEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pageId = null,
    Object? blockId = freezed,
    Object? title = null,
    Object? reminderTime = null,
    Object? timezone = null,
    Object? recurrenceRule = freezed,
    Object? snoozeUntil = freezed,
    Object? completed = null,
    Object? version = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deleted = null,
  }) {
    return _then(_$ReminderEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      blockId: freezed == blockId
          ? _value.blockId
          : blockId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      reminderTime: null == reminderTime
          ? _value.reminderTime
          : reminderTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
      recurrenceRule: freezed == recurrenceRule
          ? _value.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as String?,
      snoozeUntil: freezed == snoozeUntil
          ? _value.snoozeUntil
          : snoozeUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deleted: null == deleted
          ? _value.deleted
          : deleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReminderEntityImpl implements _ReminderEntity {
  const _$ReminderEntityImpl(
      {required this.id,
      required this.pageId,
      this.blockId,
      this.title = '',
      required this.reminderTime,
      this.timezone = 'UTC',
      this.recurrenceRule,
      this.snoozeUntil,
      this.completed = false,
      this.version = 1,
      required this.createdAt,
      required this.updatedAt,
      this.deleted = false});

  factory _$ReminderEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReminderEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String pageId;
  @override
  final String? blockId;
  @override
  @JsonKey()
  final String title;
  @override
  final DateTime reminderTime;
  @override
  @JsonKey()
  final String timezone;
  @override
  final String? recurrenceRule;
  @override
  final DateTime? snoozeUntil;
  @override
  @JsonKey()
  final bool completed;
  @override
  @JsonKey()
  final int version;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final bool deleted;

  @override
  String toString() {
    return 'ReminderEntity(id: $id, pageId: $pageId, blockId: $blockId, title: $title, reminderTime: $reminderTime, timezone: $timezone, recurrenceRule: $recurrenceRule, snoozeUntil: $snoozeUntil, completed: $completed, version: $version, createdAt: $createdAt, updatedAt: $updatedAt, deleted: $deleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReminderEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pageId, pageId) || other.pageId == pageId) &&
            (identical(other.blockId, blockId) || other.blockId == blockId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.reminderTime, reminderTime) ||
                other.reminderTime == reminderTime) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            (identical(other.snoozeUntil, snoozeUntil) ||
                other.snoozeUntil == snoozeUntil) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deleted, deleted) || other.deleted == deleted));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      pageId,
      blockId,
      title,
      reminderTime,
      timezone,
      recurrenceRule,
      snoozeUntil,
      completed,
      version,
      createdAt,
      updatedAt,
      deleted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReminderEntityImplCopyWith<_$ReminderEntityImpl> get copyWith =>
      __$$ReminderEntityImplCopyWithImpl<_$ReminderEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReminderEntityImplToJson(
      this,
    );
  }
}

abstract class _ReminderEntity implements ReminderEntity {
  const factory _ReminderEntity(
      {required final String id,
      required final String pageId,
      final String? blockId,
      final String title,
      required final DateTime reminderTime,
      final String timezone,
      final String? recurrenceRule,
      final DateTime? snoozeUntil,
      final bool completed,
      final int version,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final bool deleted}) = _$ReminderEntityImpl;

  factory _ReminderEntity.fromJson(Map<String, dynamic> json) =
      _$ReminderEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get pageId;
  @override
  String? get blockId;
  @override
  String get title;
  @override
  DateTime get reminderTime;
  @override
  String get timezone;
  @override
  String? get recurrenceRule;
  @override
  DateTime? get snoozeUntil;
  @override
  bool get completed;
  @override
  int get version;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  bool get deleted;
  @override
  @JsonKey(ignore: true)
  _$$ReminderEntityImplCopyWith<_$ReminderEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
