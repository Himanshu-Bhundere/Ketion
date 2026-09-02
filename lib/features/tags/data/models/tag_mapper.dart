import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/tag.dart' as domain;

extension TagMapper on db.Tag {
  domain.Tag toDomain() {
    return domain.Tag(
      id: id,
      name: name,
      color: color,
      version: version,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deleted: deleted,
    );
  }
}

extension DomainTagMapper on domain.Tag {
  db.TagsCompanion toCompanion() {
    return db.TagsCompanion.insert(
      id: id,
      name: name,
      color: drift.Value(color),
      version: drift.Value(version),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
      deleted: drift.Value(deleted),
    );
  }
}
