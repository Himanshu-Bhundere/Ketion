import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart' as db;
import '../../../editor/domain/models/block_data_models.dart';
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
    String? searchableText;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final model = BlockDataModel.fromJson(json);
      searchableText = model.searchableText;
    } catch (_) {
      searchableText = _legacySearchableText(data);
    }

    return db.BlocksCompanion.insert(
      id: id,
      pageId: pageId,
      parentBlockId: drift.Value(parentBlockId),
      type: type,
      position: position,
      data: data,
      searchableText: drift.Value(searchableText),
      version: drift.Value(version),
      deleted: drift.Value(deleted),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

String? _legacySearchableText(String data) {
  try {
    final json = jsonDecode(data) as Map<String, dynamic>;
    final spans = json['spans'];
    if (spans is! List) return null;
    return spans
        .whereType<Map<String, dynamic>>()
        .map((span) => span['text'])
        .whereType<String>()
        .join(' ');
  } catch (_) {
    return null;
  }
}
