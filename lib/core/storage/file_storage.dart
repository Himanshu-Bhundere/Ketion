import 'dart:typed_data';

abstract class FileStorage {
  /// Save bytes to a relative path
  Future<String> saveFile(String relativePath, Uint8List bytes);

  /// Read bytes from a relative path
  Future<Uint8List?> readFile(String relativePath);

  /// Delete a file at a relative path
  Future<void> deleteFile(String relativePath);

  /// Check if a file exists
  Future<bool> fileExists(String relativePath);

  /// Get a hash (SHA256) of a file's content
  Future<String> calculateHash(String relativePath);

  /// Generate a thumbnail for an image file
  Future<String?> generateThumbnail(String relativePath);
}
