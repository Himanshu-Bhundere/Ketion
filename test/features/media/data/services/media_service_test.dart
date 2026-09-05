import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/media/data/services/media_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart' as p;

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
  late MediaService mediaService;
  late Directory tempDir;
  late File sourceFile1;
  late File sourceFile2; // Same content as sourceFile1
  late File sourceFile3; // Different content

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('media_service_test');

    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);
    mediaService = MediaService();

    sourceFile1 = File(p.join(tempDir.path, 'source1.txt'));
    await sourceFile1.writeAsString('hello world');

    sourceFile2 = File(p.join(tempDir.path, 'source2.txt'));
    await sourceFile2.writeAsString('hello world');

    sourceFile3 = File(p.join(tempDir.path, 'source3.txt'));
    await sourceFile3.writeAsString('goodbye world');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saveMedia calculates SHA-256 and copies file', () async {
    final relativePath = (await mediaService.saveMedia(sourceFile1)).$1;

    // b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9 is SHA-256 for 'hello world'
    expect(
      relativePath,
      contains(
        'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9',
      ),
    );
    expect(relativePath, endsWith('.txt'));

    final savedFile = await mediaService.getMedia(relativePath);
    expect(savedFile, isNotNull);
    expect(await savedFile!.readAsString(), 'hello world');
  });

  test('saveMedia deduplicates identical files based on SHA-256', () async {
    final relativePath1 = (await mediaService.saveMedia(sourceFile1)).$1;
    final relativePath2 = (await mediaService.saveMedia(sourceFile2)).$1;

    expect(relativePath1, relativePath2); // Identical paths since hashes match

    // Check that there is only one file in the media directory
    final mediaDir = Directory(p.join(tempDir.path, 'media'));
    final files = await mediaDir.list().toList();
    expect(files.length, 1);
  });

  test('saveMedia creates separate files for different content', () async {
    final relativePath1 = (await mediaService.saveMedia(sourceFile1)).$1;
    final relativePath3 = (await mediaService.saveMedia(sourceFile3)).$1;

    expect(relativePath1, isNot(equals(relativePath3)));

    final mediaDir = Directory(p.join(tempDir.path, 'media'));
    final files = await mediaDir.list().toList();
    expect(files.length, 2);
  });

  test('resolvePath returns absolute path in Application Support Directory',
      () async {
    final relativePath = (await mediaService.saveMedia(sourceFile1)).$1;
    final absolutePath = await mediaService.resolvePath(relativePath);

    expect(absolutePath, startsWith(tempDir.path));
    expect(absolutePath, endsWith(relativePath));
    expect(await File(absolutePath).exists(), isTrue);
  });

  test('deleteMedia removes the file', () async {
    final relativePath = (await mediaService.saveMedia(sourceFile1)).$1;
    expect(await (await mediaService.getMedia(relativePath))?.exists(), isTrue);

    await mediaService.deleteMedia(relativePath);

    expect(await mediaService.getMedia(relativePath), isNull);
  });
}
