import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/attachment.dart';
import '../../domain/entities/attachment_upload_status.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../../domain/services/attachment_sync_service.dart';
import '../../presentation/providers/attachment_provider.dart';
import 'attachment_storage_service.dart';
import '../../../sync/domain/providers/sync_provider.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../repositories/attachment_repository_impl.dart';

class AttachmentSyncServiceImpl implements AttachmentSyncService {
  final AttachmentRepository _repository;
  final SyncProvider _syncProvider;
  final AttachmentStorageService _storageService;
  final Set<String> _cancelledIds = {};
  final Map<String, void Function(double progress)> _progressListeners = {};
  final void Function(String id, double? progress)? _onProgressChanged;
  final void Function(String id)? _onStatusChanged;

  AttachmentSyncServiceImpl(
    this._repository,
    this._syncProvider,
    this._storageService, {
    void Function(String id, double? progress)? onProgressChanged,
    void Function(String id)? onStatusChanged,
  })  : _onProgressChanged = onProgressChanged,
        _onStatusChanged = onStatusChanged;

  void setProgressListener(String attachmentId, void Function(double progress) listener) {
    _progressListeners[attachmentId] = listener;
  }

  void removeProgressListener(String attachmentId) {
    _progressListeners.remove(attachmentId);
  }

  @override
  Future<void> uploadAttachment(Attachment attachment) async {
    if (attachment.localPath == null || attachment.checksumSha256 == null) {
      return;
    }

    final id = attachment.id;
    _cancelledIds.remove(id);

    _onProgressChanged?.call(id, 0);

    await _repository.updateAttachmentSyncStatus(
      id,
      AttachmentUploadStatus.uploading.value,
    );

    _onStatusChanged?.call(id);

    try {
      final absolutePath = await _repository.resolveAttachmentPath(attachment);

      final result = await _syncProvider.uploadAttachment(
        absolutePath,
        attachment.mimeType,
        attachment.checksumSha256!,
        onProgress: (progress) {
          _progressListeners[id]?.call(progress);
          _onProgressChanged?.call(id, progress);
        },
        isCancelled: () => _cancelledIds.contains(id),
      );

      if (_cancelledIds.remove(id)) {
        await _repository.updateAttachmentSyncStatus(
          id,
          AttachmentUploadStatus.cancelled.value,
        );
        return;
      }

      await result.fold(
        (driveFileId) async {
          await _repository.updateAttachmentSyncStatus(
            id,
            AttachmentUploadStatus.uploaded.value,
            driveFileId: driveFileId,
          );
        },
        (failure) async {
          await _repository.updateAttachmentSyncStatus(
            id,
            AttachmentUploadStatus.failed.value,
          );
        },
      );
    } catch (e) {
      final wasCancelled = _cancelledIds.remove(id);

      await _repository.updateAttachmentSyncStatus(
        id,
        wasCancelled
            ? AttachmentUploadStatus.cancelled.value
            : AttachmentUploadStatus.failed.value,
      );

      if (!wasCancelled) rethrow;
    } finally {
      _cancelledIds.remove(id);
      _onProgressChanged?.call(id, null);
      _onStatusChanged?.call(id);
    }
  }

  @override
  Future<void> downloadAttachment(Attachment attachment) async {
    if (attachment.driveFileId == null) return;

    if (kIsWeb) {
      throw UnsupportedError(
        'Local attachment download is not supported on the web',
      );
    }

    // We need a temp directory
    final tempDir = io.Directory.systemTemp;
    final tempFile = io.File('${tempDir.path}/${attachment.id}_download');

    final result = await _syncProvider.downloadAttachment(
      attachment.driveFileId!,
      tempFile.path,
    );

    await result.fold(
      (_) async {
        final platformFile = PlatformFile(
          name: '${attachment.id}_download',
          size: await tempFile.length(),
          path: tempFile.path,
        );

        // Save the downloaded file to managed storage
        final saveResult = await _storageService.saveAttachment(
          platformFile,
          generateThumbnail: attachment.mimeType.startsWith('image/'),
        );
        final localPath = saveResult.$1;
        final downloadedHash = saveResult.$3;

        if (attachment.checksumSha256 != null &&
            downloadedHash != attachment.checksumSha256) {
          // Checksum mismatch, delete from storage
          await _storageService.deleteFile(localPath);
          if (saveResult.$2 != null) {
            await _storageService.deleteFile(saveResult.$2!);
          }
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          await _repository.updateAttachmentSyncStatus(
            attachment.id,
            AttachmentUploadStatus.failed.value,
          );
          return;
        }

        // Clean up temp file
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        // Update repository
        await _repository.updateAttachmentSyncStatus(
          attachment.id,
          AttachmentUploadStatus.uploaded.value,
          localPath: localPath,
        );
      },
      (failure) async {
        // Handle error
        await _repository.updateAttachmentSyncStatus(
          attachment.id,
          AttachmentUploadStatus.failed.value,
        );
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      },
    );
  }

  @override
  Future<void> cancelSync(String attachmentId) async {
    _cancelledIds.add(attachmentId);
  }

  @override
  Future<void> syncPendingAttachments() async {
    final pendingUploads = await _repository.getPendingUploads();
    for (final attachment in pendingUploads) {
      try {
        await uploadAttachment(attachment);
      } catch (e) {
        // Log or handle individual upload failure, continue with others
      }
    }

    final pendingDownloads = await _repository.getPendingDownloads();
    for (final attachment in pendingDownloads) {
      try {
        await downloadAttachment(attachment);
      } catch (e) {
        // Log or handle individual download failure, continue with others
      }
    }
  }
}

final attachmentSyncServiceProvider = Provider<AttachmentSyncService>((ref) {
  final repository = ref.watch(attachmentRepositoryProvider);
  final syncProvider = ref.watch(syncProviderInterfaceProvider);
  final storageService = ref.watch(attachmentStorageServiceProvider);

  return AttachmentSyncServiceImpl(
    repository,
    syncProvider,
    storageService,
    onProgressChanged: (id, progress) {
      ref.read(attachmentUploadProgressProvider(id).notifier).state = progress;
    },
    onStatusChanged: (id) {
      ref.invalidate(attachmentProvider(id));
    },
  );
});
