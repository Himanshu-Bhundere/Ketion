// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Attachment _$AttachmentFromJson(Map<String, dynamic> json) {
  return _Attachment.fromJson(json);
}

/// @nodoc
mixin _$Attachment {
  String get id => throw _privateConstructorUsedError;
  String? get driveFileId => throw _privateConstructorUsedError;
  String? get localPath => throw _privateConstructorUsedError;
  String? get mimeType => throw _privateConstructorUsedError;
  String? get checksumSha256 => throw _privateConstructorUsedError;
  int? get fileSize => throw _privateConstructorUsedError;
  int? get width => throw _privateConstructorUsedError;
  int? get height => throw _privateConstructorUsedError;
  int? get duration => throw _privateConstructorUsedError;
  String? get thumbnailPath => throw _privateConstructorUsedError;
  String? get uploadStatus => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  bool get deleted => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AttachmentCopyWith<Attachment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttachmentCopyWith<$Res> {
  factory $AttachmentCopyWith(
          Attachment value, $Res Function(Attachment) then) =
      _$AttachmentCopyWithImpl<$Res, Attachment>;
  @useResult
  $Res call(
      {String id,
      String? driveFileId,
      String? localPath,
      String? mimeType,
      String? checksumSha256,
      int? fileSize,
      int? width,
      int? height,
      int? duration,
      String? thumbnailPath,
      String? uploadStatus,
      DateTime createdAt,
      DateTime updatedAt,
      int version,
      bool deleted});
}

/// @nodoc
class _$AttachmentCopyWithImpl<$Res, $Val extends Attachment>
    implements $AttachmentCopyWith<$Res> {
  _$AttachmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? driveFileId = freezed,
    Object? localPath = freezed,
    Object? mimeType = freezed,
    Object? checksumSha256 = freezed,
    Object? fileSize = freezed,
    Object? width = freezed,
    Object? height = freezed,
    Object? duration = freezed,
    Object? thumbnailPath = freezed,
    Object? uploadStatus = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? version = null,
    Object? deleted = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      driveFileId: freezed == driveFileId
          ? _value.driveFileId
          : driveFileId // ignore: cast_nullable_to_non_nullable
              as String?,
      localPath: freezed == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
      mimeType: freezed == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
      checksumSha256: freezed == checksumSha256
          ? _value.checksumSha256
          : checksumSha256 // ignore: cast_nullable_to_non_nullable
              as String?,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      duration: freezed == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int?,
      thumbnailPath: freezed == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String?,
      uploadStatus: freezed == uploadStatus
          ? _value.uploadStatus
          : uploadStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      deleted: null == deleted
          ? _value.deleted
          : deleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttachmentImplCopyWith<$Res>
    implements $AttachmentCopyWith<$Res> {
  factory _$$AttachmentImplCopyWith(
          _$AttachmentImpl value, $Res Function(_$AttachmentImpl) then) =
      __$$AttachmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? driveFileId,
      String? localPath,
      String? mimeType,
      String? checksumSha256,
      int? fileSize,
      int? width,
      int? height,
      int? duration,
      String? thumbnailPath,
      String? uploadStatus,
      DateTime createdAt,
      DateTime updatedAt,
      int version,
      bool deleted});
}

