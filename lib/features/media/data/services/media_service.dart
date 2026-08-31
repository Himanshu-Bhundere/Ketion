import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image_lib;

/// Service responsible for managing media files on the local filesystem.
///
/// Uses the Application Support Directory to prevent accidental user deletion
/// and to maintain offline-first architecture invariants.
class MediaService {
  Future<Directory> get _appSupportDir async {
    final dir = await getApplicationSupportDirectory();
    final mediaDir = Directory(p.join(dir.path, 'media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// Calculates the SHA-256 checksum of a file.
  Future<String> calculateSha256(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Saves a file to the application's managed media directory.
  ///
  /// Uses the file's SHA-256 hash to deduplicate files on disk.
  /// Returns a record with the relative path to the saved file and an optional relative thumbnail path.
  Future<(String, String?)> saveMedia(File sourceFile, {bool generateThumbnail = false}) async {
    final mediaDir = await _appSupportDir;
    final hash = await calculateSha256(sourceFile);

    final extension = p.extension(sourceFile.path);
    final relativePath = '$hash$extension';
    final destinationPath = p.join(mediaDir.path, relativePath);

    final destinationFile = File(destinationPath);

    if (!await destinationFile.exists()) {
      await sourceFile.copy(destinationPath);
    }

    String? thumbnailRelativePath;
    if (generateThumbnail) {
      final thumbHash = '${hash}_thumb';
      thumbnailRelativePath = '$thumbHash.jpg';
      final thumbDestPath = p.join(mediaDir.path, thumbnailRelativePath);
      final thumbFile = File(thumbDestPath);
      
      if (!await thumbFile.exists()) {
        try {
          final bytes = await sourceFile.readAsBytes();
          final image_lib.Image? image = image_lib.decodeImage(bytes);
          if (image != null) {
            final thumbnail = image_lib.copyResize(image, width: 256);
            await thumbFile.writeAsBytes(image_lib.encodeJpg(thumbnail, quality: 70));
          } else {
             thumbnailRelativePath = null;
          }
        } catch (e) {
          thumbnailRelativePath = null;
        }
      }
    }

    return (relativePath, thumbnailRelativePath);
  }

  /// Retrieves a file from the managed media directory given its relative path.
  Future<File?> getMedia(String relativePath) async {
    final mediaDir = await _appSupportDir;
    final path = p.join(mediaDir.path, relativePath);
    final file = File(path);

    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Deletes a file from the managed media directory.
  Future<void> deleteMedia(String relativePath) async {
    final mediaDir = await _appSupportDir;
    final path = p.join(mediaDir.path, relativePath);
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Resolves an absolute path from a relative path for UI consumption.
  Future<String> resolvePath(String relativePath) async {
    final mediaDir = await _appSupportDir;
    return p.join(mediaDir.path, relativePath);
  }
}

final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});
