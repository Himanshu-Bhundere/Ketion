import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'file_storage.dart';

class NativeFileStorage implements FileStorage {
  Future<Directory> _getBaseDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDir.path, 'KetionStorage'));
  }

  @override
  Future<String> saveFile(String relativePath, Uint8List bytes) async {
    final baseDir = await _getBaseDir();
    final file = File(p.join(baseDir.path, relativePath));
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes);
    return relativePath;
  }

  @override
  Future<Uint8List?> readFile(String relativePath) async {
    final baseDir = await _getBaseDir();
    final file = File(p.join(baseDir.path, relativePath));
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  @override
  Future<void> deleteFile(String relativePath) async {
    final baseDir = await _getBaseDir();
    final file = File(p.join(baseDir.path, relativePath));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> fileExists(String relativePath) async {
    final baseDir = await _getBaseDir();
    final file = File(p.join(baseDir.path, relativePath));
    return await file.exists();
  }

  @override
  Future<String> calculateHash(String relativePath) async {
    final baseDir = await _getBaseDir();
    final file = File(p.join(baseDir.path, relativePath));
    if (!await file.exists()) return '';
    final stream = file.openRead();
    final hash = await sha256.bind(stream).first;
    return hash.toString();
  }

  @override
  Future<String?> generateThumbnail(String relativePath) async {
    final bytes = await readFile(relativePath);
    if (bytes == null) return null;
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final thumbnail = img.copyResize(image, width: 320);
    final thumbPath = p.join('Thumbnails', relativePath);
    await saveFile(thumbPath, img.encodeJpg(thumbnail, quality: 85));
    return thumbPath;
  }
}

FileStorage getFileStorage() => NativeFileStorage();
