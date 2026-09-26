// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_queue_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SyncQueueItem _$SyncQueueItemFromJson(Map<String, dynamic> json) {
  return _SyncQueueItem.fromJson(json);
}

/// @nodoc
mixin _$SyncQueueItem {
  String get id => throw _privateConstructorUsedError;
  String get entityTable => throw _privateConstructorUsedError;
  String get entityId => throw _privateConstructorUsedError;
  String get operation => throw _privateConstructorUsedError;
  String? get payload => throw _privateConstructorUsedError;
  String? get batchId => throw _privateConstructorUsedError;
  int? get version => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  SyncQueueItemStatus get status => throw _privateConstructorUsedError;
  int get attemptCount => throw _privateConstructorUsedError;
  DateTime? get lastAttemptAt => throw _privateConstructorUsedError;
  DateTime? get nextRetryAt => throw _privateConstructorUsedError;
  DateTime? get leaseUntil => throw _privateConstructorUsedError;
  String? get lastError => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SyncQueueItemCopyWith<SyncQueueItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncQueueItemCopyWith<$Res> {
  factory $SyncQueueItemCopyWith(
          SyncQueueItem value, $Res Function(SyncQueueItem) then) =
      _$SyncQueueItemCopyWithImpl<$Res, SyncQueueItem>;
  @useResult
  $Res call(
      {String id,
      String entityTable,
      String entityId,
      String operation,
      String? payload,
      String? batchId,
      int? version,
      DateTime? updatedAt,
      DateTime createdAt,
      SyncQueueItemStatus status,
      int attemptCount,
      DateTime? lastAttemptAt,
      DateTime? nextRetryAt,
      DateTime? leaseUntil,
      String? lastError});
}

/// @nodoc
class _$SyncQueueItemCopyWithImpl<$Res, $Val extends SyncQueueItem>
    implements $SyncQueueItemCopyWith<$Res> {
  _$SyncQueueItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? entityTable = null,
    Object? entityId = null,
    Object? operation = null,
    Object? payload = freezed,
    Object? batchId = freezed,
    Object? version = freezed,
    Object? updatedAt = freezed,
    Object? createdAt = null,
    Object? status = null,
    Object? attemptCount = null,
    Object? lastAttemptAt = freezed,
    Object? nextRetryAt = freezed,
    Object? leaseUntil = freezed,
    Object? lastError = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      entityTable: null == entityTable
          ? _value.entityTable
          : entityTable // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      operation: null == operation
          ? _value.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as String,
      payload: freezed == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as String?,
      batchId: freezed == batchId
          ? _value.batchId
          : batchId // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SyncQueueItemStatus,
      attemptCount: null == attemptCount
          ? _value.attemptCount
          : attemptCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastAttemptAt: freezed == lastAttemptAt
          ? _value.lastAttemptAt
          : lastAttemptAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextRetryAt: freezed == nextRetryAt
          ? _value.nextRetryAt
          : nextRetryAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      leaseUntil: freezed == leaseUntil
          ? _value.leaseUntil
          : leaseUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastError: freezed == lastError
          ? _value.lastError
          : lastError // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncQueueItemImplCopyWith<$Res>
    implements $SyncQueueItemCopyWith<$Res> {
  factory _$$SyncQueueItemImplCopyWith(
          _$SyncQueueItemImpl value, $Res Function(_$SyncQueueItemImpl) then) =
      __$$SyncQueueItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String entityTable,
      String entityId,
      String operation,
      String? payload,
      String? batchId,
      int? version,
      DateTime? updatedAt,
      DateTime createdAt,
      SyncQueueItemStatus status,
      int attemptCount,
      DateTime? lastAttemptAt,
      DateTime? nextRetryAt,
      DateTime? leaseUntil,
      String? lastError});
}

