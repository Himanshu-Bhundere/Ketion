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
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int get retryCount => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

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
      DateTime createdAt,
      String status,
      int retryCount,
      String? errorMessage});
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
    Object? createdAt = null,
    Object? status = null,
    Object? retryCount = null,
    Object? errorMessage = freezed,
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
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      retryCount: null == retryCount
          ? _value.retryCount
          : retryCount // ignore: cast_nullable_to_non_nullable
              as int,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
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
      DateTime createdAt,
      String status,
      int retryCount,
      String? errorMessage});
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
    Object? createdAt = null,
    Object? status = null,
    Object? retryCount = null,
    Object? errorMessage = freezed,
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
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      retryCount: null == retryCount
          ? _value.retryCount
          : retryCount // ignore: cast_nullable_to_non_nullable
              as int,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
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
      required this.createdAt,
      this.status = 'pending',
      this.retryCount = 0,
      this.errorMessage});

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
  final DateTime createdAt;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final int retryCount;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'SyncQueueItem(id: $id, entityTable: $entityTable, entityId: $entityId, operation: $operation, payload: $payload, createdAt: $createdAt, status: $status, retryCount: $retryCount, errorMessage: $errorMessage)';
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
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.retryCount, retryCount) ||
                other.retryCount == retryCount) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, entityTable, entityId,
      operation, payload, createdAt, status, retryCount, errorMessage);

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
      required final DateTime createdAt,
      final String status,
      final int retryCount,
      final String? errorMessage}) = _$SyncQueueItemImpl;

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
  DateTime get createdAt;
  @override
  String get status;
  @override
  int get retryCount;
  @override
  String? get errorMessage;
  @override
  @JsonKey(ignore: true)
  _$$SyncQueueItemImplCopyWith<_$SyncQueueItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
