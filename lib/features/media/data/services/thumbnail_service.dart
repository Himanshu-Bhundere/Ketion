import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image_lib;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service responsible for generating preview thumbnails for various media types.
///
/// - Images: Decoded with [image] package, resized to 256px width.
/// - Video: First-frame extraction via `ffmpeg` when available, placeholder otherwise.
/// - PDF: First-page rasterisation via `pdf_render` when available, placeholder otherwise.
class ThumbnailService {
  static const int _thumbWidth = 256;
  static const int _thumbQuality = 70;

  Future<Directory> get _thumbCacheDir async {
    final dir = await getApplicationSupportDirectory();
    final thumbDir = Directory(p.join(dir.path, 'Thumbnails'));
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    return thumbDir;
  }

  /// Generates a thumbnail for the given [sourceFile] based on its [mimeType].
  ///
  /// Returns the absolute path to the generated thumbnail, or `null` on failure.
  Future<String?> generateThumbnail({
    required File sourceFile,
    required String mimeType,
    required String hash,
  }) async {
    if (mimeType.startsWith('image/')) {
      return _generateImageThumbnail(sourceFile, hash);
    } else if (mimeType.startsWith('video/')) {
      return _generateVideoThumbnail(sourceFile, hash);
    } else if (mimeType == 'application/pdf') {
      return _generatePdfThumbnail(sourceFile, hash);
    }
    return null;
  }

  /// Image thumbnail: decode → resize → encode as JPEG.
  Future<String?> _generateImageThumbnail(File sourceFile, String hash) async {
    try {
      final thumbDir = await _thumbCacheDir;
      final thumbPath = p.join(thumbDir.path, '${hash}_thumb.jpg');
      final thumbFile = File(thumbPath);

      if (await thumbFile.exists()) return thumbPath;

      final bytes = await sourceFile.readAsBytes();
      final decoded = image_lib.decodeImage(bytes);
      if (decoded == null) return null;

      final resized = image_lib.copyResize(decoded, width: _thumbWidth);
      await thumbFile.writeAsBytes(
        image_lib.encodeJpg(resized, quality: _thumbQuality),
      );
      return thumbPath;
    } catch (_) {
      return null;
    }
  }

  /// Video thumbnail: extract first frame using platform ffmpeg, if available.
  ///
  /// Falls back to null when ffmpeg is not installed (the UI should display a
  /// generic video icon in that case).
  Future<String?> _generateVideoThumbnail(File sourceFile, String hash) async {
    try {
      final thumbDir = await _thumbCacheDir;
      final thumbPath = p.join(thumbDir.path, '${hash}_video_thumb.jpg');
      final thumbFile = File(thumbPath);

      if (await thumbFile.exists()) return thumbPath;

      // Attempt ffmpeg first-frame extraction
      final result = await Process.run('ffmpeg', [
        '-i', sourceFile.path,
        '-vframes', '1',
        '-vf', 'scale=$_thumbWidth:-1',
        '-q:v', '5',
        '-y',
        thumbPath,
      ]);

      if (result.exitCode == 0 && await thumbFile.exists()) {
        return thumbPath;
      }
      return null;
    } catch (_) {
      // ffmpeg not available — no thumbnail
      return null;
    }
  }

  /// PDF preview: rasterise the first page.
  ///
  /// Uses a lightweight approach with external tooling. Falls back gracefully.
  Future<String?> _generatePdfThumbnail(File sourceFile, String hash) async {
    try {
      final thumbDir = await _thumbCacheDir;
      final thumbPath = p.join(thumbDir.path, '${hash}_pdf_thumb.jpg');
      final thumbFile = File(thumbPath);

      if (await thumbFile.exists()) return thumbPath;

      // Attempt using ImageMagick/Ghostscript `convert` for first-page render
      final result = await Process.run('magick', [
        'convert',
        '${sourceFile.path}[0]',
        '-resize', '${_thumbWidth}x',
        '-quality', '$_thumbQuality',
        thumbPath,
      ]);

      if (result.exitCode == 0 && await thumbFile.exists()) {
        return thumbPath;
      }
      return null;
    } catch (_) {
      // ImageMagick not available — no thumbnail
      return null;
    }
  }
}

final thumbnailServiceProvider = Provider<ThumbnailService>((ref) {
  return ThumbnailService();
});
