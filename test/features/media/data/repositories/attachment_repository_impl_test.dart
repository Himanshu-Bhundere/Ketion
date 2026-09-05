import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/media/data/repositories/attachment_repository_impl.dart';
import 'package:ketion/features/media/data/services/media_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart' as p;

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
  late MediaService mediaService;
  late AttachmentRepositoryImpl repository;
  late Directory tempDir;
  late File testFile;

  setUp(() async {
    // In-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());

    // Mock file system for MediaService
    tempDir = await Directory.systemTemp.createTemp('attachment_repo_test');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    mediaService = MediaService();
    repository = AttachmentRepositoryImpl(database, mediaService);

    testFile = File(p.join(tempDir.path, 'test_image.png'));
    await testFile.writeAsString('fake image content');
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saveAttachment saves file to media service and metadata to DB',
      () async {
    final attachment = await repository.saveAttachment(
      pageId: 'page-1',
      blockId: 'block-1',
      sourceFile: testFile,
      mimeType: 'image/png',
    );

    expect(attachment.id, isNotEmpty);
    expect(attachment.pageId, 'page-1');
    expect(attachment.blockId, 'block-1');
    expect(attachment.fileName, 'test_image.png');
    expect(attachment.mimeType, 'image/png');
    expect(attachment.relativePath, isNotEmpty);
    expect(attachment.deleted, isFalse);

    // Verify it's in the DB
    final savedAttachment = await repository.getAttachment(attachment.id);
    expect(savedAttachment, isNotNull);
    expect(savedAttachment?.id, attachment.id);

    // Verify file exists in media service
    final resolvedPath = await repository.resolveAttachmentPath(attachment);
    expect(await File(resolvedPath).exists(), isTrue);
  });

  test('getAttachmentsForPage returns only non-deleted attachments', () async {
    await repository.saveAttachment(
      pageId: 'page-1',
      blockId: 'block-1',
      sourceFile: testFile,
      mimeType: 'image/png',
    );

    final att2 = await repository.saveAttachment(
      pageId: 'page-1',
      blockId: 'block-2',
      sourceFile: testFile,
      mimeType: 'image/png',
    );

    var attachments = await repository.getAttachmentsForPage('page-1');
    expect(attachments.length, 2);

    // Delete one
    await repository.deleteAttachment(att2.id);

    attachments = await repository.getAttachmentsForPage('page-1');
    expect(attachments.length, 1);
    expect(attachments.first.blockId, 'block-1');
  });

  test('getAttachment returns null for deleted attachment', () async {
    final attachment = await repository.saveAttachment(
      pageId: 'page-1',
      blockId: 'block-1',
      sourceFile: testFile,
      mimeType: 'image/png',
    );

    await repository.deleteAttachment(attachment.id);

    final retrieved = await repository.getAttachment(attachment.id);
    expect(retrieved, isNull);
  });
}
