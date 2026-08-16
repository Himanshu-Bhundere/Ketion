import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

class FileUtils {
  static Future<String> calculateSha256(File file) async {
    final stream = file.openRead();
    final hash = await sha256.bind(stream).first;
    return hash.toString();
  }

  static Future<File> copyToLocalDirectory(File source, String subDir, String newFileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(appDir.path, 'Attachments', subDir));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final targetPath = p.join(targetDir.path, newFileName);
    return await source.copy(targetPath);
  }

  static Future<File?> generateThumbnail(File source, String newFileName) async {
    final bytes = await source.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final thumbnail = img.copyResize(image, width: 320); // Resize width to 320px
    
    final appDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(appDir.path, 'Attachments', 'Thumbnails'));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    
    final targetPath = p.join(targetDir.path, newFileName);
    final thumbnailFile = File(targetPath);
    await thumbnailFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 85));
    
    return thumbnailFile;
  }
}
