import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;

/// Service responsible for calculating checksums of files for deduplication.
class ChecksumService {
  /// Calculates the SHA-256 checksum of a file's contents.
  Future<String> calculateSha256(PlatformFile file) async {
    List<int> bytes;
    if (kIsWeb) {
      if (file.bytes == null) {
        throw UnsupportedError('File bytes are not available on web');
      }
      bytes = file.bytes!;
    } else {
      bytes = await io.File(file.path!).readAsBytes();
    }
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

final checksumServiceProvider = Provider<ChecksumService>((ref) {
  return ChecksumService();
});
