import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../../core/database/app_database.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../services/media_service.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  final AppDatabase _db;
  final MediaService _mediaService;
  final Uuid _uuid = const Uuid();

  AttachmentRepositoryImpl(this._db, this._mediaService);

  @override
  Future<Attachment> saveAttachment({
    required String pageId,
    required String blockId,
    required File sourceFile,
    required String mimeType,
  }) async {
    final size = await sourceFile.length();
    final fileName = p.basename(sourceFile.path);
    final sha256 = await _mediaService.calculateSha256(sourceFile);

    // Save to media service (will deduplicate automatically if exists)
    final mediaResult = await _mediaService.saveMedia(
      sourceFile,
      generateThumbnail: mimeType.startsWith('image/'),
    );
    final relativePath = mediaResult.$1;
    final thumbnailPath = mediaResult.$2;

    final id = _uuid.v4();
    final now = DateTime.now();

    final attachment = Attachment(
      id: id,
      pageId: pageId,
      blockId: blockId,
      fileName: fileName,
      mimeType: mimeType,
      size: size,
      sha256: sha256,
      relativePath: relativePath,
      thumbnailPath: thumbnailPath,
      createdAt: now,
      updatedAt: now,
    );

    // Save to database
    await _db.into(_db.attachments).insert(
          AttachmentsCompanion.insert(
            id: id,
            pageId: pageId,
            blockId: blockId,
            fileName: fileName,
            mimeType: mimeType,
            size: size,
            sha256: sha256,
            relativePath: relativePath,
            thumbnailPath: Value(thumbnailPath),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return attachment;
  }

  @override
  Future<Attachment?> getAttachment(String id) async {
    final row = await (_db.select(_db.attachments)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null || row.deleted) return null;
    return _mapRowToEntity(row);
  }

  @override
  Future<List<Attachment>> getAttachmentsForPage(String pageId) async {
    final rows = await (_db.select(_db.attachments)
          ..where((t) => t.pageId.equals(pageId))
          ..where((t) => t.deleted.equals(false)))
        .get();

    return rows.map(_mapRowToEntity).toList();
  }

  @override
  Future<void> deleteAttachment(String id) async {
    // Soft delete in database
    await (_db.update(_db.attachments)..where((t) => t.id.equals(id))).write(
      AttachmentsCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Note: We don't delete the physical file yet because other blocks might reference
    // the same file (deduplication via SHA-256). A separate garbage collection
    // routine would handle orphaned files later.
  }

  @override
  Future<String> resolveAttachmentPath(Attachment attachment) {
    return _mediaService.resolvePath(attachment.relativePath);
  }

  Attachment _mapRowToEntity(AttachmentData row) {
    return Attachment(
      id: row.id,
      pageId: row.pageId,
      blockId: row.blockId,
      fileName: row.fileName,
      mimeType: row.mimeType,
      size: row.size,
      sha256: row.sha256,
      relativePath: row.relativePath,
      thumbnailPath: row.thumbnailPath,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deleted: row.deleted,
    );
  }
}

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final mediaService = ref.watch(mediaServiceProvider);
  return AttachmentRepositoryImpl(db, mediaService);
});
