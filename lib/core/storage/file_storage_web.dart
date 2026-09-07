import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'file_storage.dart';

class WebFileStorage implements FileStorage {
  // Simple in-memory storage for Web in Phase 1
  // Can be upgraded to IndexedDB later.
  final Map<String, Uint8List> _storage = {};

  @override
  Future<String> saveFile(String relativePath, Uint8List bytes) async {
    _storage[relativePath] = bytes;
    return relativePath;
  }

  @override
  Future<Uint8List?> readFile(String relativePath) async {
    return _storage[relativePath];
  }

  @override
  Future<void> deleteFile(String relativePath) async {
    _storage.remove(relativePath);
  }

  @override
  Future<bool> fileExists(String relativePath) async {
    return _storage.containsKey(relativePath);
  }

  @override
  Future<String> calculateHash(String relativePath) async {
    final bytes = _storage[relativePath];
    if (bytes == null) return '';
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  @override
  Future<String?> generateThumbnail(String relativePath) async {
    final bytes = await readFile(relativePath);
    if (bytes == null) return null;
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final thumbnail = img.copyResize(image, width: 320);
    final thumbPath = 'Thumbnails/$relativePath';
    await saveFile(thumbPath, img.encodeJpg(thumbnail, quality: 85));
    return thumbPath;
  }
}

FileStorage getFileStorage() => WebFileStorage();