/// @nodoc
class __$$SyncQueueItemImplCopyWithImpl<$Res>
    extends _$SyncQueueItemCopyWithImpl<$Res, _$SyncQueueItemImpl>
    implements _$$SyncQueueItemImplCopyWith<$Res> {
  __$$SyncQueueItemImplCopyWithImpl(
      _$SyncQueueItemImpl _value, $Res Function(_$SyncQueueItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? entityTable = null,
    Object? entityId = null,
    Object? operation = null,
    Object? payload = freezed,
    Object? batchId = freezed,
    Object? version = freezed,
    Object? updatedAt = freezed,
    Object? createdAt = null,
    Object? status = null,
    Object? attemptCount = null,
    Object? lastAttemptAt = freezed,
    Object? nextRetryAt = freezed,
    Object? leaseUntil = freezed,
    Object? lastError = freezed,
  }) {
    return _then(_$SyncQueueItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      entityTable: null == entityTable
          ? _value.entityTable
          : entityTable // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      operation: null == operation
          ? _value.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as String,
      payload: freezed == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as String?,
      batchId: freezed == batchId
          ? _value.batchId
          : batchId // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SyncQueueItemStatus,
      attemptCount: null == attemptCount
          ? _value.attemptCount
          : attemptCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastAttemptAt: freezed == lastAttemptAt
          ? _value.lastAttemptAt
          : lastAttemptAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextRetryAt: freezed == nextRetryAt
          ? _value.nextRetryAt
          : nextRetryAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      leaseUntil: freezed == leaseUntil
          ? _value.leaseUntil
          : leaseUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastError: freezed == lastError
          ? _value.lastError
          : lastError // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncQueueItemImpl implements _SyncQueueItem {
  const _$SyncQueueItemImpl(
      {required this.id,
      required this.entityTable,
      required this.entityId,
      required this.operation,
      this.payload,
      this.batchId,
      this.version,
      this.updatedAt,
      required this.createdAt,
      this.status = SyncQueueItemStatus.pending,
      this.attemptCount = 0,
      this.lastAttemptAt,
      this.nextRetryAt,
      this.leaseUntil,
      this.lastError});

  factory _$SyncQueueItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncQueueItemImplFromJson(json);

  @override
  final String id;
  @override
  final String entityTable;
  @override
  final String entityId;
  @override
  final String operation;
  @override
  final String? payload;
  @override
  final String? batchId;
  @override
  final int? version;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final SyncQueueItemStatus status;
  @override
  @JsonKey()
  final int attemptCount;
  @override
  final DateTime? lastAttemptAt;
  @override
  final DateTime? nextRetryAt;
  @override
  final DateTime? leaseUntil;
  @override
  final String? lastError;

  @override
  String toString() {
    return 'SyncQueueItem(id: $id, entityTable: $entityTable, entityId: $entityId, operation: $operation, payload: $payload, batchId: $batchId, version: $version, updatedAt: $updatedAt, createdAt: $createdAt, status: $status, attemptCount: $attemptCount, lastAttemptAt: $lastAttemptAt, nextRetryAt: $nextRetryAt, leaseUntil: $leaseUntil, lastError: $lastError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncQueueItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.entityTable, entityTable) ||
                other.entityTable == entityTable) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.payload, payload) || other.payload == payload) &&
            (identical(other.batchId, batchId) || other.batchId == batchId) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.attemptCount, attemptCount) ||
                other.attemptCount == attemptCount) &&
            (identical(other.lastAttemptAt, lastAttemptAt) ||
                other.lastAttemptAt == lastAttemptAt) &&
            (identical(other.nextRetryAt, nextRetryAt) ||
                other.nextRetryAt == nextRetryAt) &&
            (identical(other.leaseUntil, leaseUntil) ||
                other.leaseUntil == leaseUntil) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      entityTable,
      entityId,
      operation,
      payload,
      batchId,
      version,
      updatedAt,
      createdAt,
      status,
      attemptCount,
      lastAttemptAt,
      nextRetryAt,
      leaseUntil,
      lastError);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncQueueItemImplCopyWith<_$SyncQueueItemImpl> get copyWith =>
      __$$SyncQueueItemImplCopyWithImpl<_$SyncQueueItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncQueueItemImplToJson(
      this,
    );
  }
}

abstract class _SyncQueueItem implements SyncQueueItem {
  const factory _SyncQueueItem(
      {required final String id,
      required final String entityTable,
      required final String entityId,
      required final String operation,
      final String? payload,
      final String? batchId,
      final int? version,
      final DateTime? updatedAt,
      required final DateTime createdAt,
      final SyncQueueItemStatus status,
      final int attemptCount,
      final DateTime? lastAttemptAt,
      final DateTime? nextRetryAt,
      final DateTime? leaseUntil,
      final String? lastError}) = _$SyncQueueItemImpl;

  factory _SyncQueueItem.fromJson(Map<String, dynamic> json) =
      _$SyncQueueItemImpl.fromJson;

  @override
  String get id;
  @override
  String get entityTable;
  @override
  String get entityId;
  @override
  String get operation;
  @override
  String? get payload;
  @override
  String? get batchId;
  @override
  int? get version;
  @override
  DateTime? get updatedAt;
  @override
  DateTime get createdAt;
  @override
  SyncQueueItemStatus get status;
  @override
  int get attemptCount;
  @override
  DateTime? get lastAttemptAt;
  @override
  DateTime? get nextRetryAt;
  @override
  DateTime? get leaseUntil;
  @override
  String? get lastError;
  @override
  @JsonKey(ignore: true)
  _$$SyncQueueItemImplCopyWith<_$SyncQueueItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
