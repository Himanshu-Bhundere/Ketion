import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as domain_page;
import 'package:ketion/features/blocks/domain/entities/block.dart' as domain_block;
import 'package:ketion/features/media/domain/entities/attachment.dart' as domain_attachment;
import 'package:ketion/features/pages/data/models/page_mapper.dart';
import 'package:ketion/features/blocks/data/models/block_mapper.dart';
import 'package:ketion/features/media/data/models/attachment_mapper.dart';
import 'package:ketion/features/collections/domain/entities/collection.dart' as domain_collection;
import 'package:ketion/features/collections/data/models/collection_mapper.dart';
import 'package:ketion/features/tags/domain/entities/tag.dart' as domain_tag;
import 'package:ketion/features/tags/data/models/tag_mapper.dart';
import 'package:ketion/features/reminders/domain/entities/reminder.dart' as domain_reminder;
import 'package:ketion/features/reminders/data/models/reminder_mapper.dart';

class SyncEntityApplier {
  final AppDatabase _db;

  SyncEntityApplier(this._db);

  /// Applies a resolved entity (create, update, or tombstone delete) using the generated Data Classes / Companions.
  Future<void> applyResolvedEntity(String table, String entityId, Map<String, dynamic> payload) async {
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
      case 'collections':
        final collection = domain_collection.Collection.fromJson(payload);
        await _db.into(_db.collections).insertOnConflictUpdate(collection.toCompanion());
        break;
      case 'tags':
        final tag = domain_tag.Tag.fromJson(payload);
        await _db.into(_db.tags).insertOnConflictUpdate(tag.toCompanion());
        break;
      case 'reminders':
        final reminder = domain_reminder.ReminderEntity.fromJson(payload);
        await _db.into(_db.reminders).insertOnConflictUpdate(ReminderMapper.toDbCompanion(reminder));
        break;
      default:
        // Other tables could be added here (e.g. widgets)
        break;
    }
  }


}