/// @nodoc
class __$$AttachmentImplCopyWithImpl<$Res>
    extends _$AttachmentCopyWithImpl<$Res, _$AttachmentImpl>
    implements _$$AttachmentImplCopyWith<$Res> {
  __$$AttachmentImplCopyWithImpl(
      _$AttachmentImpl _value, $Res Function(_$AttachmentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? driveFileId = freezed,
    Object? localPath = freezed,
    Object? mimeType = freezed,
    Object? checksumSha256 = freezed,
    Object? fileSize = freezed,
    Object? width = freezed,
    Object? height = freezed,
    Object? duration = freezed,
    Object? thumbnailPath = freezed,
    Object? uploadStatus = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? version = null,
    Object? deleted = null,
  }) {
    return _then(_$AttachmentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      driveFileId: freezed == driveFileId
          ? _value.driveFileId
          : driveFileId // ignore: cast_nullable_to_non_nullable
              as String?,
      localPath: freezed == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
      mimeType: freezed == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
      checksumSha256: freezed == checksumSha256
          ? _value.checksumSha256
          : checksumSha256 // ignore: cast_nullable_to_non_nullable
              as String?,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      duration: freezed == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int?,
      thumbnailPath: freezed == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String?,
      uploadStatus: freezed == uploadStatus
          ? _value.uploadStatus
          : uploadStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      deleted: null == deleted
          ? _value.deleted
          : deleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttachmentImpl implements _Attachment {
  const _$AttachmentImpl(
      {required this.id,
      this.driveFileId,
      this.localPath,
      this.mimeType,
      this.checksumSha256,
      this.fileSize,
      this.width,
      this.height,
      this.duration,
      this.thumbnailPath,
      this.uploadStatus,
      required this.createdAt,
      required this.updatedAt,
      required this.version,
      this.deleted = false});

  factory _$AttachmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttachmentImplFromJson(json);

  @override
  final String id;
  @override
  final String? driveFileId;
  @override
  final String? localPath;
  @override
  final String? mimeType;
  @override
  final String? checksumSha256;
  @override
  final int? fileSize;
  @override
  final int? width;
  @override
  final int? height;
  @override
  final int? duration;
  @override
  final String? thumbnailPath;
  @override
  final String? uploadStatus;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final int version;
  @override
  @JsonKey()
  final bool deleted;

  @override
  String toString() {
    return 'Attachment(id: $id, driveFileId: $driveFileId, localPath: $localPath, mimeType: $mimeType, checksumSha256: $checksumSha256, fileSize: $fileSize, width: $width, height: $height, duration: $duration, thumbnailPath: $thumbnailPath, uploadStatus: $uploadStatus, createdAt: $createdAt, updatedAt: $updatedAt, version: $version, deleted: $deleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttachmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.driveFileId, driveFileId) ||
                other.driveFileId == driveFileId) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.checksumSha256, checksumSha256) ||
                other.checksumSha256 == checksumSha256) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            (identical(other.uploadStatus, uploadStatus) ||
                other.uploadStatus == uploadStatus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.deleted, deleted) || other.deleted == deleted));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      driveFileId,
      localPath,
      mimeType,
      checksumSha256,
      fileSize,
      width,
      height,
      duration,
      thumbnailPath,
      uploadStatus,
      createdAt,
      updatedAt,
      version,
      deleted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AttachmentImplCopyWith<_$AttachmentImpl> get copyWith =>
      __$$AttachmentImplCopyWithImpl<_$AttachmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttachmentImplToJson(
      this,
    );
  }
}

abstract class _Attachment implements Attachment {
  const factory _Attachment(
      {required final String id,
      final String? driveFileId,
      final String? localPath,
      final String? mimeType,
      final String? checksumSha256,
      final int? fileSize,
      final int? width,
      final int? height,
      final int? duration,
      final String? thumbnailPath,
      final String? uploadStatus,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      required final int version,
      final bool deleted}) = _$AttachmentImpl;

  factory _Attachment.fromJson(Map<String, dynamic> json) =
      _$AttachmentImpl.fromJson;

  @override
  String get id;
  @override
  String? get driveFileId;
  @override
  String? get localPath;
  @override
  String? get mimeType;
  @override
  String? get checksumSha256;
  @override
  int? get fileSize;
  @override
  int? get width;
  @override
  int? get height;
  @override
  int? get duration;
  @override
  String? get thumbnailPath;
  @override
  String? get uploadStatus;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  int get version;
  @override
  bool get deleted;
  @override
  @JsonKey(ignore: true)
  _$$AttachmentImplCopyWith<_$AttachmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
