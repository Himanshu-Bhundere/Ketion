
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attachment_storage_service.dart';
import '../../../../core/database/app_database.dart';

/// Manages the local cache size of attachments, evicting the least recently used
/// (LRU) attachments that are NOT pinned for offline access when space is constrained.
class AttachmentCacheManager {
  final AppDatabase _db;
  final AttachmentStorageService _storageService;

  AttachmentCacheManager(this._db, this._storageService);

  /// Enforces a maximum cache size (in bytes).
  ///
  /// This will delete the physical files of unpinned attachments to free up space.
  /// It updates the database by setting localPath and thumbnailPath to null
  /// and uploadStatus to AttachmentUploadStatus.uploaded (if it was already uploaded).
  Future<void> enforceCacheLimit(int maxSizeBytes) async {
    // Note: For LRU eviction, we need a way to track "last accessed" time.
    // Currently, we'll use `updatedAt` on the attachment as a proxy, 
    // or we could just use file modification time. 
    // The query finds unpinned attachments that have local files, ordered by oldest first.
    
    // First, let's get all attachments that are unpinned and have a local path.
    final rows = await (_db.select(_db.attachments)
          ..where((t) => t.isPinnedOffline.equals(false))
          ..where((t) => t.localPath.isNotNull())
          ..where((t) => t.uploadStatus.equals('uploaded')) // Only evict if backed up
          ..where((t) => t.deleted.equals(false))
          // Order by oldest first
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.asc)]))
        .get();

    int totalSize = 0;
    for (final row in rows) {
      totalSize += row.fileSize;
    }

    if (totalSize <= maxSizeBytes) {
      return; // Under limit
    }

    int bytesToFree = totalSize - maxSizeBytes;
    int bytesFreed = 0;

    for (final row in rows) {
      if (bytesFreed >= bytesToFree) break;

      // Delete physical files
      if (row.localPath != null) {
        await _storageService.deleteFile(row.localPath!);
      }
      if (row.thumbnailPath != null) {
        await _storageService.deleteFile(row.thumbnailPath!);
      }

      // Update database to remove local paths
      await (_db.update(_db.attachments)..where((t) => t.id.equals(row.id))).write(
        const AttachmentsCompanion(
          localPath: Value(null),
          thumbnailPath: Value(null),
          // We can only evict if it's already uploaded to Drive.
          // Wait, if it's not uploaded, we shouldn't evict it!
          // We should filter only those that are 'uploaded'.
        ),
      );

      bytesFreed += row.fileSize;
    }
  }
}

final attachmentCacheManagerProvider = Provider<AttachmentCacheManager>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final storageService = ref.watch(attachmentStorageServiceProvider);
  return AttachmentCacheManager(db, storageService);
});
