import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/attachment_upload_status.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../services/attachment_storage_service.dart';
import '../../../sync/domain/repositories/sync_queue_repository.dart';
import '../../../sync/domain/entities/sync_queue_item.dart';
import '../../../sync/presentation/providers/sync_providers.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  final AppDatabase _db;
  final AttachmentStorageService _storageService;
  final SyncQueueRepository _syncQueue;
  final Uuid _uuid = const Uuid();

  AttachmentRepositoryImpl(this._db, this._storageService, this._syncQueue);

  @override
  Future<Attachment> saveAttachment({
    required String pageId,
    required String blockId,
    required PlatformFile sourceFile,
    required String mimeType,
  }) async {
    final fileSize = sourceFile.size;

    // Save to storage service (will deduplicate automatically if exists)
    final mediaResult = await _storageService.saveAttachment(
      sourceFile,
      generateThumbnail: mimeType.startsWith('image/'),
    );
    final localPath = mediaResult.$1;
    final thumbnailPath = mediaResult.$2;
    final sha256 = mediaResult.$3;

    final id = _uuid.v4();
    final now = DateTime.now();

    final attachment = Attachment(
      id: id,
      blockId: blockId,
      localPath: localPath,
      mimeType: mimeType,
      checksumSha256: sha256,
      fileSize: fileSize,
      thumbnailPath: thumbnailPath,
      uploadStatus: AttachmentUploadStatus.pending,
      createdAt: now,
      updatedAt: now,
      version: 1,
      deleted: false,
      isPinnedOffline: false,
    );

    // Save to database
    await _db.transaction(() async {
      await _db.into(_db.attachments).insert(
            AttachmentsCompanion.insert(
              id: id,
              blockId: blockId,
              localPath: Value(localPath),
              mimeType: mimeType,
              checksumSha256: Value(sha256),
              fileSize: fileSize,
              thumbnailPath: Value(thumbnailPath),
              uploadStatus: Value(AttachmentUploadStatus.pending.value),
              createdAt: Value(now),
              updatedAt: Value(now),
              version: const Value(1),
              deleted: const Value(false),
              isPinnedOffline: const Value(false),
            ),
          );

      await _syncQueue.enqueueOrCoalesce(
        SyncQueueItem(
          id: const Uuid().v7(),
          entityTable: 'attachments',
          entityId: id,
          operation: 'create',
          payload: jsonEncode(attachment.toJson()),
          createdAt: DateTime.now().toUtc(),
        ),
      );
    });

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
    // We need to join with blocks to get attachments for a page
    final query = _db.select(_db.attachments).join([
      innerJoin(_db.blocks, _db.blocks.id.equalsExp(_db.attachments.blockId)),
    ])
      ..where(_db.blocks.pageId.equals(pageId))
      ..where(_db.attachments.deleted.equals(false));

    final rows = await query.get();
    return rows
        .map((row) => _mapRowToEntity(row.readTable(_db.attachments)))
        .toList();
  }

  @override
  Future<void> deleteAttachment(String id) async {
    await _db.transaction(() async {
      final attachment = await getAttachment(id);
      if (attachment == null) return;

      final newVersion = attachment.version + 1;

      // Soft delete in database
      final updatedRows = await (_db.update(_db.attachments)
            ..where((t) => t.id.equals(id)))
          .write(
        AttachmentsCompanion(
          deleted: const Value(true),
          version: Value(newVersion),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (updatedRows > 0) {
        await _syncQueue.enqueueOrCoalesce(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'attachments',
            entityId: id,
            operation: 'update',
            payload: jsonEncode(
              attachment
                  .copyWith(
                    deleted: true,
                    version: newVersion,
                    updatedAt: DateTime.now(),
                  )
                  .toJson(),
            ),
            createdAt: DateTime.now().toUtc(),
          ),
        );
      }
    });

    // Note: We don't delete the physical file yet because other blocks might reference
    // the same file (deduplication via SHA-256). A separate garbage collection
    // routine will handle orphaned files based on reference counting.
  }

  @override
  Future<String> resolveAttachmentPath(Attachment attachment) async {
    if (attachment.localPath == null) return '';
    return _storageService.resolvePath(attachment.localPath!);
  }

  @override
  Future<void> garbageCollectOrphanedFiles() async {
    final validPaths = <String>{};

    // Get all non-deleted attachments
    final rows = await (_db.select(_db.attachments)
          ..where((t) => t.deleted.equals(false)))
        .get();

    for (final row in rows) {
      if (row.localPath != null) {
        validPaths.add(row.localPath!.replaceAll('\\', '/'));
      }
      if (row.thumbnailPath != null) {
        validPaths.add(row.thumbnailPath!.replaceAll('\\', '/'));
      }
    }

    await _storageService.garbageCollect(validPaths);
  }

  @override
  Future<void> updateAttachmentSyncStatus(
    String id,
    String uploadStatus, {
    String? driveFileId,
    String? localPath,
  }) async {
    await _db.transaction(() async {
      final companion = AttachmentsCompanion(
        uploadStatus: Value(uploadStatus),
        updatedAt: Value(DateTime.now()),
        driveFileId:
            driveFileId != null ? Value(driveFileId) : const Value.absent(),
        localPath: localPath != null ? Value(localPath) : const Value.absent(),
      );

      final updatedRows = await (_db.update(_db.attachments)
            ..where((t) => t.id.equals(id)))
          .write(companion);

      // If we assigned a driveFileId, we need to sync this metadata to other devices
      if (updatedRows > 0 && driveFileId != null) {
        final attachment = await getAttachment(id);
        if (attachment != null) {
          final newVersion = attachment.version + 1;
          await (_db.update(_db.attachments)..where((t) => t.id.equals(id)))
              .write(
            AttachmentsCompanion(version: Value(newVersion)),
          );

          await _syncQueue.enqueueOrCoalesce(
            SyncQueueItem(
              id: const Uuid().v7(),
              entityTable: 'attachments',
              entityId: id,
              operation: 'update',
              payload:
                  jsonEncode(attachment.copyWith(version: newVersion).toJson()),
              createdAt: DateTime.now().toUtc(),
            ),
          );
        }
      }
    });
  }

  @override
  Future<List<Attachment>> getPendingUploads() async {
    final rows = await (_db.select(_db.attachments)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                (t.uploadStatus.equals(AttachmentUploadStatus.pending.value) |
                    t.uploadStatus.equals(AttachmentUploadStatus.failed.value)),
          ))
        .get();
    return rows.map(_mapRowToEntity).toList();
  }

  @override
  Future<List<Attachment>> getPendingDownloads() async {
    final rows = await (_db.select(_db.attachments)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                t.driveFileId.isNotNull() &
                t.localPath.isNull(),
          ))
        .get();
    return rows.map(_mapRowToEntity).toList();
  }

  Attachment _mapRowToEntity(AttachmentData row) {
    return Attachment(
      id: row.id,
      blockId: row.blockId,
      driveFileId: row.driveFileId,
      localPath: row.localPath,
      mimeType: row.mimeType,
      checksumSha256: row.checksumSha256,
      fileSize: row.fileSize,
      width: row.width,
      height: row.height,
      duration: row.duration,
      thumbnailPath: row.thumbnailPath,
      uploadStatus: AttachmentUploadStatus.fromString(row.uploadStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
      deleted: row.deleted,
      isPinnedOffline: row.isPinnedOffline,
    );
  }
}

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final storageService = ref.watch(attachmentStorageServiceProvider);
  final syncQueue = ref.watch(syncQueueRepositoryProvider);
  return AttachmentRepositoryImpl(db, storageService, syncQueue);
});
