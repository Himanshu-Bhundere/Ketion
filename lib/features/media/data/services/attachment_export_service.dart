import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

final attachmentExportServiceProvider = Provider<AttachmentExportService>((ref) {
  return AttachmentExportService();
});

class AttachmentExportService {
  /// Saves or exports an attachment file from its local cache path to the user's device/gallery.
  /// On Desktop (Windows/macOS/Linux), opens a native Save File dialog.
  /// On Mobile (Android/iOS), opens the system Share sheet allowing saving to Photos/Files.
  Future<bool> saveAttachmentToDevice(
    String localFilePath, {
    String? fileName,
  }) async {
    final file = io.File(localFilePath);
    if (!await file.exists()) {
      return false;
    }

    final name = fileName ?? p.basename(localFilePath);

    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    if (isDesktop) {
      try {
        final destinationPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save attachment to device',
          fileName: name,
        );

        if (destinationPath == null) {
          // User cancelled
          return false;
        }

        await file.copy(destinationPath);
        return true;
      } catch (e) {
        debugPrint('Failed to save attachment on desktop: $e');
        return false;
      }
    } else {
      // Mobile platform: use Share sheet allowing saving to Gallery/Photos/Files
      try {
        final result = await Share.shareXFiles(
          [XFile(localFilePath, name: name)],
          subject: name,
        );
        return result.status == ShareResultStatus.success;
      } catch (e) {
        debugPrint('Failed to export attachment on mobile: $e');
        return false;
      }
    }
  }
}
