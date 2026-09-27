import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image_lib;

import 'checksum_service.dart';

/// Service responsible for managing attachment files on the local filesystem.
///
/// Uses content-addressable storage (SHA-256) for deduplication.
class AttachmentStorageService {
  final ChecksumService _checksumService;

  AttachmentStorageService(this._checksumService);

  Future<io.Directory> get _attachmentsDir async {
    final dir = await getApplicationSupportDirectory();
    final mediaDir = io.Directory(p.join(dir.path, 'Attachments'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// Saves a file to the managed attachments directory using its SHA-256 hash.
  ///
  /// The path format is `Attachments/<first_two_chars>/<hash>.<ext>`.
  /// Returns a tuple of (relativePath, optionalThumbnailRelativePath, hash).
  Future<(String, String?, String)> saveAttachment(PlatformFile sourceFile,
      {bool generateThumbnail = false}) async {
    if (kIsWeb) {
      throw UnsupportedError(
          'Local attachment storage is not supported on the web');
    }

    final mediaDir = await _attachmentsDir;
    final hash = await _checksumService.calculateSha256(sourceFile);

    final prefix = hash.substring(0, 2);
    final extension = sourceFile.extension != null
        ? '.${sourceFile.extension!.toLowerCase()}'
        : '';

    // e.g., Attachments/ab
    final prefixDir = io.Directory(p.join(mediaDir.path, prefix));
    if (!await prefixDir.exists()) {
      await prefixDir.create(recursive: true);
    }

    final fileName = '$hash$extension';
    final relativePath = p.join(prefix, fileName).replaceAll('\\', '/');
    final destinationPath = p.join(mediaDir.path, prefix, fileName);

    final destinationFile = io.File(destinationPath);

    if (!await destinationFile.exists()) {
      if (sourceFile.path != null) {
        await io.File(sourceFile.path!).copy(destinationPath);
      } else if (sourceFile.bytes != null) {
        await destinationFile.writeAsBytes(sourceFile.bytes!);
      } else {
        throw Exception('Cannot save file: neither path nor bytes available.');
      }
    }

    String? thumbnailRelativePath;
    if (generateThumbnail) {
      final thumbFileName = '${hash}_thumb.jpg';
      thumbnailRelativePath =
          p.join(prefix, thumbFileName).replaceAll('\\', '/');
      final thumbDestPath = p.join(mediaDir.path, prefix, thumbFileName);
      final thumbFile = io.File(thumbDestPath);

      if (!await thumbFile.exists()) {
        try {
          final bytes =
              sourceFile.bytes ?? await io.File(sourceFile.path!).readAsBytes();
          final image_lib.Image? image = image_lib.decodeImage(bytes);
          if (image != null) {
            final thumbnail = image_lib.copyResize(image, width: 256);
            await thumbFile
                .writeAsBytes(image_lib.encodeJpg(thumbnail, quality: 70));
          } else {
            thumbnailRelativePath = null;
          }
        } catch (e) {
          thumbnailRelativePath = null;
        }
      }
    }

    return (relativePath, thumbnailRelativePath, hash);
  }

  /// Retrieves a file from the managed directory given its relative path.
  Future<io.File?> getFile(String relativePath) async {
    if (kIsWeb) return null;
    final mediaDir = await _attachmentsDir;
    final path = p.join(mediaDir.path, relativePath);
    final file = io.File(path);

    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Deletes a file from the managed directory.
  Future<void> deleteFile(String relativePath) async {
    if (kIsWeb) return;
    final mediaDir = await _attachmentsDir;
    final path = p.join(mediaDir.path, relativePath);
    final file = io.File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Resolves an absolute path from a relative path for UI consumption.
  Future<String> resolvePath(String relativePath) async {
    if (kIsWeb) return relativePath;
    final mediaDir = await _attachmentsDir;
    return p.join(mediaDir.path, relativePath);
  }

  /// Performs garbage collection by deleting physical files that are not in the [validRelativePaths] set.
  Future<void> garbageCollect(Set<String> validRelativePaths) async {
    if (kIsWeb) return;
    final mediaDir = await _attachmentsDir;
    if (!await mediaDir.exists()) return;

    final entities = mediaDir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is io.File) {
        final relativePath = p.relative(entity.path, from: mediaDir.path);
        // Normalize path separators to forward slash for comparison
        final normalizedPath = relativePath.replaceAll('\\', '/');

        if (!validRelativePaths.contains(normalizedPath)) {
          try {
            await entity.delete();
          } catch (e) {
            // Ignore deletion errors (e.g. file locked)
          }
        }
      }
    }
  }
}

final attachmentStorageServiceProvider =
    Provider<AttachmentStorageService>((ref) {
  final checksumService = ref.watch(checksumServiceProvider);
  return AttachmentStorageService(checksumService);
});
