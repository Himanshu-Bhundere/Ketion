// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PagesTable extends Pages with TableInfo<$PagesTable, Page> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentPageIdMeta =
      const VerificationMeta('parentPageId');
  @override
  late final GeneratedColumn<String> parentPageId = GeneratedColumn<String>(
      'parent_page_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES pages (id) ON DELETE SET NULL'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverImageMeta =
      const VerificationMeta('coverImage');
  @override
  late final GeneratedColumn<String> coverImage = GeneratedColumn<String>(
      'cover_image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isTemplateMeta =
      const VerificationMeta('isTemplate');
  @override
  late final GeneratedColumn<bool> isTemplate = GeneratedColumn<bool>(
      'is_template', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_template" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        parentPageId,
        title,
        icon,
        coverImage,
        isFavorite,
        isArchived,
        deleted,
        isTemplate,
        version,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pages';
  @override
  VerificationContext validateIntegrity(Insertable<Page> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_page_id')) {
      context.handle(
          _parentPageIdMeta,
          parentPageId.isAcceptableOrUnknown(
              data['parent_page_id']!, _parentPageIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('cover_image')) {
      context.handle(
          _coverImageMeta,
          coverImage.isAcceptableOrUnknown(
              data['cover_image']!, _coverImageMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('is_template')) {
      context.handle(
          _isTemplateMeta,
          isTemplate.isAcceptableOrUnknown(
              data['is_template']!, _isTemplateMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Page map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Page(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      parentPageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_page_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      coverImage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_image']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      isTemplate: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_template'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PagesTable createAlias(String alias) {
    return $PagesTable(attachedDatabase, alias);
  }
}

class Page extends DataClass implements Insertable<Page> {
  final String id;
  final String? parentPageId;
  final String title;
  final String? icon;
  final String? coverImage;
  final bool isFavorite;
  final bool isArchived;
  final bool deleted;
  final bool isTemplate;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Page(
      {required this.id,
      this.parentPageId,
      required this.title,
      this.icon,
      this.coverImage,
      required this.isFavorite,
      required this.isArchived,
      required this.deleted,
      required this.isTemplate,
      required this.version,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentPageId != null) {
      map['parent_page_id'] = Variable<String>(parentPageId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || coverImage != null) {
      map['cover_image'] = Variable<String>(coverImage);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_archived'] = Variable<bool>(isArchived);
    map['deleted'] = Variable<bool>(deleted);
    map['is_template'] = Variable<bool>(isTemplate);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PagesCompanion toCompanion(bool nullToAbsent) {
    return PagesCompanion(
      id: Value(id),
      parentPageId: parentPageId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentPageId),
      title: Value(title),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      coverImage: coverImage == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImage),
      isFavorite: Value(isFavorite),
      isArchived: Value(isArchived),
      deleted: Value(deleted),
      isTemplate: Value(isTemplate),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Page.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Page(
      id: serializer.fromJson<String>(json['id']),
      parentPageId: serializer.fromJson<String?>(json['parentPageId']),
      title: serializer.fromJson<String>(json['title']),
      icon: serializer.fromJson<String?>(json['icon']),
      coverImage: serializer.fromJson<String?>(json['coverImage']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      isTemplate: serializer.fromJson<bool>(json['isTemplate']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentPageId': serializer.toJson<String?>(parentPageId),
      'title': serializer.toJson<String>(title),
      'icon': serializer.toJson<String?>(icon),
      'coverImage': serializer.toJson<String?>(coverImage),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isArchived': serializer.toJson<bool>(isArchived),
      'deleted': serializer.toJson<bool>(deleted),
      'isTemplate': serializer.toJson<bool>(isTemplate),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Page copyWith(
          {String? id,
          Value<String?> parentPageId = const Value.absent(),
          String? title,
          Value<String?> icon = const Value.absent(),
          Value<String?> coverImage = const Value.absent(),
          bool? isFavorite,
          bool? isArchived,
          bool? deleted,
          bool? isTemplate,
          int? version,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Page(
        id: id ?? this.id,
        parentPageId:
            parentPageId.present ? parentPageId.value : this.parentPageId,
        title: title ?? this.title,
        icon: icon.present ? icon.value : this.icon,
        coverImage: coverImage.present ? coverImage.value : this.coverImage,
        isFavorite: isFavorite ?? this.isFavorite,
        isArchived: isArchived ?? this.isArchived,
        deleted: deleted ?? this.deleted,
        isTemplate: isTemplate ?? this.isTemplate,
        version: version ?? this.version,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Page copyWithCompanion(PagesCompanion data) {
    return Page(
      id: data.id.present ? data.id.value : this.id,
      parentPageId: data.parentPageId.present
          ? data.parentPageId.value
          : this.parentPageId,
      title: data.title.present ? data.title.value : this.title,
      icon: data.icon.present ? data.icon.value : this.icon,
      coverImage:
          data.coverImage.present ? data.coverImage.value : this.coverImage,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isTemplate:
          data.isTemplate.present ? data.isTemplate.value : this.isTemplate,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Page(')
          ..write('id: $id, ')
          ..write('parentPageId: $parentPageId, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coverImage: $coverImage, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isArchived: $isArchived, ')
          ..write('deleted: $deleted, ')
          ..write('isTemplate: $isTemplate, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      parentPageId,
      title,
      icon,
      coverImage,
      isFavorite,
      isArchived,
      deleted,
      isTemplate,
      version,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Page &&
          other.id == this.id &&
          other.parentPageId == this.parentPageId &&
          other.title == this.title &&
          other.icon == this.icon &&
          other.coverImage == this.coverImage &&
          other.isFavorite == this.isFavorite &&
          other.isArchived == this.isArchived &&
          other.deleted == this.deleted &&
          other.isTemplate == this.isTemplate &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PagesCompanion extends UpdateCompanion<Page> {
  final Value<String> id;
  final Value<String?> parentPageId;
  final Value<String> title;
  final Value<String?> icon;
  final Value<String?> coverImage;
  final Value<bool> isFavorite;
  final Value<bool> isArchived;
  final Value<bool> deleted;
  final Value<bool> isTemplate;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PagesCompanion({
    this.id = const Value.absent(),
    this.parentPageId = const Value.absent(),
    this.title = const Value.absent(),
    this.icon = const Value.absent(),
    this.coverImage = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isTemplate = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PagesCompanion.insert({
    required String id,
    this.parentPageId = const Value.absent(),
    this.title = const Value.absent(),
    this.icon = const Value.absent(),
    this.coverImage = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isTemplate = const Value.absent(),
    this.version = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Page> custom({
    Expression<String>? id,
    Expression<String>? parentPageId,
    Expression<String>? title,
    Expression<String>? icon,
    Expression<String>? coverImage,
    Expression<bool>? isFavorite,
    Expression<bool>? isArchived,
    Expression<bool>? deleted,
    Expression<bool>? isTemplate,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentPageId != null) 'parent_page_id': parentPageId,
      if (title != null) 'title': title,
      if (icon != null) 'icon': icon,
      if (coverImage != null) 'cover_image': coverImage,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isArchived != null) 'is_archived': isArchived,
      if (deleted != null) 'deleted': deleted,
      if (isTemplate != null) 'is_template': isTemplate,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PagesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? parentPageId,
      Value<String>? title,
      Value<String?>? icon,
      Value<String?>? coverImage,
      Value<bool>? isFavorite,
      Value<bool>? isArchived,
      Value<bool>? deleted,
      Value<bool>? isTemplate,
      Value<int>? version,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return PagesCompanion(
      id: id ?? this.id,
      parentPageId: parentPageId ?? this.parentPageId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      coverImage: coverImage ?? this.coverImage,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      deleted: deleted ?? this.deleted,
      isTemplate: isTemplate ?? this.isTemplate,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentPageId.present) {
      map['parent_page_id'] = Variable<String>(parentPageId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (coverImage.present) {
      map['cover_image'] = Variable<String>(coverImage.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (isTemplate.present) {
      map['is_template'] = Variable<bool>(isTemplate.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagesCompanion(')
          ..write('id: $id, ')
          ..write('parentPageId: $parentPageId, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coverImage: $coverImage, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isArchived: $isArchived, ')
          ..write('deleted: $deleted, ')
          ..write('isTemplate: $isTemplate, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BlocksTable extends Blocks with TableInfo<$BlocksTable, Block> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES pages (id) ON DELETE CASCADE'));
  static const VerificationMeta _parentBlockIdMeta =
      const VerificationMeta('parentBlockId');
  @override
  late final GeneratedColumn<String> parentBlockId = GeneratedColumn<String>(
      'parent_block_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES blocks (id) ON DELETE CASCADE'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<double> position = GeneratedColumn<double>(
      'position', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pageId,
        parentBlockId,
        type,
        position,
        data,
        version,
        deleted,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blocks';
  @override
  VerificationContext validateIntegrity(Insertable<Block> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('parent_block_id')) {
      context.handle(
          _parentBlockIdMeta,
          parentBlockId.isAcceptableOrUnknown(
              data['parent_block_id']!, _parentBlockIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Block map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Block(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      parentBlockId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_block_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}position'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BlocksTable createAlias(String alias) {
    return $BlocksTable(attachedDatabase, alias);
  }
}

class Block extends DataClass implements Insertable<Block> {
  final String id;
  final String pageId;
  final String? parentBlockId;
  final String type;
  final double position;
  final String data;
  final int version;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Block(
      {required this.id,
      required this.pageId,
      this.parentBlockId,
      required this.type,
      required this.position,
      required this.data,
      required this.version,
      required this.deleted,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    if (!nullToAbsent || parentBlockId != null) {
      map['parent_block_id'] = Variable<String>(parentBlockId);
    }
    map['type'] = Variable<String>(type);
    map['position'] = Variable<double>(position);
    map['data'] = Variable<String>(data);
    map['version'] = Variable<int>(version);
    map['deleted'] = Variable<bool>(deleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BlocksCompanion toCompanion(bool nullToAbsent) {
    return BlocksCompanion(
      id: Value(id),
      pageId: Value(pageId),
      parentBlockId: parentBlockId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentBlockId),
      type: Value(type),
      position: Value(position),
      data: Value(data),
      version: Value(version),
      deleted: Value(deleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Block.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Block(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      parentBlockId: serializer.fromJson<String?>(json['parentBlockId']),
      type: serializer.fromJson<String>(json['type']),
      position: serializer.fromJson<double>(json['position']),
      data: serializer.fromJson<String>(json['data']),
      version: serializer.fromJson<int>(json['version']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'parentBlockId': serializer.toJson<String?>(parentBlockId),
      'type': serializer.toJson<String>(type),
      'position': serializer.toJson<double>(position),
      'data': serializer.toJson<String>(data),
      'version': serializer.toJson<int>(version),
      'deleted': serializer.toJson<bool>(deleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Block copyWith(
          {String? id,
          String? pageId,
          Value<String?> parentBlockId = const Value.absent(),
          String? type,
          double? position,
          String? data,
          int? version,
          bool? deleted,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Block(
        id: id ?? this.id,
        pageId: pageId ?? this.pageId,
        parentBlockId:
            parentBlockId.present ? parentBlockId.value : this.parentBlockId,
        type: type ?? this.type,
        position: position ?? this.position,
        data: data ?? this.data,
        version: version ?? this.version,
        deleted: deleted ?? this.deleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Block copyWithCompanion(BlocksCompanion data) {
    return Block(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      parentBlockId: data.parentBlockId.present
          ? data.parentBlockId.value
          : this.parentBlockId,
      type: data.type.present ? data.type.value : this.type,
      position: data.position.present ? data.position.value : this.position,
      data: data.data.present ? data.data.value : this.data,
      version: data.version.present ? data.version.value : this.version,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Block(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('parentBlockId: $parentBlockId, ')
          ..write('type: $type, ')
          ..write('position: $position, ')
          ..write('data: $data, ')
          ..write('version: $version, ')
          ..write('deleted: $deleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pageId, parentBlockId, type, position,
      data, version, deleted, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Block &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.parentBlockId == this.parentBlockId &&
          other.type == this.type &&
          other.position == this.position &&
          other.data == this.data &&
          other.version == this.version &&
          other.deleted == this.deleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BlocksCompanion extends UpdateCompanion<Block> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String?> parentBlockId;
  final Value<String> type;
  final Value<double> position;
  final Value<String> data;
  final Value<int> version;
  final Value<bool> deleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BlocksCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.parentBlockId = const Value.absent(),
    this.type = const Value.absent(),
    this.position = const Value.absent(),
    this.data = const Value.absent(),
    this.version = const Value.absent(),
    this.deleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlocksCompanion.insert({
    required String id,
    required String pageId,
    this.parentBlockId = const Value.absent(),
    required String type,
    required double position,
    required String data,
    this.version = const Value.absent(),
    this.deleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        pageId = Value(pageId),
        type = Value(type),
        position = Value(position),
        data = Value(data),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Block> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? parentBlockId,
    Expression<String>? type,
    Expression<double>? position,
    Expression<String>? data,
    Expression<int>? version,
    Expression<bool>? deleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (parentBlockId != null) 'parent_block_id': parentBlockId,
      if (type != null) 'type': type,
      if (position != null) 'position': position,
      if (data != null) 'data': data,
      if (version != null) 'version': version,
      if (deleted != null) 'deleted': deleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlocksCompanion copyWith(
      {Value<String>? id,
      Value<String>? pageId,
      Value<String?>? parentBlockId,
      Value<String>? type,
      Value<double>? position,
      Value<String>? data,
      Value<int>? version,
      Value<bool>? deleted,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BlocksCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      parentBlockId: parentBlockId ?? this.parentBlockId,
      type: type ?? this.type,
      position: position ?? this.position,
      data: data ?? this.data,
      version: version ?? this.version,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (parentBlockId.present) {
      map['parent_block_id'] = Variable<String>(parentBlockId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (position.present) {
      map['position'] = Variable<double>(position.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlocksCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('parentBlockId: $parentBlockId, ')
          ..write('type: $type, ')
          ..write('position: $position, ')
          ..write('data: $data, ')
          ..write('version: $version, ')
          ..write('deleted: $deleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, AttachmentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _blockIdMeta =
      const VerificationMeta('blockId');
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
      'block_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
      'sha256', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relativePathMeta =
      const VerificationMeta('relativePath');
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
      'relative_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pageId,
        blockId,
        fileName,
        mimeType,
        size,
        sha256,
        relativePath,
        thumbnailPath,
        createdAt,
        updatedAt,
        deleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(Insertable<AttachmentData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('block_id')) {
      context.handle(_blockIdMeta,
          blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta));
    } else if (isInserting) {
      context.missing(_blockIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(_sha256Meta,
          sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta));
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
          _relativePathMeta,
          relativePath.isAcceptableOrUnknown(
              data['relative_path']!, _relativePathMeta));
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      blockId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}block_id'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      sha256: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sha256'])!,
      relativePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relative_path'])!,
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class AttachmentData extends DataClass implements Insertable<AttachmentData> {
  final String id;
  final String pageId;
  final String blockId;
  final String fileName;
  final String mimeType;
  final int size;
  final String sha256;
  final String relativePath;
  final String? thumbnailPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  const AttachmentData(
      {required this.id,
      required this.pageId,
      required this.blockId,
      required this.fileName,
      required this.mimeType,
      required this.size,
      required this.sha256,
      required this.relativePath,
      this.thumbnailPath,
      required this.createdAt,
      required this.updatedAt,
      required this.deleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['block_id'] = Variable<String>(blockId);
    map['file_name'] = Variable<String>(fileName);
    map['mime_type'] = Variable<String>(mimeType);
    map['size'] = Variable<int>(size);
    map['sha256'] = Variable<String>(sha256);
    map['relative_path'] = Variable<String>(relativePath);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      pageId: Value(pageId),
      blockId: Value(blockId),
      fileName: Value(fileName),
      mimeType: Value(mimeType),
      size: Value(size),
      sha256: Value(sha256),
      relativePath: Value(relativePath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
    );
  }

  factory AttachmentData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentData(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      blockId: serializer.fromJson<String>(json['blockId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      size: serializer.fromJson<int>(json['size']),
      sha256: serializer.fromJson<String>(json['sha256']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'blockId': serializer.toJson<String>(blockId),
      'fileName': serializer.toJson<String>(fileName),
      'mimeType': serializer.toJson<String>(mimeType),
      'size': serializer.toJson<int>(size),
      'sha256': serializer.toJson<String>(sha256),
      'relativePath': serializer.toJson<String>(relativePath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  AttachmentData copyWith(
          {String? id,
          String? pageId,
          String? blockId,
          String? fileName,
          String? mimeType,
          int? size,
          String? sha256,
          String? relativePath,
          Value<String?> thumbnailPath = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? deleted}) =>
      AttachmentData(
        id: id ?? this.id,
        pageId: pageId ?? this.pageId,
        blockId: blockId ?? this.blockId,
        fileName: fileName ?? this.fileName,
        mimeType: mimeType ?? this.mimeType,
        size: size ?? this.size,
        sha256: sha256 ?? this.sha256,
        relativePath: relativePath ?? this.relativePath,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );
  AttachmentData copyWithCompanion(AttachmentsCompanion data) {
    return AttachmentData(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      size: data.size.present ? data.size.value : this.size,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentData(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('blockId: $blockId, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('sha256: $sha256, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pageId, blockId, fileName, mimeType, size,
      sha256, relativePath, thumbnailPath, createdAt, updatedAt, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentData &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.blockId == this.blockId &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.size == this.size &&
          other.sha256 == this.sha256 &&
          other.relativePath == this.relativePath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted);
}

class AttachmentsCompanion extends UpdateCompanion<AttachmentData> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String> blockId;
  final Value<String> fileName;
  final Value<String> mimeType;
  final Value<int> size;
  final Value<String> sha256;
  final Value<String> relativePath;
  final Value<String?> thumbnailPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.blockId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.size = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String pageId,
    required String blockId,
    required String fileName,
    required String mimeType,
    required int size,
    required String sha256,
    required String relativePath,
    this.thumbnailPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        pageId = Value(pageId),
        blockId = Value(blockId),
        fileName = Value(fileName),
        mimeType = Value(mimeType),
        size = Value(size),
        sha256 = Value(sha256),
        relativePath = Value(relativePath);
  static Insertable<AttachmentData> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? blockId,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<int>? size,
    Expression<String>? sha256,
    Expression<String>? relativePath,
    Expression<String>? thumbnailPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (blockId != null) 'block_id': blockId,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (size != null) 'size': size,
      if (sha256 != null) 'sha256': sha256,
      if (relativePath != null) 'relative_path': relativePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? pageId,
      Value<String>? blockId,
      Value<String>? fileName,
      Value<String>? mimeType,
      Value<int>? size,
      Value<String>? sha256,
      Value<String>? relativePath,
      Value<String?>? thumbnailPath,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? deleted,
      Value<int>? rowid}) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      blockId: blockId ?? this.blockId,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      sha256: sha256 ?? this.sha256,
      relativePath: relativePath ?? this.relativePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('blockId: $blockId, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('size: $size, ')
          ..write('sha256: $sha256, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES pages (id) ON DELETE CASCADE'));
  static const VerificationMeta _blockIdMeta =
      const VerificationMeta('blockId');
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
      'block_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES blocks (id) ON DELETE CASCADE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _reminderTimeMeta =
      const VerificationMeta('reminderTime');
  @override
  late final GeneratedColumn<DateTime> reminderTime = GeneratedColumn<DateTime>(
      'reminder_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _timezoneMeta =
      const VerificationMeta('timezone');
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
      'timezone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('UTC'));
  static const VerificationMeta _recurrenceRuleMeta =
      const VerificationMeta('recurrenceRule');
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
      'recurrence_rule', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _snoozeUntilMeta =
      const VerificationMeta('snoozeUntil');
  @override
  late final GeneratedColumn<DateTime> snoozeUntil = GeneratedColumn<DateTime>(
      'snooze_until', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
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
        deleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(Insertable<Reminder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('block_id')) {
      context.handle(_blockIdMeta,
          blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
          _reminderTimeMeta,
          reminderTime.isAcceptableOrUnknown(
              data['reminder_time']!, _reminderTimeMeta));
    } else if (isInserting) {
      context.missing(_reminderTimeMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(_timezoneMeta,
          timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta));
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
          _recurrenceRuleMeta,
          recurrenceRule.isAcceptableOrUnknown(
              data['recurrence_rule']!, _recurrenceRuleMeta));
    }
    if (data.containsKey('snooze_until')) {
      context.handle(
          _snoozeUntilMeta,
          snoozeUntil.isAcceptableOrUnknown(
              data['snooze_until']!, _snoozeUntilMeta));
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      blockId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}block_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      reminderTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}reminder_time'])!,
      timezone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timezone'])!,
      recurrenceRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurrence_rule']),
      snoozeUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}snooze_until']),
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final String id;
  final String pageId;
  final String? blockId;
  final String title;
  final DateTime reminderTime;
  final String timezone;
  final String? recurrenceRule;
  final DateTime? snoozeUntil;
  final bool completed;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  const Reminder(
      {required this.id,
      required this.pageId,
      this.blockId,
      required this.title,
      required this.reminderTime,
      required this.timezone,
      this.recurrenceRule,
      this.snoozeUntil,
      required this.completed,
      required this.version,
      required this.createdAt,
      required this.updatedAt,
      required this.deleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    if (!nullToAbsent || blockId != null) {
      map['block_id'] = Variable<String>(blockId);
    }
    map['title'] = Variable<String>(title);
    map['reminder_time'] = Variable<DateTime>(reminderTime);
    map['timezone'] = Variable<String>(timezone);
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    if (!nullToAbsent || snoozeUntil != null) {
      map['snooze_until'] = Variable<DateTime>(snoozeUntil);
    }
    map['completed'] = Variable<bool>(completed);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      pageId: Value(pageId),
      blockId: blockId == null && nullToAbsent
          ? const Value.absent()
          : Value(blockId),
      title: Value(title),
      reminderTime: Value(reminderTime),
      timezone: Value(timezone),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      snoozeUntil: snoozeUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozeUntil),
      completed: Value(completed),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      blockId: serializer.fromJson<String?>(json['blockId']),
      title: serializer.fromJson<String>(json['title']),
      reminderTime: serializer.fromJson<DateTime>(json['reminderTime']),
      timezone: serializer.fromJson<String>(json['timezone']),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      snoozeUntil: serializer.fromJson<DateTime?>(json['snoozeUntil']),
      completed: serializer.fromJson<bool>(json['completed']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'blockId': serializer.toJson<String?>(blockId),
      'title': serializer.toJson<String>(title),
      'reminderTime': serializer.toJson<DateTime>(reminderTime),
      'timezone': serializer.toJson<String>(timezone),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'snoozeUntil': serializer.toJson<DateTime?>(snoozeUntil),
      'completed': serializer.toJson<bool>(completed),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  Reminder copyWith(
          {String? id,
          String? pageId,
          Value<String?> blockId = const Value.absent(),
          String? title,
          DateTime? reminderTime,
          String? timezone,
          Value<String?> recurrenceRule = const Value.absent(),
          Value<DateTime?> snoozeUntil = const Value.absent(),
          bool? completed,
          int? version,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? deleted}) =>
      Reminder(
        id: id ?? this.id,
        pageId: pageId ?? this.pageId,
        blockId: blockId.present ? blockId.value : this.blockId,
        title: title ?? this.title,
        reminderTime: reminderTime ?? this.reminderTime,
        timezone: timezone ?? this.timezone,
        recurrenceRule:
            recurrenceRule.present ? recurrenceRule.value : this.recurrenceRule,
        snoozeUntil: snoozeUntil.present ? snoozeUntil.value : this.snoozeUntil,
        completed: completed ?? this.completed,
        version: version ?? this.version,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      title: data.title.present ? data.title.value : this.title,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      snoozeUntil:
          data.snoozeUntil.present ? data.snoozeUntil.value : this.snoozeUntil,
      completed: data.completed.present ? data.completed.value : this.completed,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('blockId: $blockId, ')
          ..write('title: $title, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('timezone: $timezone, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('snoozeUntil: $snoozeUntil, ')
          ..write('completed: $completed, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.blockId == this.blockId &&
          other.title == this.title &&
          other.reminderTime == this.reminderTime &&
          other.timezone == this.timezone &&
          other.recurrenceRule == this.recurrenceRule &&
          other.snoozeUntil == this.snoozeUntil &&
          other.completed == this.completed &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String?> blockId;
  final Value<String> title;
  final Value<DateTime> reminderTime;
  final Value<String> timezone;
  final Value<String?> recurrenceRule;
  final Value<DateTime?> snoozeUntil;
  final Value<bool> completed;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.blockId = const Value.absent(),
    this.title = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.timezone = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.snoozeUntil = const Value.absent(),
    this.completed = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String pageId,
    this.blockId = const Value.absent(),
    this.title = const Value.absent(),
    required DateTime reminderTime,
    this.timezone = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.snoozeUntil = const Value.absent(),
    this.completed = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        pageId = Value(pageId),
        reminderTime = Value(reminderTime);
  static Insertable<Reminder> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? blockId,
    Expression<String>? title,
    Expression<DateTime>? reminderTime,
    Expression<String>? timezone,
    Expression<String>? recurrenceRule,
    Expression<DateTime>? snoozeUntil,
    Expression<bool>? completed,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (blockId != null) 'block_id': blockId,
      if (title != null) 'title': title,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (timezone != null) 'timezone': timezone,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (snoozeUntil != null) 'snooze_until': snoozeUntil,
      if (completed != null) 'completed': completed,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith(
      {Value<String>? id,
      Value<String>? pageId,
      Value<String?>? blockId,
      Value<String>? title,
      Value<DateTime>? reminderTime,
      Value<String>? timezone,
      Value<String?>? recurrenceRule,
      Value<DateTime?>? snoozeUntil,
      Value<bool>? completed,
      Value<int>? version,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? deleted,
      Value<int>? rowid}) {
    return RemindersCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      blockId: blockId ?? this.blockId,
      title: title ?? this.title,
      reminderTime: reminderTime ?? this.reminderTime,
      timezone: timezone ?? this.timezone,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      completed: completed ?? this.completed,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<DateTime>(reminderTime.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (snoozeUntil.present) {
      map['snooze_until'] = Variable<DateTime>(snoozeUntil.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('blockId: $blockId, ')
          ..write('title: $title, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('timezone: $timezone, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('snoozeUntil: $snoozeUntil, ')
          ..write('completed: $completed, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, Collection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, icon, color, version, createdAt, updatedAt, deleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(Insertable<Collection> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Collection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Collection(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class Collection extends DataClass implements Insertable<Collection> {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  const Collection(
      {required this.id,
      required this.name,
      this.icon,
      this.color,
      required this.version,
      required this.createdAt,
      required this.updatedAt,
      required this.deleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      id: Value(id),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
    );
  }

  factory Collection.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Collection(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<String?>(json['color']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<String?>(color),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  Collection copyWith(
          {String? id,
          String? name,
          Value<String?> icon = const Value.absent(),
          Value<String?> color = const Value.absent(),
          int? version,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? deleted}) =>
      Collection(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon.present ? icon.value : this.icon,
        color: color.present ? color.value : this.color,
        version: version ?? this.version,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );
  Collection copyWithCompanion(CollectionsCompanion data) {
    return Collection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Collection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, icon, color, version, createdAt, updatedAt, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collection &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted);
}

class CollectionsCompanion extends UpdateCompanion<Collection> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> icon;
  final Value<String?> color;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<int> rowid;
  const CollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionsCompanion.insert({
    required String id,
    required String name,
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Collection> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? icon,
      Value<String?>? color,
      Value<int>? version,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? deleted,
      Value<int>? rowid}) {
    return CollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, color, version, createdAt, updatedAt, deleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<Tag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String name;
  final String? color;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  const Tag(
      {required this.id,
      required this.name,
      this.color,
      required this.version,
      required this.createdAt,
      required this.updatedAt,
      required this.deleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  Tag copyWith(
          {String? id,
          String? name,
          Value<String?> color = const Value.absent(),
          int? version,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? deleted}) =>
      Tag(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
        version: version ?? this.version,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, version, createdAt, updatedAt, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> color;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> deleted;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? color,
      Value<int>? version,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? deleted,
      Value<int>? rowid}) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryPagesTable extends HistoryPages
    with TableInfo<$HistoryPagesTable, HistoryPage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES pages (id) ON DELETE CASCADE'));
  static const VerificationMeta _snapshotVersionMeta =
      const VerificationMeta('snapshotVersion');
  @override
  late final GeneratedColumn<int> snapshotVersion = GeneratedColumn<int>(
      'snapshot_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _compressedSnapshotMeta =
      const VerificationMeta('compressedSnapshot');
  @override
  late final GeneratedColumn<Uint8List> compressedSnapshot =
      GeneratedColumn<Uint8List>('compressed_snapshot', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, pageId, snapshotVersion, compressedSnapshot, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_pages';
  @override
  VerificationContext validateIntegrity(Insertable<HistoryPage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('snapshot_version')) {
      context.handle(
          _snapshotVersionMeta,
          snapshotVersion.isAcceptableOrUnknown(
              data['snapshot_version']!, _snapshotVersionMeta));
    } else if (isInserting) {
      context.missing(_snapshotVersionMeta);
    }
    if (data.containsKey('compressed_snapshot')) {
      context.handle(
          _compressedSnapshotMeta,
          compressedSnapshot.isAcceptableOrUnknown(
              data['compressed_snapshot']!, _compressedSnapshotMeta));
    } else if (isInserting) {
      context.missing(_compressedSnapshotMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryPage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryPage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      snapshotVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}snapshot_version'])!,
      compressedSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.blob, data['${effectivePrefix}compressed_snapshot'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $HistoryPagesTable createAlias(String alias) {
    return $HistoryPagesTable(attachedDatabase, alias);
  }
}

class HistoryPage extends DataClass implements Insertable<HistoryPage> {
  final String id;
  final String pageId;
  final int snapshotVersion;
  final Uint8List compressedSnapshot;
  final DateTime createdAt;
  const HistoryPage(
      {required this.id,
      required this.pageId,
      required this.snapshotVersion,
      required this.compressedSnapshot,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['snapshot_version'] = Variable<int>(snapshotVersion);
    map['compressed_snapshot'] = Variable<Uint8List>(compressedSnapshot);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HistoryPagesCompanion toCompanion(bool nullToAbsent) {
    return HistoryPagesCompanion(
      id: Value(id),
      pageId: Value(pageId),
      snapshotVersion: Value(snapshotVersion),
      compressedSnapshot: Value(compressedSnapshot),
      createdAt: Value(createdAt),
    );
  }

  factory HistoryPage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryPage(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      snapshotVersion: serializer.fromJson<int>(json['snapshotVersion']),
      compressedSnapshot:
          serializer.fromJson<Uint8List>(json['compressedSnapshot']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'snapshotVersion': serializer.toJson<int>(snapshotVersion),
      'compressedSnapshot': serializer.toJson<Uint8List>(compressedSnapshot),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HistoryPage copyWith(
          {String? id,
          String? pageId,
          int? snapshotVersion,
          Uint8List? compressedSnapshot,
          DateTime? createdAt}) =>
      HistoryPage(
        id: id ?? this.id,
        pageId: pageId ?? this.pageId,
        snapshotVersion: snapshotVersion ?? this.snapshotVersion,
        compressedSnapshot: compressedSnapshot ?? this.compressedSnapshot,
        createdAt: createdAt ?? this.createdAt,
      );
  HistoryPage copyWithCompanion(HistoryPagesCompanion data) {
    return HistoryPage(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      snapshotVersion: data.snapshotVersion.present
          ? data.snapshotVersion.value
          : this.snapshotVersion,
      compressedSnapshot: data.compressedSnapshot.present
          ? data.compressedSnapshot.value
          : this.compressedSnapshot,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryPage(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('snapshotVersion: $snapshotVersion, ')
          ..write('compressedSnapshot: $compressedSnapshot, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pageId, snapshotVersion,
      $driftBlobEquality.hash(compressedSnapshot), createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryPage &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.snapshotVersion == this.snapshotVersion &&
          $driftBlobEquality.equals(
              other.compressedSnapshot, this.compressedSnapshot) &&
          other.createdAt == this.createdAt);
}

class HistoryPagesCompanion extends UpdateCompanion<HistoryPage> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<int> snapshotVersion;
  final Value<Uint8List> compressedSnapshot;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const HistoryPagesCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.snapshotVersion = const Value.absent(),
    this.compressedSnapshot = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryPagesCompanion.insert({
    required String id,
    required String pageId,
    required int snapshotVersion,
    required Uint8List compressedSnapshot,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        pageId = Value(pageId),
        snapshotVersion = Value(snapshotVersion),
        compressedSnapshot = Value(compressedSnapshot),
        createdAt = Value(createdAt);
  static Insertable<HistoryPage> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<int>? snapshotVersion,
    Expression<Uint8List>? compressedSnapshot,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (snapshotVersion != null) 'snapshot_version': snapshotVersion,
      if (compressedSnapshot != null) 'compressed_snapshot': compressedSnapshot,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryPagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? pageId,
      Value<int>? snapshotVersion,
      Value<Uint8List>? compressedSnapshot,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return HistoryPagesCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      snapshotVersion: snapshotVersion ?? this.snapshotVersion,
      compressedSnapshot: compressedSnapshot ?? this.compressedSnapshot,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (snapshotVersion.present) {
      map['snapshot_version'] = Variable<int>(snapshotVersion.value);
    }
    if (compressedSnapshot.present) {
      map['compressed_snapshot'] =
          Variable<Uint8List>(compressedSnapshot.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryPagesCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('snapshotVersion: $snapshotVersion, ')
          ..write('compressedSnapshot: $compressedSnapshot, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PageCollectionsTable extends PageCollections
    with TableInfo<$PageCollectionsTable, PageCollection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PageCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES pages (id) ON DELETE CASCADE'));
  static const VerificationMeta _collectionIdMeta =
      const VerificationMeta('collectionId');
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
      'collection_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES collections (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [pageId, collectionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'page_collections';
  @override
  VerificationContext validateIntegrity(Insertable<PageCollection> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
          _collectionIdMeta,
          collectionId.isAcceptableOrUnknown(
              data['collection_id']!, _collectionIdMeta));
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pageId, collectionId};
  @override
  PageCollection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageCollection(
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      collectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}collection_id'])!,
    );
  }

  @override
  $PageCollectionsTable createAlias(String alias) {
    return $PageCollectionsTable(attachedDatabase, alias);
  }
}

class PageCollection extends DataClass implements Insertable<PageCollection> {
  final String pageId;
  final String collectionId;
  const PageCollection({required this.pageId, required this.collectionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page_id'] = Variable<String>(pageId);
    map['collection_id'] = Variable<String>(collectionId);
    return map;
  }

  PageCollectionsCompanion toCompanion(bool nullToAbsent) {
    return PageCollectionsCompanion(
      pageId: Value(pageId),
      collectionId: Value(collectionId),
    );
  }

  factory PageCollection.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageCollection(
      pageId: serializer.fromJson<String>(json['pageId']),
      collectionId: serializer.fromJson<String>(json['collectionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pageId': serializer.toJson<String>(pageId),
      'collectionId': serializer.toJson<String>(collectionId),
    };
  }

  PageCollection copyWith({String? pageId, String? collectionId}) =>
      PageCollection(
        pageId: pageId ?? this.pageId,
        collectionId: collectionId ?? this.collectionId,
      );
  PageCollection copyWithCompanion(PageCollectionsCompanion data) {
    return PageCollection(
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageCollection(')
          ..write('pageId: $pageId, ')
          ..write('collectionId: $collectionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pageId, collectionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageCollection &&
          other.pageId == this.pageId &&
          other.collectionId == this.collectionId);
}

class PageCollectionsCompanion extends UpdateCompanion<PageCollection> {
  final Value<String> pageId;
  final Value<String> collectionId;
  final Value<int> rowid;
  const PageCollectionsCompanion({
    this.pageId = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PageCollectionsCompanion.insert({
    required String pageId,
    required String collectionId,
    this.rowid = const Value.absent(),
  })  : pageId = Value(pageId),
        collectionId = Value(collectionId);
  static Insertable<PageCollection> custom({
    Expression<String>? pageId,
    Expression<String>? collectionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pageId != null) 'page_id': pageId,
      if (collectionId != null) 'collection_id': collectionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PageCollectionsCompanion copyWith(
      {Value<String>? pageId, Value<String>? collectionId, Value<int>? rowid}) {
    return PageCollectionsCompanion(
      pageId: pageId ?? this.pageId,
      collectionId: collectionId ?? this.collectionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PageCollectionsCompanion(')
          ..write('pageId: $pageId, ')
          ..write('collectionId: $collectionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PageTagsTable extends PageTags with TableInfo<$PageTagsTable, PageTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PageTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES pages (id) ON DELETE CASCADE'));
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tags (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [pageId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'page_tags';
  @override
  VerificationContext validateIntegrity(Insertable<PageTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pageId, tagId};
  @override
  PageTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageTag(
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  $PageTagsTable createAlias(String alias) {
    return $PageTagsTable(attachedDatabase, alias);
  }
}

class PageTag extends DataClass implements Insertable<PageTag> {
  final String pageId;
  final String tagId;
  const PageTag({required this.pageId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page_id'] = Variable<String>(pageId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  PageTagsCompanion toCompanion(bool nullToAbsent) {
    return PageTagsCompanion(
      pageId: Value(pageId),
      tagId: Value(tagId),
    );
  }

  factory PageTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageTag(
      pageId: serializer.fromJson<String>(json['pageId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pageId': serializer.toJson<String>(pageId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  PageTag copyWith({String? pageId, String? tagId}) => PageTag(
        pageId: pageId ?? this.pageId,
        tagId: tagId ?? this.tagId,
      );
  PageTag copyWithCompanion(PageTagsCompanion data) {
    return PageTag(
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageTag(')
          ..write('pageId: $pageId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pageId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageTag &&
          other.pageId == this.pageId &&
          other.tagId == this.tagId);
}

class PageTagsCompanion extends UpdateCompanion<PageTag> {
  final Value<String> pageId;
  final Value<String> tagId;
  final Value<int> rowid;
  const PageTagsCompanion({
    this.pageId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PageTagsCompanion.insert({
    required String pageId,
    required String tagId,
    this.rowid = const Value.absent(),
  })  : pageId = Value(pageId),
        tagId = Value(tagId);
  static Insertable<PageTag> custom({
    Expression<String>? pageId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pageId != null) 'page_id': pageId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PageTagsCompanion copyWith(
      {Value<String>? pageId, Value<String>? tagId, Value<int>? rowid}) {
    return PageTagsCompanion(
      pageId: pageId ?? this.pageId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PageTagsCompanion(')
          ..write('pageId: $pageId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTableMeta =
      const VerificationMeta('entityTable');
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
      'entity_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>('last_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
      'next_retry_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityTable,
        entityId,
        operation,
        payload,
        createdAt,
        status,
        attemptCount,
        lastAttemptAt,
        nextRetryAt,
        lastError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_table')) {
      context.handle(
          _entityTableMeta,
          entityTable.isAcceptableOrUnknown(
              data['entity_table']!, _entityTableMeta));
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      entityTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_table'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempt_at']),
      nextRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_retry_at']),
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;
  final String entityTable;
  final String entityId;
  final String operation;
  final String? payload;
  final DateTime createdAt;
  final String status;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;
  final String? lastError;
  const SyncQueueData(
      {required this.id,
      required this.entityTable,
      required this.entityId,
      required this.operation,
      this.payload,
      required this.createdAt,
      required this.status,
      required this.attemptCount,
      this.lastAttemptAt,
      this.nextRetryAt,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_table'] = Variable<String>(entityTable);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityTable: Value(entityTable),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      createdAt: Value(createdAt),
      status: Value(status),
      attemptCount: Value(attemptCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String?>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityTable': serializer.toJson<String>(entityTable),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String?>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueData copyWith(
          {String? id,
          String? entityTable,
          String? entityId,
          String? operation,
          Value<String?> payload = const Value.absent(),
          DateTime? createdAt,
          String? status,
          int? attemptCount,
          Value<DateTime?> lastAttemptAt = const Value.absent(),
          Value<DateTime?> nextRetryAt = const Value.absent(),
          Value<String?> lastError = const Value.absent()}) =>
      SyncQueueData(
        id: id ?? this.id,
        entityTable: entityTable ?? this.entityTable,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payload: payload.present ? payload.value : this.payload,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        attemptCount: attemptCount ?? this.attemptCount,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
        nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityTable:
          data.entityTable.present ? data.entityTable.value : this.entityTable,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityTable, entityId, operation, payload,
      createdAt, status, attemptCount, lastAttemptAt, nextRetryAt, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityTable == this.entityTable &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastError == this.lastError);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> entityTable;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String?> payload;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> nextRetryAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String entityTable,
    required String entityId,
    required String operation,
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        entityTable = Value(entityTable),
        entityId = Value(entityId),
        operation = Value(operation);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? entityTable,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityTable != null) 'entity_table': entityTable,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<String>? id,
      Value<String>? entityTable,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String?>? payload,
      Value<DateTime>? createdAt,
      Value<String>? status,
      Value<int>? attemptCount,
      Value<DateTime?>? lastAttemptAt,
      Value<DateTime?>? nextRetryAt,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityTable: entityTable ?? this.entityTable,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastAppliedGenerationMeta =
      const VerificationMeta('lastAppliedGeneration');
  @override
  late final GeneratedColumn<int> lastAppliedGeneration = GeneratedColumn<int>(
      'last_applied_generation', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastSyncTimeMeta =
      const VerificationMeta('lastSyncTime');
  @override
  late final GeneratedColumn<DateTime> lastSyncTime = GeneratedColumn<DateTime>(
      'last_sync_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [deviceId, provider, lastAppliedGeneration, lastSyncTime];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_states';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('last_applied_generation')) {
      context.handle(
          _lastAppliedGenerationMeta,
          lastAppliedGeneration.isAcceptableOrUnknown(
              data['last_applied_generation']!, _lastAppliedGenerationMeta));
    }
    if (data.containsKey('last_sync_time')) {
      context.handle(
          _lastSyncTimeMeta,
          lastSyncTime.isAcceptableOrUnknown(
              data['last_sync_time']!, _lastSyncTimeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, provider};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider'])!,
      lastAppliedGeneration: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_applied_generation'])!,
      lastSyncTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_sync_time']),
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String deviceId;
  final String provider;
  final int lastAppliedGeneration;
  final DateTime? lastSyncTime;
  const SyncStateData(
      {required this.deviceId,
      required this.provider,
      required this.lastAppliedGeneration,
      this.lastSyncTime});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['provider'] = Variable<String>(provider);
    map['last_applied_generation'] = Variable<int>(lastAppliedGeneration);
    if (!nullToAbsent || lastSyncTime != null) {
      map['last_sync_time'] = Variable<DateTime>(lastSyncTime);
    }
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(
      deviceId: Value(deviceId),
      provider: Value(provider),
      lastAppliedGeneration: Value(lastAppliedGeneration),
      lastSyncTime: lastSyncTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncTime),
    );
  }

  factory SyncStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      provider: serializer.fromJson<String>(json['provider']),
      lastAppliedGeneration:
          serializer.fromJson<int>(json['lastAppliedGeneration']),
      lastSyncTime: serializer.fromJson<DateTime?>(json['lastSyncTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'provider': serializer.toJson<String>(provider),
      'lastAppliedGeneration': serializer.toJson<int>(lastAppliedGeneration),
      'lastSyncTime': serializer.toJson<DateTime?>(lastSyncTime),
    };
  }

  SyncStateData copyWith(
          {String? deviceId,
          String? provider,
          int? lastAppliedGeneration,
          Value<DateTime?> lastSyncTime = const Value.absent()}) =>
      SyncStateData(
        deviceId: deviceId ?? this.deviceId,
        provider: provider ?? this.provider,
        lastAppliedGeneration:
            lastAppliedGeneration ?? this.lastAppliedGeneration,
        lastSyncTime:
            lastSyncTime.present ? lastSyncTime.value : this.lastSyncTime,
      );
  SyncStateData copyWithCompanion(SyncStatesCompanion data) {
    return SyncStateData(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      provider: data.provider.present ? data.provider.value : this.provider,
      lastAppliedGeneration: data.lastAppliedGeneration.present
          ? data.lastAppliedGeneration.value
          : this.lastAppliedGeneration,
      lastSyncTime: data.lastSyncTime.present
          ? data.lastSyncTime.value
          : this.lastSyncTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('deviceId: $deviceId, ')
          ..write('provider: $provider, ')
          ..write('lastAppliedGeneration: $lastAppliedGeneration, ')
          ..write('lastSyncTime: $lastSyncTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(deviceId, provider, lastAppliedGeneration, lastSyncTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.deviceId == this.deviceId &&
          other.provider == this.provider &&
          other.lastAppliedGeneration == this.lastAppliedGeneration &&
          other.lastSyncTime == this.lastSyncTime);
}

class SyncStatesCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> deviceId;
  final Value<String> provider;
  final Value<int> lastAppliedGeneration;
  final Value<DateTime?> lastSyncTime;
  final Value<int> rowid;
  const SyncStatesCompanion({
    this.deviceId = const Value.absent(),
    this.provider = const Value.absent(),
    this.lastAppliedGeneration = const Value.absent(),
    this.lastSyncTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    required String deviceId,
    required String provider,
    this.lastAppliedGeneration = const Value.absent(),
    this.lastSyncTime = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        provider = Value(provider);
  static Insertable<SyncStateData> custom({
    Expression<String>? deviceId,
    Expression<String>? provider,
    Expression<int>? lastAppliedGeneration,
    Expression<DateTime>? lastSyncTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (provider != null) 'provider': provider,
      if (lastAppliedGeneration != null)
        'last_applied_generation': lastAppliedGeneration,
      if (lastSyncTime != null) 'last_sync_time': lastSyncTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatesCompanion copyWith(
      {Value<String>? deviceId,
      Value<String>? provider,
      Value<int>? lastAppliedGeneration,
      Value<DateTime?>? lastSyncTime,
      Value<int>? rowid}) {
    return SyncStatesCompanion(
      deviceId: deviceId ?? this.deviceId,
      provider: provider ?? this.provider,
      lastAppliedGeneration:
          lastAppliedGeneration ?? this.lastAppliedGeneration,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (lastAppliedGeneration.present) {
      map['last_applied_generation'] =
          Variable<int>(lastAppliedGeneration.value);
    }
    if (lastSyncTime.present) {
      map['last_sync_time'] = Variable<DateTime>(lastSyncTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('provider: $provider, ')
          ..write('lastAppliedGeneration: $lastAppliedGeneration, ')
          ..write('lastSyncTime: $lastSyncTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTableTable extends AppSettingsTable
    with TableInfo<$AppSettingsTableTable, AppSettingEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('System'));
  static const VerificationMeta _syncFrequencyMeta =
      const VerificationMeta('syncFrequency');
  @override
  late final GeneratedColumn<String> syncFrequency = GeneratedColumn<String>(
      'sync_frequency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('15 minutes'));
  static const VerificationMeta _autoSyncMeta =
      const VerificationMeta('autoSync');
  @override
  late final GeneratedColumn<bool> autoSync = GeneratedColumn<bool>(
      'auto_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("auto_sync" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _cacheLimitMBMeta =
      const VerificationMeta('cacheLimitMB');
  @override
  late final GeneratedColumn<int> cacheLimitMB = GeneratedColumn<int>(
      'cache_limit_m_b', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(100));
  static const VerificationMeta _lastCleanupMeta =
      const VerificationMeta('lastCleanup');
  @override
  late final GeneratedColumn<DateTime> lastCleanup = GeneratedColumn<DateTime>(
      'last_cleanup', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        themeMode,
        syncFrequency,
        autoSync,
        cacheLimitMB,
        lastCleanup,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings_table';
  @override
  VerificationContext validateIntegrity(Insertable<AppSettingEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    }
    if (data.containsKey('sync_frequency')) {
      context.handle(
          _syncFrequencyMeta,
          syncFrequency.isAcceptableOrUnknown(
              data['sync_frequency']!, _syncFrequencyMeta));
    }
    if (data.containsKey('auto_sync')) {
      context.handle(_autoSyncMeta,
          autoSync.isAcceptableOrUnknown(data['auto_sync']!, _autoSyncMeta));
    }
    if (data.containsKey('cache_limit_m_b')) {
      context.handle(
          _cacheLimitMBMeta,
          cacheLimitMB.isAcceptableOrUnknown(
              data['cache_limit_m_b']!, _cacheLimitMBMeta));
    }
    if (data.containsKey('last_cleanup')) {
      context.handle(
          _lastCleanupMeta,
          lastCleanup.isAcceptableOrUnknown(
              data['last_cleanup']!, _lastCleanupMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      syncFrequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_frequency'])!,
      autoSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}auto_sync'])!,
      cacheLimitMB: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cache_limit_m_b'])!,
      lastCleanup: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_cleanup']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTableTable createAlias(String alias) {
    return $AppSettingsTableTable(attachedDatabase, alias);
  }
}

class AppSettingEntity extends DataClass
    implements Insertable<AppSettingEntity> {
  final String id;
  final String themeMode;
  final String syncFrequency;
  final bool autoSync;
  final int cacheLimitMB;
  final DateTime? lastCleanup;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AppSettingEntity(
      {required this.id,
      required this.themeMode,
      required this.syncFrequency,
      required this.autoSync,
      required this.cacheLimitMB,
      this.lastCleanup,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['theme_mode'] = Variable<String>(themeMode);
    map['sync_frequency'] = Variable<String>(syncFrequency);
    map['auto_sync'] = Variable<bool>(autoSync);
    map['cache_limit_m_b'] = Variable<int>(cacheLimitMB);
    if (!nullToAbsent || lastCleanup != null) {
      map['last_cleanup'] = Variable<DateTime>(lastCleanup);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(
      id: Value(id),
      themeMode: Value(themeMode),
      syncFrequency: Value(syncFrequency),
      autoSync: Value(autoSync),
      cacheLimitMB: Value(cacheLimitMB),
      lastCleanup: lastCleanup == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCleanup),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingEntity(
      id: serializer.fromJson<String>(json['id']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      syncFrequency: serializer.fromJson<String>(json['syncFrequency']),
      autoSync: serializer.fromJson<bool>(json['autoSync']),
      cacheLimitMB: serializer.fromJson<int>(json['cacheLimitMB']),
      lastCleanup: serializer.fromJson<DateTime?>(json['lastCleanup']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'themeMode': serializer.toJson<String>(themeMode),
      'syncFrequency': serializer.toJson<String>(syncFrequency),
      'autoSync': serializer.toJson<bool>(autoSync),
      'cacheLimitMB': serializer.toJson<int>(cacheLimitMB),
      'lastCleanup': serializer.toJson<DateTime?>(lastCleanup),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingEntity copyWith(
          {String? id,
          String? themeMode,
          String? syncFrequency,
          bool? autoSync,
          int? cacheLimitMB,
          Value<DateTime?> lastCleanup = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      AppSettingEntity(
        id: id ?? this.id,
        themeMode: themeMode ?? this.themeMode,
        syncFrequency: syncFrequency ?? this.syncFrequency,
        autoSync: autoSync ?? this.autoSync,
        cacheLimitMB: cacheLimitMB ?? this.cacheLimitMB,
        lastCleanup: lastCleanup.present ? lastCleanup.value : this.lastCleanup,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSettingEntity copyWithCompanion(AppSettingsTableCompanion data) {
    return AppSettingEntity(
      id: data.id.present ? data.id.value : this.id,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      syncFrequency: data.syncFrequency.present
          ? data.syncFrequency.value
          : this.syncFrequency,
      autoSync: data.autoSync.present ? data.autoSync.value : this.autoSync,
      cacheLimitMB: data.cacheLimitMB.present
          ? data.cacheLimitMB.value
          : this.cacheLimitMB,
      lastCleanup:
          data.lastCleanup.present ? data.lastCleanup.value : this.lastCleanup,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingEntity(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('syncFrequency: $syncFrequency, ')
          ..write('autoSync: $autoSync, ')
          ..write('cacheLimitMB: $cacheLimitMB, ')
          ..write('lastCleanup: $lastCleanup, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, themeMode, syncFrequency, autoSync,
      cacheLimitMB, lastCleanup, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingEntity &&
          other.id == this.id &&
          other.themeMode == this.themeMode &&
          other.syncFrequency == this.syncFrequency &&
          other.autoSync == this.autoSync &&
          other.cacheLimitMB == this.cacheLimitMB &&
          other.lastCleanup == this.lastCleanup &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsTableCompanion extends UpdateCompanion<AppSettingEntity> {
  final Value<String> id;
  final Value<String> themeMode;
  final Value<String> syncFrequency;
  final Value<bool> autoSync;
  final Value<int> cacheLimitMB;
  final Value<DateTime?> lastCleanup;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsTableCompanion({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.syncFrequency = const Value.absent(),
    this.autoSync = const Value.absent(),
    this.cacheLimitMB = const Value.absent(),
    this.lastCleanup = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    required String id,
    this.themeMode = const Value.absent(),
    this.syncFrequency = const Value.absent(),
    this.autoSync = const Value.absent(),
    this.cacheLimitMB = const Value.absent(),
    this.lastCleanup = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AppSettingEntity> custom({
    Expression<String>? id,
    Expression<String>? themeMode,
    Expression<String>? syncFrequency,
    Expression<bool>? autoSync,
    Expression<int>? cacheLimitMB,
    Expression<DateTime>? lastCleanup,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themeMode != null) 'theme_mode': themeMode,
      if (syncFrequency != null) 'sync_frequency': syncFrequency,
      if (autoSync != null) 'auto_sync': autoSync,
      if (cacheLimitMB != null) 'cache_limit_m_b': cacheLimitMB,
      if (lastCleanup != null) 'last_cleanup': lastCleanup,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? themeMode,
      Value<String>? syncFrequency,
      Value<bool>? autoSync,
      Value<int>? cacheLimitMB,
      Value<DateTime?>? lastCleanup,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AppSettingsTableCompanion(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      autoSync: autoSync ?? this.autoSync,
      cacheLimitMB: cacheLimitMB ?? this.cacheLimitMB,
      lastCleanup: lastCleanup ?? this.lastCleanup,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (syncFrequency.present) {
      map['sync_frequency'] = Variable<String>(syncFrequency.value);
    }
    if (autoSync.present) {
      map['auto_sync'] = Variable<bool>(autoSync.value);
    }
    if (cacheLimitMB.present) {
      map['cache_limit_m_b'] = Variable<int>(cacheLimitMB.value);
    }
    if (lastCleanup.present) {
      map['last_cleanup'] = Variable<DateTime>(lastCleanup.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('syncFrequency: $syncFrequency, ')
          ..write('autoSync: $autoSync, ')
          ..write('cacheLimitMB: $cacheLimitMB, ')
          ..write('lastCleanup: $lastCleanup, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PagesTable pages = $PagesTable(this);
  late final $BlocksTable blocks = $BlocksTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $HistoryPagesTable historyPages = $HistoryPagesTable(this);
  late final $PageCollectionsTable pageCollections =
      $PageCollectionsTable(this);
  late final $PageTagsTable pageTags = $PageTagsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  late final $AppSettingsTableTable appSettingsTable =
      $AppSettingsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        pages,
        blocks,
        attachments,
        reminders,
        collections,
        tags,
        historyPages,
        pageCollections,
        pageTags,
        syncQueue,
        syncStates,
        appSettingsTable
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('pages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('pages', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('pages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('blocks', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('blocks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('blocks', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('pages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('reminders', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('blocks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('reminders', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('pages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('history_pages', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('pages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('page_collections', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('collections',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('page_collections', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('pages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('page_tags', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('tags',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('page_tags', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$PagesTableCreateCompanionBuilder = PagesCompanion Function({
  required String id,
  Value<String?> parentPageId,
  Value<String> title,
  Value<String?> icon,
  Value<String?> coverImage,
  Value<bool> isFavorite,
  Value<bool> isArchived,
  Value<bool> deleted,
  Value<bool> isTemplate,
  Value<int> version,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PagesTableUpdateCompanionBuilder = PagesCompanion Function({
  Value<String> id,
  Value<String?> parentPageId,
  Value<String> title,
  Value<String?> icon,
  Value<String?> coverImage,
  Value<bool> isFavorite,
  Value<bool> isArchived,
  Value<bool> deleted,
  Value<bool> isTemplate,
  Value<int> version,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$PagesTableReferences
    extends BaseReferences<_$AppDatabase, $PagesTable, Page> {
  $$PagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PagesTable _parentPageIdTable(_$AppDatabase db) => db.pages
      .createAlias($_aliasNameGenerator(db.pages.parentPageId, db.pages.id));

  $$PagesTableProcessedTableManager? get parentPageId {
    if ($_item.parentPageId == null) return null;
    final manager = $$PagesTableTableManager($_db, $_db.pages)
        .filter((f) => f.id($_item.parentPageId!));
    final item = $_typedResult.readTableOrNull(_parentPageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$BlocksTable, List<Block>> _blocksRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.blocks,
          aliasName: $_aliasNameGenerator(db.pages.id, db.blocks.pageId));

  $$BlocksTableProcessedTableManager get blocksRefs {
    final manager = $$BlocksTableTableManager($_db, $_db.blocks)
        .filter((f) => f.pageId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_blocksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RemindersTable, List<Reminder>>
      _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.reminders,
          aliasName: $_aliasNameGenerator(db.pages.id, db.reminders.pageId));

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager($_db, $_db.reminders)
        .filter((f) => f.pageId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$HistoryPagesTable, List<HistoryPage>>
      _historyPagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.historyPages,
          aliasName: $_aliasNameGenerator(db.pages.id, db.historyPages.pageId));

  $$HistoryPagesTableProcessedTableManager get historyPagesRefs {
    final manager = $$HistoryPagesTableTableManager($_db, $_db.historyPages)
        .filter((f) => f.pageId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_historyPagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PageCollectionsTable, List<PageCollection>>
      _pageCollectionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.pageCollections,
              aliasName:
                  $_aliasNameGenerator(db.pages.id, db.pageCollections.pageId));

  $$PageCollectionsTableProcessedTableManager get pageCollectionsRefs {
    final manager =
        $$PageCollectionsTableTableManager($_db, $_db.pageCollections)
            .filter((f) => f.pageId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_pageCollectionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PageTagsTable, List<PageTag>> _pageTagsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.pageTags,
          aliasName: $_aliasNameGenerator(db.pages.id, db.pageTags.pageId));

  $$PageTagsTableProcessedTableManager get pageTagsRefs {
    final manager = $$PageTagsTableTableManager($_db, $_db.pageTags)
        .filter((f) => f.pageId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_pageTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PagesTableFilterComposer extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverImage => $composableBuilder(
      column: $table.coverImage, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isTemplate => $composableBuilder(
      column: $table.isTemplate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$PagesTableFilterComposer get parentPageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentPageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableFilterComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> blocksRefs(
      Expression<bool> Function($$BlocksTableFilterComposer f) f) {
    final $$BlocksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.blocks,
        getReferencedColumn: (t) => t.pageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlocksTableFilterComposer(
              $db: $db,
              $table: $db.blocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> remindersRefs(
      Expression<bool> Function($$RemindersTableFilterComposer f) f) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.pageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableFilterComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> historyPagesRefs(
      Expression<bool> Function($$HistoryPagesTableFilterComposer f) f) {
    final $$HistoryPagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.historyPages,
        getReferencedColumn: (t) => t.pageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HistoryPagesTableFilterComposer(
              $db: $db,
              $table: $db.historyPages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> pageCollectionsRefs(
      Expression<bool> Function($$PageCollectionsTableFilterComposer f) f) {
    final $$PageCollectionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pageCollections,
        getReferencedColumn: (t) => t.pageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PageCollectionsTableFilterComposer(
              $db: $db,
              $table: $db.pageCollections,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> pageTagsRefs(
      Expression<bool> Function($$PageTagsTableFilterComposer f) f) {
    final $$PageTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pageTags,
        getReferencedColumn: (t) => t.pageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PageTagsTableFilterComposer(
              $db: $db,
              $table: $db.pageTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverImage => $composableBuilder(
      column: $table.coverImage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTemplate => $composableBuilder(
      column: $table.isTemplate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$PagesTableOrderingComposer get parentPageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentPageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableOrderingComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get coverImage => $composableBuilder(
      column: $table.coverImage, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get isTemplate => $composableBuilder(
      column: $table.isTemplate, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PagesTableAnnotationComposer get parentPageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentPageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableAnnotationComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> blocksRefs<T extends Object>(
      Expression<T> Function($$BlocksTableAnnotationComposer a) f) {
    final $$BlocksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.blocks,
        getReferencedColumn: (t) => t.pageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlocksTableAnnotationComposer(
              $db: $db,
              $table: $db.blocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> remindersRefs<T extends Object>(
      Expression<T> Function($$RemindersTableAnnotationComposer a) f) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.pageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableAnnotationComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> historyPagesRefs<T extends Object>(
      Expression<T> Function($$HistoryPagesTableAnnotationComposer a) f) {
    final $$HistoryPagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.historyPages,
        getReferencedColumn: (t) => t.pageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HistoryPagesTableAnnotationComposer(
              $db: $db,
              $table: $db.historyPages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> pageCollectionsRefs<T extends Object>(
      Expression<T> Function($$PageCollectionsTableAnnotationComposer a) f) {
    final $$PageCollectionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pageCollections,
        getReferencedColumn: (t) => t.pageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PageCollectionsTableAnnotationComposer(
              $db: $db,
              $table: $db.pageCollections,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> pageTagsRefs<T extends Object>(
      Expression<T> Function($$PageTagsTableAnnotationComposer a) f) {
    final $$PageTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pageTags,
        getReferencedColumn: (t) => t.pageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PageTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.pageTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PagesTable,
    Page,
    $$PagesTableFilterComposer,
    $$PagesTableOrderingComposer,
    $$PagesTableAnnotationComposer,
    $$PagesTableCreateCompanionBuilder,
    $$PagesTableUpdateCompanionBuilder,
    (Page, $$PagesTableReferences),
    Page,
    PrefetchHooks Function(
        {bool parentPageId,
        bool blocksRefs,
        bool remindersRefs,
        bool historyPagesRefs,
        bool pageCollectionsRefs,
        bool pageTagsRefs})> {
  $$PagesTableTableManager(_$AppDatabase db, $PagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> parentPageId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String?> coverImage = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> isTemplate = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PagesCompanion(
            id: id,
            parentPageId: parentPageId,
            title: title,
            icon: icon,
            coverImage: coverImage,
            isFavorite: isFavorite,
            isArchived: isArchived,
            deleted: deleted,
            isTemplate: isTemplate,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> parentPageId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String?> coverImage = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> isTemplate = const Value.absent(),
            Value<int> version = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PagesCompanion.insert(
            id: id,
            parentPageId: parentPageId,
            title: title,
            icon: icon,
            coverImage: coverImage,
            isFavorite: isFavorite,
            isArchived: isArchived,
            deleted: deleted,
            isTemplate: isTemplate,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PagesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {parentPageId = false,
              blocksRefs = false,
              remindersRefs = false,
              historyPagesRefs = false,
              pageCollectionsRefs = false,
              pageTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (blocksRefs) db.blocks,
                if (remindersRefs) db.reminders,
                if (historyPagesRefs) db.historyPages,
                if (pageCollectionsRefs) db.pageCollections,
                if (pageTagsRefs) db.pageTags
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (parentPageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.parentPageId,
                    referencedTable:
                        $$PagesTableReferences._parentPageIdTable(db),
                    referencedColumn:
                        $$PagesTableReferences._parentPageIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (blocksRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$PagesTableReferences._blocksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PagesTableReferences(db, table, p0).blocksRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.pageId == item.id),
                        typedResults: items),
                  if (remindersRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$PagesTableReferences._remindersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PagesTableReferences(db, table, p0).remindersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.pageId == item.id),
                        typedResults: items),
                  if (historyPagesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$PagesTableReferences._historyPagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PagesTableReferences(db, table, p0)
                                .historyPagesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.pageId == item.id),
                        typedResults: items),
                  if (pageCollectionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$PagesTableReferences
                            ._pageCollectionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PagesTableReferences(db, table, p0)
                                .pageCollectionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.pageId == item.id),
                        typedResults: items),
                  if (pageTagsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$PagesTableReferences._pageTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PagesTableReferences(db, table, p0).pageTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.pageId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PagesTable,
    Page,
    $$PagesTableFilterComposer,
    $$PagesTableOrderingComposer,
    $$PagesTableAnnotationComposer,
    $$PagesTableCreateCompanionBuilder,
    $$PagesTableUpdateCompanionBuilder,
    (Page, $$PagesTableReferences),
    Page,
    PrefetchHooks Function(
        {bool parentPageId,
        bool blocksRefs,
        bool remindersRefs,
        bool historyPagesRefs,
        bool pageCollectionsRefs,
        bool pageTagsRefs})>;
typedef $$BlocksTableCreateCompanionBuilder = BlocksCompanion Function({
  required String id,
  required String pageId,
  Value<String?> parentBlockId,
  required String type,
  required double position,
  required String data,
  Value<int> version,
  Value<bool> deleted,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BlocksTableUpdateCompanionBuilder = BlocksCompanion Function({
  Value<String> id,
  Value<String> pageId,
  Value<String?> parentBlockId,
  Value<String> type,
  Value<double> position,
  Value<String> data,
  Value<int> version,
  Value<bool> deleted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$BlocksTableReferences
    extends BaseReferences<_$AppDatabase, $BlocksTable, Block> {
  $$BlocksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PagesTable _pageIdTable(_$AppDatabase db) =>
      db.pages.createAlias($_aliasNameGenerator(db.blocks.pageId, db.pages.id));

  $$PagesTableProcessedTableManager? get pageId {
    if ($_item.pageId == null) return null;
    final manager = $$PagesTableTableManager($_db, $_db.pages)
        .filter((f) => f.id($_item.pageId!));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BlocksTable _parentBlockIdTable(_$AppDatabase db) => db.blocks
      .createAlias($_aliasNameGenerator(db.blocks.parentBlockId, db.blocks.id));

  $$BlocksTableProcessedTableManager? get parentBlockId {
    if ($_item.parentBlockId == null) return null;
    final manager = $$BlocksTableTableManager($_db, $_db.blocks)
        .filter((f) => f.id($_item.parentBlockId!));
    final item = $_typedResult.readTableOrNull(_parentBlockIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RemindersTable, List<Reminder>>
      _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.reminders,
          aliasName: $_aliasNameGenerator(db.blocks.id, db.reminders.blockId));

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager($_db, $_db.reminders)
        .filter((f) => f.blockId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BlocksTableFilterComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableFilterComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BlocksTableFilterComposer get parentBlockId {
    final $$BlocksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentBlockId,
        referencedTable: $db.blocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlocksTableFilterComposer(
              $db: $db,
              $table: $db.blocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> remindersRefs(
      Expression<bool> Function($$RemindersTableFilterComposer f) f) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.blockId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableFilterComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableOrderingComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BlocksTableOrderingComposer get parentBlockId {
    final $$BlocksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentBlockId,
        referencedTable: $db.blocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlocksTableOrderingComposer(
              $db: $db,
              $table: $db.blocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableAnnotationComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BlocksTableAnnotationComposer get parentBlockId {
    final $$BlocksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentBlockId,
        referencedTable: $db.blocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlocksTableAnnotationComposer(
              $db: $db,
              $table: $db.blocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> remindersRefs<T extends Object>(
      Expression<T> Function($$RemindersTableAnnotationComposer a) f) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.blockId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableAnnotationComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BlocksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BlocksTable,
    Block,
    $$BlocksTableFilterComposer,
    $$BlocksTableOrderingComposer,
    $$BlocksTableAnnotationComposer,
    $$BlocksTableCreateCompanionBuilder,
    $$BlocksTableUpdateCompanionBuilder,
    (Block, $$BlocksTableReferences),
    Block,
    PrefetchHooks Function(
        {bool pageId, bool parentBlockId, bool remindersRefs})> {
  $$BlocksTableTableManager(_$AppDatabase db, $BlocksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> pageId = const Value.absent(),
            Value<String?> parentBlockId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> position = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BlocksCompanion(
            id: id,
            pageId: pageId,
            parentBlockId: parentBlockId,
            type: type,
            position: position,
            data: data,
            version: version,
            deleted: deleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String pageId,
            Value<String?> parentBlockId = const Value.absent(),
            required String type,
            required double position,
            required String data,
            Value<int> version = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BlocksCompanion.insert(
            id: id,
            pageId: pageId,
            parentBlockId: parentBlockId,
            type: type,
            position: position,
            data: data,
            version: version,
            deleted: deleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BlocksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {pageId = false, parentBlockId = false, remindersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (remindersRefs) db.reminders],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (pageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.pageId,
                    referencedTable: $$BlocksTableReferences._pageIdTable(db),
                    referencedColumn:
                        $$BlocksTableReferences._pageIdTable(db).id,
                  ) as T;
                }
                if (parentBlockId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.parentBlockId,
                    referencedTable:
                        $$BlocksTableReferences._parentBlockIdTable(db),
                    referencedColumn:
                        $$BlocksTableReferences._parentBlockIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (remindersRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$BlocksTableReferences._remindersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BlocksTableReferences(db, table, p0)
                                .remindersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.blockId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BlocksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BlocksTable,
    Block,
    $$BlocksTableFilterComposer,
    $$BlocksTableOrderingComposer,
    $$BlocksTableAnnotationComposer,
    $$BlocksTableCreateCompanionBuilder,
    $$BlocksTableUpdateCompanionBuilder,
    (Block, $$BlocksTableReferences),
    Block,
    PrefetchHooks Function(
        {bool pageId, bool parentBlockId, bool remindersRefs})>;
typedef $$AttachmentsTableCreateCompanionBuilder = AttachmentsCompanion
    Function({
  required String id,
  required String pageId,
  required String blockId,
  required String fileName,
  required String mimeType,
  required int size,
  required String sha256,
  required String relativePath,
  Value<String?> thumbnailPath,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$AttachmentsTableUpdateCompanionBuilder = AttachmentsCompanion
    Function({
  Value<String> id,
  Value<String> pageId,
  Value<String> blockId,
  Value<String> fileName,
  Value<String> mimeType,
  Value<int> size,
  Value<String> sha256,
  Value<String> relativePath,
  Value<String?> thumbnailPath,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get blockId => $composableBuilder(
      column: $table.blockId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get blockId => $composableBuilder(
      column: $table.blockId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relativePath => $composableBuilder(
      column: $table.relativePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get blockId =>
      $composableBuilder(column: $table.blockId, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$AttachmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttachmentsTable,
    AttachmentData,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableAnnotationComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder,
    (
      AttachmentData,
      BaseReferences<_$AppDatabase, $AttachmentsTable, AttachmentData>
    ),
    AttachmentData,
    PrefetchHooks Function()> {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> pageId = const Value.absent(),
            Value<String> blockId = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<int> size = const Value.absent(),
            Value<String> sha256 = const Value.absent(),
            Value<String> relativePath = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion(
            id: id,
            pageId: pageId,
            blockId: blockId,
            fileName: fileName,
            mimeType: mimeType,
            size: size,
            sha256: sha256,
            relativePath: relativePath,
            thumbnailPath: thumbnailPath,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deleted: deleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String pageId,
            required String blockId,
            required String fileName,
            required String mimeType,
            required int size,
            required String sha256,
            required String relativePath,
            Value<String?> thumbnailPath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion.insert(
            id: id,
            pageId: pageId,
            blockId: blockId,
            fileName: fileName,
            mimeType: mimeType,
            size: size,
            sha256: sha256,
            relativePath: relativePath,
            thumbnailPath: thumbnailPath,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deleted: deleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttachmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttachmentsTable,
    AttachmentData,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableAnnotationComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder,
    (
      AttachmentData,
      BaseReferences<_$AppDatabase, $AttachmentsTable, AttachmentData>
    ),
    AttachmentData,
    PrefetchHooks Function()>;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  required String pageId,
  Value<String?> blockId,
  Value<String> title,
  required DateTime reminderTime,
  Value<String> timezone,
  Value<String?> recurrenceRule,
  Value<DateTime?> snoozeUntil,
  Value<bool> completed,
  Value<int> version,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<String> pageId,
  Value<String?> blockId,
  Value<String> title,
  Value<DateTime> reminderTime,
  Value<String> timezone,
  Value<String?> recurrenceRule,
  Value<DateTime?> snoozeUntil,
  Value<bool> completed,
  Value<int> version,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PagesTable _pageIdTable(_$AppDatabase db) => db.pages
      .createAlias($_aliasNameGenerator(db.reminders.pageId, db.pages.id));

  $$PagesTableProcessedTableManager? get pageId {
    if ($_item.pageId == null) return null;
    final manager = $$PagesTableTableManager($_db, $_db.pages)
        .filter((f) => f.id($_item.pageId!));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BlocksTable _blockIdTable(_$AppDatabase db) => db.blocks
      .createAlias($_aliasNameGenerator(db.reminders.blockId, db.blocks.id));

  $$BlocksTableProcessedTableManager? get blockId {
    if ($_item.blockId == null) return null;
    final manager = $$BlocksTableTableManager($_db, $_db.blocks)
        .filter((f) => f.id($_item.blockId!));
    final item = $_typedResult.readTableOrNull(_blockIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reminderTime => $composableBuilder(
      column: $table.reminderTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timezone => $composableBuilder(
      column: $table.timezone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
      column: $table.recurrenceRule,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get snoozeUntil => $composableBuilder(
      column: $table.snoozeUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableFilterComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BlocksTableFilterComposer get blockId {
    final $$BlocksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blockId,
        referencedTable: $db.blocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlocksTableFilterComposer(
              $db: $db,
              $table: $db.blocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reminderTime => $composableBuilder(
      column: $table.reminderTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timezone => $composableBuilder(
      column: $table.timezone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
      column: $table.recurrenceRule,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get snoozeUntil => $composableBuilder(
      column: $table.snoozeUntil, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableOrderingComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BlocksTableOrderingComposer get blockId {
    final $$BlocksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blockId,
        referencedTable: $db.blocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlocksTableOrderingComposer(
              $db: $db,
              $table: $db.blocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get reminderTime => $composableBuilder(
      column: $table.reminderTime, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
      column: $table.recurrenceRule, builder: (column) => column);

  GeneratedColumn<DateTime> get snoozeUntil => $composableBuilder(
      column: $table.snoozeUntil, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableAnnotationComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BlocksTableAnnotationComposer get blockId {
    final $$BlocksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.blockId,
        referencedTable: $db.blocks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlocksTableAnnotationComposer(
              $db: $db,
              $table: $db.blocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RemindersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RemindersTable,
    Reminder,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (Reminder, $$RemindersTableReferences),
    Reminder,
    PrefetchHooks Function({bool pageId, bool blockId})> {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> pageId = const Value.absent(),
            Value<String?> blockId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<DateTime> reminderTime = const Value.absent(),
            Value<String> timezone = const Value.absent(),
            Value<String?> recurrenceRule = const Value.absent(),
            Value<DateTime?> snoozeUntil = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion(
            id: id,
            pageId: pageId,
            blockId: blockId,
            title: title,
            reminderTime: reminderTime,
            timezone: timezone,
            recurrenceRule: recurrenceRule,
            snoozeUntil: snoozeUntil,
            completed: completed,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deleted: deleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String pageId,
            Value<String?> blockId = const Value.absent(),
            Value<String> title = const Value.absent(),
            required DateTime reminderTime,
            Value<String> timezone = const Value.absent(),
            Value<String?> recurrenceRule = const Value.absent(),
            Value<DateTime?> snoozeUntil = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion.insert(
            id: id,
            pageId: pageId,
            blockId: blockId,
            title: title,
            reminderTime: reminderTime,
            timezone: timezone,
            recurrenceRule: recurrenceRule,
            snoozeUntil: snoozeUntil,
            completed: completed,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deleted: deleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RemindersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({pageId = false, blockId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (pageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.pageId,
                    referencedTable:
                        $$RemindersTableReferences._pageIdTable(db),
                    referencedColumn:
                        $$RemindersTableReferences._pageIdTable(db).id,
                  ) as T;
                }
                if (blockId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.blockId,
                    referencedTable:
                        $$RemindersTableReferences._blockIdTable(db),
                    referencedColumn:
                        $$RemindersTableReferences._blockIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RemindersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RemindersTable,
    Reminder,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (Reminder, $$RemindersTableReferences),
    Reminder,
    PrefetchHooks Function({bool pageId, bool blockId})>;
typedef $$CollectionsTableCreateCompanionBuilder = CollectionsCompanion
    Function({
  required String id,
  required String name,
  Value<String?> icon,
  Value<String?> color,
  Value<int> version,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$CollectionsTableUpdateCompanionBuilder = CollectionsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> icon,
  Value<String?> color,
  Value<int> version,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});

final class $$CollectionsTableReferences
    extends BaseReferences<_$AppDatabase, $CollectionsTable, Collection> {
  $$CollectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PageCollectionsTable, List<PageCollection>>
      _pageCollectionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.pageCollections,
              aliasName: $_aliasNameGenerator(
                  db.collections.id, db.pageCollections.collectionId));

  $$PageCollectionsTableProcessedTableManager get pageCollectionsRefs {
    final manager =
        $$PageCollectionsTableTableManager($_db, $_db.pageCollections)
            .filter((f) => f.collectionId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_pageCollectionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  Expression<bool> pageCollectionsRefs(
      Expression<bool> Function($$PageCollectionsTableFilterComposer f) f) {
    final $$PageCollectionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pageCollections,
        getReferencedColumn: (t) => t.collectionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PageCollectionsTableFilterComposer(
              $db: $db,
              $table: $db.pageCollections,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  Expression<T> pageCollectionsRefs<T extends Object>(
      Expression<T> Function($$PageCollectionsTableAnnotationComposer a) f) {
    final $$PageCollectionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pageCollections,
        getReferencedColumn: (t) => t.collectionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PageCollectionsTableAnnotationComposer(
              $db: $db,
              $table: $db.pageCollections,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CollectionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CollectionsTable,
    Collection,
    $$CollectionsTableFilterComposer,
    $$CollectionsTableOrderingComposer,
    $$CollectionsTableAnnotationComposer,
    $$CollectionsTableCreateCompanionBuilder,
    $$CollectionsTableUpdateCompanionBuilder,
    (Collection, $$CollectionsTableReferences),
    Collection,
    PrefetchHooks Function({bool pageCollectionsRefs})> {
  $$CollectionsTableTableManager(_$AppDatabase db, $CollectionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CollectionsCompanion(
            id: id,
            name: name,
            icon: icon,
            color: color,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deleted: deleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> icon = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CollectionsCompanion.insert(
            id: id,
            name: name,
            icon: icon,
            color: color,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deleted: deleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CollectionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({pageCollectionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (pageCollectionsRefs) db.pageCollections
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pageCollectionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$CollectionsTableReferences
                            ._pageCollectionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CollectionsTableReferences(db, table, p0)
                                .pageCollectionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.collectionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CollectionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CollectionsTable,
    Collection,
    $$CollectionsTableFilterComposer,
    $$CollectionsTableOrderingComposer,
    $$CollectionsTableAnnotationComposer,
    $$CollectionsTableCreateCompanionBuilder,
    $$CollectionsTableUpdateCompanionBuilder,
    (Collection, $$CollectionsTableReferences),
    Collection,
    PrefetchHooks Function({bool pageCollectionsRefs})>;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required String name,
  Value<String?> color,
  Value<int> version,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> color,
  Value<int> version,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PageTagsTable, List<PageTag>> _pageTagsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.pageTags,
          aliasName: $_aliasNameGenerator(db.tags.id, db.pageTags.tagId));

  $$PageTagsTableProcessedTableManager get pageTagsRefs {
    final manager = $$PageTagsTableTableManager($_db, $_db.pageTags)
        .filter((f) => f.tagId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_pageTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  Expression<bool> pageTagsRefs(
      Expression<bool> Function($$PageTagsTableFilterComposer f) f) {
    final $$PageTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pageTags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PageTagsTableFilterComposer(
              $db: $db,
              $table: $db.pageTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  Expression<T> pageTagsRefs<T extends Object>(
      Expression<T> Function($$PageTagsTableAnnotationComposer a) f) {
    final $$PageTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pageTags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PageTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.pageTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (Tag, $$TagsTableReferences),
    Tag,
    PrefetchHooks Function({bool pageTagsRefs})> {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TagsCompanion(
            id: id,
            name: name,
            color: color,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deleted: deleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> color = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TagsCompanion.insert(
            id: id,
            name: name,
            color: color,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deleted: deleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TagsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({pageTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (pageTagsRefs) db.pageTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pageTagsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$TagsTableReferences._pageTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TagsTableReferences(db, table, p0).pageTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tagId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (Tag, $$TagsTableReferences),
    Tag,
    PrefetchHooks Function({bool pageTagsRefs})>;
typedef $$HistoryPagesTableCreateCompanionBuilder = HistoryPagesCompanion
    Function({
  required String id,
  required String pageId,
  required int snapshotVersion,
  required Uint8List compressedSnapshot,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$HistoryPagesTableUpdateCompanionBuilder = HistoryPagesCompanion
    Function({
  Value<String> id,
  Value<String> pageId,
  Value<int> snapshotVersion,
  Value<Uint8List> compressedSnapshot,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$HistoryPagesTableReferences
    extends BaseReferences<_$AppDatabase, $HistoryPagesTable, HistoryPage> {
  $$HistoryPagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PagesTable _pageIdTable(_$AppDatabase db) => db.pages
      .createAlias($_aliasNameGenerator(db.historyPages.pageId, db.pages.id));

  $$PagesTableProcessedTableManager? get pageId {
    if ($_item.pageId == null) return null;
    final manager = $$PagesTableTableManager($_db, $_db.pages)
        .filter((f) => f.id($_item.pageId!));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HistoryPagesTableFilterComposer
    extends Composer<_$AppDatabase, $HistoryPagesTable> {
  $$HistoryPagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get snapshotVersion => $composableBuilder(
      column: $table.snapshotVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get compressedSnapshot => $composableBuilder(
      column: $table.compressedSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableFilterComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HistoryPagesTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoryPagesTable> {
  $$HistoryPagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get snapshotVersion => $composableBuilder(
      column: $table.snapshotVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get compressedSnapshot => $composableBuilder(
      column: $table.compressedSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableOrderingComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HistoryPagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoryPagesTable> {
  $$HistoryPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get snapshotVersion => $composableBuilder(
      column: $table.snapshotVersion, builder: (column) => column);

  GeneratedColumn<Uint8List> get compressedSnapshot => $composableBuilder(
      column: $table.compressedSnapshot, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableAnnotationComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HistoryPagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HistoryPagesTable,
    HistoryPage,
    $$HistoryPagesTableFilterComposer,
    $$HistoryPagesTableOrderingComposer,
    $$HistoryPagesTableAnnotationComposer,
    $$HistoryPagesTableCreateCompanionBuilder,
    $$HistoryPagesTableUpdateCompanionBuilder,
    (HistoryPage, $$HistoryPagesTableReferences),
    HistoryPage,
    PrefetchHooks Function({bool pageId})> {
  $$HistoryPagesTableTableManager(_$AppDatabase db, $HistoryPagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> pageId = const Value.absent(),
            Value<int> snapshotVersion = const Value.absent(),
            Value<Uint8List> compressedSnapshot = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HistoryPagesCompanion(
            id: id,
            pageId: pageId,
            snapshotVersion: snapshotVersion,
            compressedSnapshot: compressedSnapshot,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String pageId,
            required int snapshotVersion,
            required Uint8List compressedSnapshot,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              HistoryPagesCompanion.insert(
            id: id,
            pageId: pageId,
            snapshotVersion: snapshotVersion,
            compressedSnapshot: compressedSnapshot,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$HistoryPagesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({pageId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (pageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.pageId,
                    referencedTable:
                        $$HistoryPagesTableReferences._pageIdTable(db),
                    referencedColumn:
                        $$HistoryPagesTableReferences._pageIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$HistoryPagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HistoryPagesTable,
    HistoryPage,
    $$HistoryPagesTableFilterComposer,
    $$HistoryPagesTableOrderingComposer,
    $$HistoryPagesTableAnnotationComposer,
    $$HistoryPagesTableCreateCompanionBuilder,
    $$HistoryPagesTableUpdateCompanionBuilder,
    (HistoryPage, $$HistoryPagesTableReferences),
    HistoryPage,
    PrefetchHooks Function({bool pageId})>;
typedef $$PageCollectionsTableCreateCompanionBuilder = PageCollectionsCompanion
    Function({
  required String pageId,
  required String collectionId,
  Value<int> rowid,
});
typedef $$PageCollectionsTableUpdateCompanionBuilder = PageCollectionsCompanion
    Function({
  Value<String> pageId,
  Value<String> collectionId,
  Value<int> rowid,
});

final class $$PageCollectionsTableReferences extends BaseReferences<
    _$AppDatabase, $PageCollectionsTable, PageCollection> {
  $$PageCollectionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PagesTable _pageIdTable(_$AppDatabase db) => db.pages.createAlias(
      $_aliasNameGenerator(db.pageCollections.pageId, db.pages.id));

  $$PagesTableProcessedTableManager? get pageId {
    if ($_item.pageId == null) return null;
    final manager = $$PagesTableTableManager($_db, $_db.pages)
        .filter((f) => f.id($_item.pageId!));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CollectionsTable _collectionIdTable(_$AppDatabase db) =>
      db.collections.createAlias($_aliasNameGenerator(
          db.pageCollections.collectionId, db.collections.id));

  $$CollectionsTableProcessedTableManager? get collectionId {
    if ($_item.collectionId == null) return null;
    final manager = $$CollectionsTableTableManager($_db, $_db.collections)
        .filter((f) => f.id($_item.collectionId!));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PageCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $PageCollectionsTable> {
  $$PageCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableFilterComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CollectionsTableFilterComposer get collectionId {
    final $$CollectionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.collectionId,
        referencedTable: $db.collections,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CollectionsTableFilterComposer(
              $db: $db,
              $table: $db.collections,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PageCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PageCollectionsTable> {
  $$PageCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableOrderingComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CollectionsTableOrderingComposer get collectionId {
    final $$CollectionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.collectionId,
        referencedTable: $db.collections,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CollectionsTableOrderingComposer(
              $db: $db,
              $table: $db.collections,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PageCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PageCollectionsTable> {
  $$PageCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableAnnotationComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CollectionsTableAnnotationComposer get collectionId {
    final $$CollectionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.collectionId,
        referencedTable: $db.collections,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CollectionsTableAnnotationComposer(
              $db: $db,
              $table: $db.collections,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PageCollectionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PageCollectionsTable,
    PageCollection,
    $$PageCollectionsTableFilterComposer,
    $$PageCollectionsTableOrderingComposer,
    $$PageCollectionsTableAnnotationComposer,
    $$PageCollectionsTableCreateCompanionBuilder,
    $$PageCollectionsTableUpdateCompanionBuilder,
    (PageCollection, $$PageCollectionsTableReferences),
    PageCollection,
    PrefetchHooks Function({bool pageId, bool collectionId})> {
  $$PageCollectionsTableTableManager(
      _$AppDatabase db, $PageCollectionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PageCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PageCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PageCollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> pageId = const Value.absent(),
            Value<String> collectionId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PageCollectionsCompanion(
            pageId: pageId,
            collectionId: collectionId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String pageId,
            required String collectionId,
            Value<int> rowid = const Value.absent(),
          }) =>
              PageCollectionsCompanion.insert(
            pageId: pageId,
            collectionId: collectionId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PageCollectionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({pageId = false, collectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (pageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.pageId,
                    referencedTable:
                        $$PageCollectionsTableReferences._pageIdTable(db),
                    referencedColumn:
                        $$PageCollectionsTableReferences._pageIdTable(db).id,
                  ) as T;
                }
                if (collectionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.collectionId,
                    referencedTable:
                        $$PageCollectionsTableReferences._collectionIdTable(db),
                    referencedColumn: $$PageCollectionsTableReferences
                        ._collectionIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PageCollectionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PageCollectionsTable,
    PageCollection,
    $$PageCollectionsTableFilterComposer,
    $$PageCollectionsTableOrderingComposer,
    $$PageCollectionsTableAnnotationComposer,
    $$PageCollectionsTableCreateCompanionBuilder,
    $$PageCollectionsTableUpdateCompanionBuilder,
    (PageCollection, $$PageCollectionsTableReferences),
    PageCollection,
    PrefetchHooks Function({bool pageId, bool collectionId})>;
typedef $$PageTagsTableCreateCompanionBuilder = PageTagsCompanion Function({
  required String pageId,
  required String tagId,
  Value<int> rowid,
});
typedef $$PageTagsTableUpdateCompanionBuilder = PageTagsCompanion Function({
  Value<String> pageId,
  Value<String> tagId,
  Value<int> rowid,
});

final class $$PageTagsTableReferences
    extends BaseReferences<_$AppDatabase, $PageTagsTable, PageTag> {
  $$PageTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PagesTable _pageIdTable(_$AppDatabase db) => db.pages
      .createAlias($_aliasNameGenerator(db.pageTags.pageId, db.pages.id));

  $$PagesTableProcessedTableManager? get pageId {
    if ($_item.pageId == null) return null;
    final manager = $$PagesTableTableManager($_db, $_db.pages)
        .filter((f) => f.id($_item.pageId!));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias($_aliasNameGenerator(db.pageTags.tagId, db.tags.id));

  $$TagsTableProcessedTableManager? get tagId {
    if ($_item.tagId == null) return null;
    final manager = $$TagsTableTableManager($_db, $_db.tags)
        .filter((f) => f.id($_item.tagId!));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PageTagsTableFilterComposer
    extends Composer<_$AppDatabase, $PageTagsTable> {
  $$PageTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableFilterComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableFilterComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PageTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $PageTagsTable> {
  $$PageTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableOrderingComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableOrderingComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PageTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PageTagsTable> {
  $$PageTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pageId,
        referencedTable: $db.pages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PagesTableAnnotationComposer(
              $db: $db,
              $table: $db.pages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableAnnotationComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PageTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PageTagsTable,
    PageTag,
    $$PageTagsTableFilterComposer,
    $$PageTagsTableOrderingComposer,
    $$PageTagsTableAnnotationComposer,
    $$PageTagsTableCreateCompanionBuilder,
    $$PageTagsTableUpdateCompanionBuilder,
    (PageTag, $$PageTagsTableReferences),
    PageTag,
    PrefetchHooks Function({bool pageId, bool tagId})> {
  $$PageTagsTableTableManager(_$AppDatabase db, $PageTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PageTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PageTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PageTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> pageId = const Value.absent(),
            Value<String> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PageTagsCompanion(
            pageId: pageId,
            tagId: tagId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String pageId,
            required String tagId,
            Value<int> rowid = const Value.absent(),
          }) =>
              PageTagsCompanion.insert(
            pageId: pageId,
            tagId: tagId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PageTagsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({pageId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (pageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.pageId,
                    referencedTable: $$PageTagsTableReferences._pageIdTable(db),
                    referencedColumn:
                        $$PageTagsTableReferences._pageIdTable(db).id,
                  ) as T;
                }
                if (tagId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tagId,
                    referencedTable: $$PageTagsTableReferences._tagIdTable(db),
                    referencedColumn:
                        $$PageTagsTableReferences._tagIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PageTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PageTagsTable,
    PageTag,
    $$PageTagsTableFilterComposer,
    $$PageTagsTableOrderingComposer,
    $$PageTagsTableAnnotationComposer,
    $$PageTagsTableCreateCompanionBuilder,
    $$PageTagsTableUpdateCompanionBuilder,
    (PageTag, $$PageTagsTableReferences),
    PageTag,
    PrefetchHooks Function({bool pageId, bool tagId})>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String id,
  required String entityTable,
  required String entityId,
  required String operation,
  Value<String?> payload,
  Value<DateTime> createdAt,
  Value<String> status,
  Value<int> attemptCount,
  Value<DateTime?> lastAttemptAt,
  Value<DateTime?> nextRetryAt,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> id,
  Value<String> entityTable,
  Value<String> entityId,
  Value<String> operation,
  Value<String?> payload,
  Value<DateTime> createdAt,
  Value<String> status,
  Value<int> attemptCount,
  Value<DateTime?> lastAttemptAt,
  Value<DateTime?> nextRetryAt,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> entityTable = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String?> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            entityTable: entityTable,
            entityId: entityId,
            operation: operation,
            payload: payload,
            createdAt: createdAt,
            status: status,
            attemptCount: attemptCount,
            lastAttemptAt: lastAttemptAt,
            nextRetryAt: nextRetryAt,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String entityTable,
            required String entityId,
            required String operation,
            Value<String?> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            entityTable: entityTable,
            entityId: entityId,
            operation: operation,
            payload: payload,
            createdAt: createdAt,
            status: status,
            attemptCount: attemptCount,
            lastAttemptAt: lastAttemptAt,
            nextRetryAt: nextRetryAt,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;
typedef $$SyncStatesTableCreateCompanionBuilder = SyncStatesCompanion Function({
  required String deviceId,
  required String provider,
  Value<int> lastAppliedGeneration,
  Value<DateTime?> lastSyncTime,
  Value<int> rowid,
});
typedef $$SyncStatesTableUpdateCompanionBuilder = SyncStatesCompanion Function({
  Value<String> deviceId,
  Value<String> provider,
  Value<int> lastAppliedGeneration,
  Value<DateTime?> lastSyncTime,
  Value<int> rowid,
});

class $$SyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastAppliedGeneration => $composableBuilder(
      column: $table.lastAppliedGeneration,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncTime => $composableBuilder(
      column: $table.lastSyncTime, builder: (column) => ColumnFilters(column));
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastAppliedGeneration => $composableBuilder(
      column: $table.lastAppliedGeneration,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncTime => $composableBuilder(
      column: $table.lastSyncTime,
      builder: (column) => ColumnOrderings(column));
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<int> get lastAppliedGeneration => $composableBuilder(
      column: $table.lastAppliedGeneration, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncTime => $composableBuilder(
      column: $table.lastSyncTime, builder: (column) => column);
}

class $$SyncStatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncStatesTable,
    SyncStateData,
    $$SyncStatesTableFilterComposer,
    $$SyncStatesTableOrderingComposer,
    $$SyncStatesTableAnnotationComposer,
    $$SyncStatesTableCreateCompanionBuilder,
    $$SyncStatesTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStatesTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()> {
  $$SyncStatesTableTableManager(_$AppDatabase db, $SyncStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> deviceId = const Value.absent(),
            Value<String> provider = const Value.absent(),
            Value<int> lastAppliedGeneration = const Value.absent(),
            Value<DateTime?> lastSyncTime = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStatesCompanion(
            deviceId: deviceId,
            provider: provider,
            lastAppliedGeneration: lastAppliedGeneration,
            lastSyncTime: lastSyncTime,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String deviceId,
            required String provider,
            Value<int> lastAppliedGeneration = const Value.absent(),
            Value<DateTime?> lastSyncTime = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStatesCompanion.insert(
            deviceId: deviceId,
            provider: provider,
            lastAppliedGeneration: lastAppliedGeneration,
            lastSyncTime: lastSyncTime,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncStatesTable,
    SyncStateData,
    $$SyncStatesTableFilterComposer,
    $$SyncStatesTableOrderingComposer,
    $$SyncStatesTableAnnotationComposer,
    $$SyncStatesTableCreateCompanionBuilder,
    $$SyncStatesTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStatesTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableTableCreateCompanionBuilder
    = AppSettingsTableCompanion Function({
  required String id,
  Value<String> themeMode,
  Value<String> syncFrequency,
  Value<bool> autoSync,
  Value<int> cacheLimitMB,
  Value<DateTime?> lastCleanup,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AppSettingsTableTableUpdateCompanionBuilder
    = AppSettingsTableCompanion Function({
  Value<String> id,
  Value<String> themeMode,
  Value<String> syncFrequency,
  Value<bool> autoSync,
  Value<int> cacheLimitMB,
  Value<DateTime?> lastCleanup,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AppSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncFrequency => $composableBuilder(
      column: $table.syncFrequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoSync => $composableBuilder(
      column: $table.autoSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cacheLimitMB => $composableBuilder(
      column: $table.cacheLimitMB, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastCleanup => $composableBuilder(
      column: $table.lastCleanup, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncFrequency => $composableBuilder(
      column: $table.syncFrequency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoSync => $composableBuilder(
      column: $table.autoSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cacheLimitMB => $composableBuilder(
      column: $table.cacheLimitMB,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastCleanup => $composableBuilder(
      column: $table.lastCleanup, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get syncFrequency => $composableBuilder(
      column: $table.syncFrequency, builder: (column) => column);

  GeneratedColumn<bool> get autoSync =>
      $composableBuilder(column: $table.autoSync, builder: (column) => column);

  GeneratedColumn<int> get cacheLimitMB => $composableBuilder(
      column: $table.cacheLimitMB, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCleanup => $composableBuilder(
      column: $table.lastCleanup, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTableTable,
    AppSettingEntity,
    $$AppSettingsTableTableFilterComposer,
    $$AppSettingsTableTableOrderingComposer,
    $$AppSettingsTableTableAnnotationComposer,
    $$AppSettingsTableTableCreateCompanionBuilder,
    $$AppSettingsTableTableUpdateCompanionBuilder,
    (
      AppSettingEntity,
      BaseReferences<_$AppDatabase, $AppSettingsTableTable, AppSettingEntity>
    ),
    AppSettingEntity,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableTableManager(
      _$AppDatabase db, $AppSettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<String> syncFrequency = const Value.absent(),
            Value<bool> autoSync = const Value.absent(),
            Value<int> cacheLimitMB = const Value.absent(),
            Value<DateTime?> lastCleanup = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsTableCompanion(
            id: id,
            themeMode: themeMode,
            syncFrequency: syncFrequency,
            autoSync: autoSync,
            cacheLimitMB: cacheLimitMB,
            lastCleanup: lastCleanup,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> themeMode = const Value.absent(),
            Value<String> syncFrequency = const Value.absent(),
            Value<bool> autoSync = const Value.absent(),
            Value<int> cacheLimitMB = const Value.absent(),
            Value<DateTime?> lastCleanup = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsTableCompanion.insert(
            id: id,
            themeMode: themeMode,
            syncFrequency: syncFrequency,
            autoSync: autoSync,
            cacheLimitMB: cacheLimitMB,
            lastCleanup: lastCleanup,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTableTable,
    AppSettingEntity,
    $$AppSettingsTableTableFilterComposer,
    $$AppSettingsTableTableOrderingComposer,
    $$AppSettingsTableTableAnnotationComposer,
    $$AppSettingsTableTableCreateCompanionBuilder,
    $$AppSettingsTableTableUpdateCompanionBuilder,
    (
      AppSettingEntity,
      BaseReferences<_$AppDatabase, $AppSettingsTableTable, AppSettingEntity>
    ),
    AppSettingEntity,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PagesTableTableManager get pages =>
      $$PagesTableTableManager(_db, _db.pages);
  $$BlocksTableTableManager get blocks =>
      $$BlocksTableTableManager(_db, _db.blocks);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$HistoryPagesTableTableManager get historyPages =>
      $$HistoryPagesTableTableManager(_db, _db.historyPages);
  $$PageCollectionsTableTableManager get pageCollections =>
      $$PageCollectionsTableTableManager(_db, _db.pageCollections);
  $$PageTagsTableTableManager get pageTags =>
      $$PageTagsTableTableManager(_db, _db.pageTags);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
  $$AppSettingsTableTableTableManager get appSettingsTable =>
      $$AppSettingsTableTableTableManager(_db, _db.appSettingsTable);
}
