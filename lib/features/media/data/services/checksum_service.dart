import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service responsible for calculating checksums of files for deduplication.
class ChecksumService {
  /// Calculates the SHA-256 checksum of a file's contents.
  Future<String> calculateSha256(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

final checksumServiceProvider = Provider<ChecksumService>((ref) {
  return ChecksumService();
});
