import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/page.dart' as domain;

extension PageMapper on db.Page {
  domain.Page toDomain() {
    return domain.Page(
      id: id,
      parentPageId: parentPageId,
      title: title,
      icon: icon,
      coverImage: coverImage,
      isFavorite: isFavorite,
      isArchived: isArchived,
      deleted: deleted,
      version: version,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension DomainPageMapper on domain.Page {
  db.PagesCompanion toCompanion() {
    return db.PagesCompanion.insert(
      id: id,
      parentPageId: drift.Value(parentPageId),
      title: drift.Value(title),
      icon: drift.Value(icon),
      coverImage: drift.Value(coverImage),
      isFavorite: drift.Value(isFavorite),
      isArchived: drift.Value(isArchived),
      deleted: drift.Value(deleted),
      version: drift.Value(version),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
