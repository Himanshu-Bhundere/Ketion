import 'dart:io' as io;
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class BackupService {
  Future<void> exportBackup() async {
    if (kIsWeb) {
      throw UnsupportedError('Backup export is not supported on the web');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final dbFile = io.File(p.join(appDir.path, 'ketion.sqlite'));
    final attachmentsDir = io.Directory(p.join(appDir.path, 'Attachments'));

    // Create a temporary directory for the zip
    final tempDir = await getTemporaryDirectory();
    final zipPath = p.join(
      tempDir.path,
      'ketion_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
    );

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    if (await dbFile.exists()) {
      await encoder.addFile(dbFile);
    }

    if (await attachmentsDir.exists()) {
      await encoder.addDirectory(attachmentsDir);
    }

    await encoder.close();

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zipPath, mimeType: 'application/zip')],
        text: 'Ketion Backup',
      ),
    );
  }

  Future<void> restoreBackup() async {
    if (kIsWeb) {
      throw UnsupportedError('Backup restore is not supported on the web');
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final zipFile = io.File(result.files.single.path!);
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    bool hasDb = false;
    for (final file in archive) {
      if (file.name == 'ketion.sqlite' ||
          file.name.endsWith('/ketion.sqlite')) {
        hasDb = true;
        break;
      }
    }

    if (!hasDb) {
      throw Exception('Invalid backup file: ketion.sqlite not found');
    }

    final appDir = await getApplicationDocumentsDirectory();

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = io.File(p.join(appDir.path, filename));
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(data);
      } else {
        await io.Directory(p.join(appDir.path, filename))
            .create(recursive: true);
      }
    }
  }
}
