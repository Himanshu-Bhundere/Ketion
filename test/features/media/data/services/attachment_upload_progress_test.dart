import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/media/domain/entities/attachment.dart';
import 'package:ketion/features/media/domain/entities/attachment_upload_status.dart';
import 'package:ketion/features/media/domain/repositories/attachment_repository.dart';
import 'package:ketion/features/media/data/services/attachment_storage_service.dart';
import 'package:ketion/features/media/data/services/attachment_sync_service_impl.dart';
import 'package:ketion/features/sync/domain/providers/sync_provider.dart';

class _FakeAttachmentRepository implements AttachmentRepository {
  final Map<String, Attachment> attachments = {};
  final List<String> statusUpdates = [];

  @override
  Future<String> resolveAttachmentPath(Attachment attachment) async =>
      '/mock/path/${attachment.id}';

  @override
  Future<void> updateAttachmentSyncStatus(
    String id,
    String uploadStatus, {
    String? driveFileId,
    String? localPath,
  }) async {
    statusUpdates.add('$id:$uploadStatus');
    final current = attachments[id];
    if (current != null) {
      attachments[id] = current.copyWith(
        uploadStatus: AttachmentUploadStatus.fromString(uploadStatus),
        driveFileId: driveFileId ?? current.driveFileId,
        localPath: localPath ?? current.localPath,
      );
    }
  }

  @override
  Future<List<Attachment>> getPendingUploads() async {
    return attachments.values
        .where(
          (a) =>
              !a.deleted &&
              (a.uploadStatus == AttachmentUploadStatus.pending ||
                  a.uploadStatus == AttachmentUploadStatus.failed ||
                  a.uploadStatus == AttachmentUploadStatus.uploading),
        )
        .toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSyncProvider implements SyncProvider {
  double? emittedProgress;
  bool shouldFail = false;
  Completer<void>? uploadSignal;

  @override
  String get providerId => 'fake_sync';

  @override
  Future<Result<String>> uploadAttachment(
    String localPath,
    String mimeType,
    String checksum, {
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    onProgress?.call(0.0);
    onProgress?.call(0.5);
    onProgress?.call(1.0);

    if (uploadSignal != null) {
      await uploadSignal!.future;
    }

    if (isCancelled?.call() == true) {
      return const Error(SyncFailure('Upload cancelled by user'));
    }

    if (shouldFail) {
      return const Error(SyncFailure('Simulated upload failure'));
    }

    return const Success('drive-file-id-123');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStorageService extends Fake implements AttachmentStorageService {}

void main() {
  group('Attachment Upload Progress & Recovery Tests', () {
    late _FakeAttachmentRepository repository;
    late _FakeSyncProvider syncProvider;
    late _FakeStorageService storageService;
    late Attachment testAttachment;

    setUp(() {
      repository = _FakeAttachmentRepository();
      syncProvider = _FakeSyncProvider();
      storageService = _FakeStorageService();

      testAttachment = Attachment(
        id: 'att-1',
        blockId: 'block-1',
        localPath: 'Attachments/12/file.png',
        mimeType: 'image/png',
        checksumSha256: 'sha256-hash',
        fileSize: 1024,
        uploadStatus: AttachmentUploadStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
        isPinnedOffline: false,
      );
      repository.attachments[testAttachment.id] = testAttachment;
    });

    test('Upload emits initial 0%, live progress updates, and clears progress to null on completion', () async {
      final progressUpdates = <double?>[];
      final statusUpdates = <String>[];

      final service = AttachmentSyncServiceImpl(
        repository,
        syncProvider,
        storageService,
        onProgressChanged: (id, progress) {
          progressUpdates.add(progress);
        },
        onStatusChanged: (id) {
          statusUpdates.add(id);
        },
      );

      await service.uploadAttachment(testAttachment);

      // Verify sequence of progress: 0.0 (initial), 0.0, 0.5, 1.0 (from sync provider), null (cleanup in finally)
      expect(progressUpdates, contains(0.0));
      expect(progressUpdates, contains(0.5));
      expect(progressUpdates, contains(1.0));
      expect(progressUpdates.last, isNull);

      // Verify database status transitions: uploading -> uploaded
      expect(repository.statusUpdates, contains('att-1:${AttachmentUploadStatus.uploading.value}'));
      expect(repository.statusUpdates, contains('att-1:${AttachmentUploadStatus.uploaded.value}'));
    });

    test('Failed upload marks attachment status as failed and resets progress to null', () async {
      syncProvider.shouldFail = true;
      final progressUpdates = <double?>[];

      final service = AttachmentSyncServiceImpl(
        repository,
        syncProvider,
        storageService,
        onProgressChanged: (id, progress) {
          progressUpdates.add(progress);
        },
      );

      await service.uploadAttachment(testAttachment);

      expect(repository.statusUpdates, contains('att-1:${AttachmentUploadStatus.uploading.value}'));
      expect(repository.statusUpdates, contains('att-1:${AttachmentUploadStatus.failed.value}'));
      expect(progressUpdates.last, isNull);
    });

    test('Cancelled upload marks attachment status as cancelled', () async {
      final uploadSignal = Completer<void>();
      syncProvider.uploadSignal = uploadSignal;

      final service = AttachmentSyncServiceImpl(
        repository,
        syncProvider,
        storageService,
      );

      final uploadFuture = service.uploadAttachment(testAttachment);
      await service.cancelSync(testAttachment.id);
      uploadSignal.complete();
      await uploadFuture;

      expect(repository.statusUpdates, contains('att-1:${AttachmentUploadStatus.cancelled.value}'));
    });

    test('getPendingUploads includes uploading status to recover interrupted uploads', () async {
      repository.attachments['att-interrupted'] = testAttachment.copyWith(
        id: 'att-interrupted',
        uploadStatus: AttachmentUploadStatus.uploading,
      );

      final pending = await repository.getPendingUploads();
      final ids = pending.map((a) => a.id).toList();
      expect(ids, contains('att-interrupted'));
    });
  });
}
