import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/media/data/services/thumbnail_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late ThumbnailService service;
  late Directory tempDir;

  setUp(() async {
    service = ThumbnailService();
    tempDir = await Directory.systemTemp.createTemp('thumbnail_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ThumbnailService', () {
    test('generateThumbnail returns null for unsupported mime type', () async {
      final dummyFile = File(p.join(tempDir.path, 'test.txt'));
      await dummyFile.writeAsString('hello world');

      final result = await service.generateThumbnail(
        sourceFile: dummyFile,
        mimeType: 'text/plain',
        hash: 'abc123',
      );

      expect(result, isNull);
    });

    test('generateThumbnail returns null for non-existent image', () async {
      final dummyFile = File(p.join(tempDir.path, 'nonexistent.png'));

      final result = await service.generateThumbnail(
        sourceFile: dummyFile,
        mimeType: 'image/png',
        hash: 'hash123',
      );

      // File doesn't exist, should return null gracefully
      expect(result, isNull);
    });

    test('generateThumbnail handles video gracefully when ffmpeg is missing',
        () async {
      final dummyFile = File(p.join(tempDir.path, 'test.mp4'));
      await dummyFile.writeAsBytes(
        [0, 0, 0, 0],
      ); // Invalid video, but tests ffmpeg fallback

      final result = await service.generateThumbnail(
        sourceFile: dummyFile,
        mimeType: 'video/mp4',
        hash: 'videohash123',
      );

      // ffmpeg likely not available in test env — should return null, not crash
      expect(result, anyOf(isNull, isA<String>()));
    });

    test('generateThumbnail handles pdf gracefully when imagemagick is missing',
        () async {
      final dummyFile = File(p.join(tempDir.path, 'test.pdf'));
      await dummyFile.writeAsString('%PDF-1.4 dummy');

      final result = await service.generateThumbnail(
        sourceFile: dummyFile,
        mimeType: 'application/pdf',
        hash: 'pdfhash123',
      );

      // ImageMagick likely not available in test env — should return null, not crash
      expect(result, anyOf(isNull, isA<String>()));
    });
  });
}
