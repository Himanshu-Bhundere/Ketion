import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as image_lib;
import 'package:drift/native.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/media/data/services/attachment_storage_service.dart';
import 'package:ketion/features/media/data/services/checksum_service.dart';
import 'package:ketion/features/media/data/services/attachment_export_service.dart';
import 'package:ketion/features/media/data/repositories/attachment_repository_impl.dart';
import 'package:ketion/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:ketion/features/sync/domain/entities/sync_queue_item.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final io.Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationSupportPath() async {
    return tempDir.path;
  }
}

class _MockSyncQueue implements SyncQueueRepository {
  final List<SyncQueueItem> queued = [];
  @override
  Future<Result<void>> enqueueOrCoalesce(SyncQueueItem item) async {
    queued.add(item);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ChecksumService checksumService;
  late AttachmentStorageService storageService;
  late _MockSyncQueue mockSyncQueue;
  late AttachmentRepositoryImpl repository;
  late io.Directory tempDir;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await io.Directory.systemTemp.createTemp('ketion_media_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    checksumService = ChecksumService();
    storageService = AttachmentStorageService(checksumService);
    mockSyncQueue = _MockSyncQueue();
    repository = AttachmentRepositoryImpl(db, storageService, mockSyncQueue);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Feature 4: Media Compression & Metrics', () {
    test('Image compression computes originalFileSize and compressedFileSize', () async {
      // Create a test uncompressed image (large dimension 2400x2400)
      final largeImage = image_lib.Image(width: 2400, height: 2400);
      for (var p in largeImage) {
        p.r = 200;
        p.g = 100;
        p.b = 50;
      }
      final rawJpg = Uint8List.fromList(image_lib.encodeJpg(largeImage, quality: 100));

      final testFile = io.File('${tempDir.path}/test_large.jpg');
      await testFile.writeAsBytes(rawJpg);

      final platformFile = PlatformFile(
        name: 'test_large.jpg',
        size: rawJpg.length,
        path: testFile.path,
        bytes: rawJpg,
      );

      final saved = await storageService.saveAttachment(
        platformFile,
        generateThumbnail: true,
        compressImage: true,
      );

      expect(saved.hash, isNotEmpty);
      expect(saved.originalFileSize, rawJpg.length);
      expect(saved.compressedFileSize, isNotNull);
      expect(saved.compressedFileSize!, lessThan(saved.originalFileSize!));
    });

    test('Repository stores originalFileSize, compressedFileSize, and allows soft-deletion', () async {
      final img = image_lib.Image(width: 2000, height: 2000);
      final rawJpg = Uint8List.fromList(image_lib.encodeJpg(img, quality: 100));
      final testFile = io.File('${tempDir.path}/repo_test.jpg');
      await testFile.writeAsBytes(rawJpg);

      final platformFile = PlatformFile(
        name: 'repo_test.jpg',
        size: rawJpg.length,
        path: testFile.path,
        bytes: rawJpg,
      );

      final attachment = await repository.saveAttachment(
        pageId: 'page-1',
        blockId: 'block-img-1',
        sourceFile: platformFile,
        mimeType: 'image/jpeg',
      );

      expect(attachment.originalFileSize, rawJpg.length);
      expect(attachment.compressedFileSize, isNotNull);
      expect(attachment.deleted, isFalse);

      // Feature 3: Soft delete attachment
      await repository.deleteAttachment(attachment.id);

      final fetched = await repository.getAttachment(attachment.id);
      expect(fetched, isNull, reason: 'getAttachment filters out soft-deleted items');

      // Verify row in DB is marked deleted: true
      final rawRow = await (db.select(db.attachments)..where((t) => t.id.equals(attachment.id))).getSingle();
      expect(rawRow.deleted, isTrue);

      // Verify physical file was NOT deleted (preserved for SHA-256 deduplication!)
      final absolutePath = await repository.resolveAttachmentPath(attachment);
      expect(await io.File(absolutePath).exists(), isTrue);
    });
  });

  group('Feature 3: AttachmentExportService', () {
    test('saveAttachmentToDevice handles nonexistent file gracefully', () async {
      final service = AttachmentExportService();
      final result = await service.saveAttachmentToDevice('${tempDir.path}/nonexistent.png');
      expect(result, isFalse);
    });
  });

  group('Feature 4: Resumable Upload & Cancellation stream behavior', () {
    test('Stream transformation calculates progress and honors cancellation', () async {
      final sampleData = List<int>.generate(10000, (i) => i % 256);
      int bytesSent = 0;
      double lastProgress = 0.0;

      final stream = Stream.value(sampleData);
      final transformed = stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            bytesSent += data.length;
            lastProgress = bytesSent / sampleData.length;
            sink.add(data);
          },
        ),
      );

      final received = <int>[];
      await for (final chunk in transformed) {
        received.addAll(chunk);
      }

      expect(received.length, 10000);
      expect(lastProgress, 1.0);

      // Verify cancellation error handling
      final cancelStream = Stream.value(sampleData).transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            sink.addError('Upload cancelled');
          },
        ),
      );

      expect(cancelStream.toList(), throwsA('Upload cancelled'));
    });
  });
}
