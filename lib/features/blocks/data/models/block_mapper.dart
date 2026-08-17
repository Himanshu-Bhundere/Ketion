import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/block.dart' as domain;

extension BlockMapper on db.Block {
  domain.Block toDomain() {
    return domain.Block(
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
    );
  }
}

extension DomainBlockMapper on domain.Block {
  db.BlocksCompanion toCompanion() {
    return db.BlocksCompanion.insert(
      id: id,
      pageId: pageId,
      parentBlockId: drift.Value(parentBlockId),
      type: type,
      position: position,
      data: data,
      version: drift.Value(version),
      deleted: drift.Value(deleted),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
