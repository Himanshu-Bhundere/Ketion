import 'package:drift/drift.dart' as drift;
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as domain_page;
import 'package:ketion/features/blocks/domain/entities/block.dart' as domain_block;
import 'package:ketion/features/media/domain/entities/attachment.dart' as domain_attachment;
import 'package:ketion/features/pages/data/models/page_mapper.dart';
import 'package:ketion/features/blocks/data/models/block_mapper.dart';
import 'package:ketion/features/media/data/models/attachment_mapper.dart';

class SyncEntityApplier {
  final AppDatabase _db;

  SyncEntityApplier(this._db);

  /// Applies an upsert operation using the generated Data Classes / Companions.
  Future<void> applyUpsert(String table, String entityId, Map<String, dynamic> payload) async {
    switch (table) {
      case 'pages':
        final page = domain_page.Page.fromJson(payload);
        await _db.into(_db.pages).insertOnConflictUpdate(page.toCompanion());
        break;
      case 'blocks':
        final block = domain_block.Block.fromJson(payload);
        await _db.into(_db.blocks).insertOnConflictUpdate(block.toCompanion());
        break;
      case 'attachments':
        final attachment = domain_attachment.Attachment.fromJson(payload);
        await _db.into(_db.attachments).insertOnConflictUpdate(attachment.toCompanion());
        break;
      default:
        // Other tables could be added here (e.g. widgets)
        break;
    }
  }

  /// Applies a soft-delete operation.
  Future<void> applyDelete(String table, String entityId) async {
    final now = DateTime.now().toUtc();
    switch (table) {
      case 'pages':
        await (_db.update(_db.pages)..where((t) => t.id.equals(entityId)))
            .write(PagesCompanion(
          deleted: const drift.Value(true),
          updatedAt: drift.Value(now),
        ));
        break;
      case 'blocks':
        await (_db.update(_db.blocks)..where((t) => t.id.equals(entityId)))
            .write(BlocksCompanion(
          deleted: const drift.Value(true),
          updatedAt: drift.Value(now),
        ));
        break;
      case 'attachments':
        await (_db.update(_db.attachments)..where((t) => t.id.equals(entityId)))
            .write(AttachmentsCompanion(
          deleted: const drift.Value(true),
          updatedAt: drift.Value(now),
        ));
        break;
      default:
        // Do nothing for unknown tables
        break;
    }
  }
}
