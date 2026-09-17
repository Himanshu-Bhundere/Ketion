import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/media/data/repositories/attachment_repository_impl.dart';
import 'package:ketion/features/media/data/services/attachment_storage_service.dart';
import 'package:ketion/features/media/data/services/checksum_service.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;

  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationSupportPath() async {
    return tempDir.path;
  }
}

void main() {
  late AppDatabase database;
  late ChecksumService checksumService;
  late AttachmentStorageService storageService;
  late AttachmentRepositoryImpl repository;
  late Directory tempDir;
  late File testFile;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('dedup_integration_test');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    checksumService = ChecksumService();
    storageService = AttachmentStorageService(checksumService);
    final syncQueue = SyncQueueRepositoryImpl(database);
    repository = AttachmentRepositoryImpl(database, storageService, syncQueue);

    testFile = File(p.join(tempDir.path, 'test_image.png'));
    await testFile.writeAsString('fake image content for dedup test');

    final now = DateTime.now();
    await database.into(database.pages).insert(
      PagesCompanion.insert(
        id: 'page-dedup',
        title: const Value('Dedup Test Page'),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.into(database.blocks).insert(
      BlocksCompanion.insert(
        id: 'block-dedup-1',
        pageId: 'page-dedup',
        data: 'test data',
        type: 'text',
        position: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.into(database.blocks).insert(
      BlocksCompanion.insert(
        id: 'block-dedup-2',
        pageId: 'page-dedup',
        data: 'test data',
        type: 'text',
        position: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Attachment deduplication integration', () {
    test('two saves of the same file produce the same checksum and share storage', () async {
      final att1 = await repository.saveAttachment(
        pageId: 'page-dedup',
        blockId: 'block-dedup-1',
        sourceFile: testFile,
        mimeType: 'image/png',
      );

      final att2 = await repository.saveAttachment(
        pageId: 'page-dedup',
        blockId: 'block-dedup-2',
        sourceFile: testFile,
        mimeType: 'image/png',
      );

      // Different attachment IDs
      expect(att1.id, isNot(att2.id));
      // Same checksum (content-addressable dedup)
      expect(att1.checksumSha256, isNotNull);
      expect(att1.checksumSha256, equals(att2.checksumSha256));
      // Same local path (shared physical file)
      expect(att1.localPath, equals(att2.localPath));
    });

    test('deleting one duplicate does not remove the file when another reference exists', () async {
      final att1 = await repository.saveAttachment(
        pageId: 'page-dedup',
        blockId: 'block-dedup-1',
        sourceFile: testFile,
        mimeType: 'image/png',
      );

      final att2 = await repository.saveAttachment(
        pageId: 'page-dedup',
        blockId: 'block-dedup-2',
        sourceFile: testFile,
        mimeType: 'image/png',
      );

      // Delete the first reference
      await repository.deleteAttachment(att1.id);

      // The second reference should still be valid
      final surviving = await repository.getAttachment(att2.id);
      expect(surviving, isNotNull);
      expect(surviving?.deleted, isFalse);

      // The file should still exist
      final resolvedPath = await repository.resolveAttachmentPath(surviving!);
      expect(await File(resolvedPath).exists(), isTrue);
    });

    test('different files produce different checksums', () async {
      final otherFile = File(p.join(tempDir.path, 'other_image.png'));
      await otherFile.writeAsString('different content');

      final att1 = await repository.saveAttachment(
        pageId: 'page-dedup',
        blockId: 'block-dedup-1',
        sourceFile: testFile,
        mimeType: 'image/png',
      );

      final att2 = await repository.saveAttachment(
        pageId: 'page-dedup',
        blockId: 'block-dedup-2',
        sourceFile: otherFile,
        mimeType: 'image/png',
      );

      expect(att1.checksumSha256, isNot(equals(att2.checksumSha256)));
      expect(att1.localPath, isNot(equals(att2.localPath)));
    });

    test('getPendingUploads returns attachments with pending status', () async {
      await repository.saveAttachment(
        pageId: 'page-dedup',
        blockId: 'block-dedup-1',
        sourceFile: testFile,
        mimeType: 'image/png',
      );

      final pendingUploads = await repository.getPendingUploads();
      expect(pendingUploads.length, 1);
    });

    test('updateAttachmentSyncStatus changes upload status', () async {
      final att = await repository.saveAttachment(
        pageId: 'page-dedup',
        blockId: 'block-dedup-1',
        sourceFile: testFile,
        mimeType: 'image/png',
      );

      await repository.updateAttachmentSyncStatus(
        att.id,
        'Uploaded',
        driveFileId: 'drive-file-123',
      );

      // After updating, pending uploads should be empty
      final pendingUploads = await repository.getPendingUploads();
      expect(pendingUploads.isEmpty, isTrue);

      // The attachment should have the drive file ID
      final updated = await repository.getAttachment(att.id);
      expect(updated?.driveFileId, 'drive-file-123');
    });
  });
}
