import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/collection.dart' as domain;

extension CollectionMapper on db.Collection {
  domain.Collection toDomain() {
    return domain.Collection(
      id: id,
      name: name,
      icon: icon,
      color: color,
      version: version,
    );
  }
}

extension DomainCollectionMapper on domain.Collection {
  db.CollectionsCompanion toCompanion() {
    return db.CollectionsCompanion.insert(
      id: id,
      name: name,
      icon: drift.Value(icon),
      color: drift.Value(color),
      version: drift.Value(version),
    );
  }
}
