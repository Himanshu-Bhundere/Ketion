import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/file_utils.dart';
import '../entities/attachment.dart';
import '../repositories/attachment_repository.dart';

class SaveAttachmentUseCase {
  final AttachmentRepository _repository;

  SaveAttachmentUseCase(this._repository);

  Future<Result<Attachment>> call({
    required File file,
    required String mimeType,
  }) async {
    try {
      // 1. Calculate SHA-256
      final checksum = await FileUtils.calculateSha256(file);

      // 2. Check for deduplication
      final existingResult = await _repository.getAttachmentByChecksum(checksum);
      if (existingResult is Success<Attachment?> && existingResult.value != null) {
        return Success(existingResult.value!);
      }

      // 3. Setup new attachment
      final id = const Uuid().v7();
      final extension = p.extension(file.path);
      final fileName = '$id$extension';
      
      String subDir = 'Files';
      if (mimeType.startsWith('image/')) {
        subDir = 'Images';
      } else if (mimeType.startsWith('video/')) {
        subDir = 'Videos';
      } else if (mimeType.startsWith('audio/')) {
        subDir = 'Audio';
      } else if (mimeType == 'application/pdf') {
        subDir = 'PDFs';
      }

      // 4. Copy to local storage
      final localFile = await FileUtils.copyToLocalDirectory(file, subDir, fileName);
      final fileSize = await localFile.length();

      // 5. Generate thumbnail (if image)
      String? thumbnailPath;
      int? width;
      int? height;
      
      if (mimeType.startsWith('image/')) {
        final thumbnailFile = await FileUtils.generateThumbnail(localFile, '$id.jpg');
        thumbnailPath = thumbnailFile?.path;
        
        // Note: For full dimensions we'd ideally decode headers only, 
        // but image package decodes the whole image which we just did in generateThumbnail.
        // For optimization, we can live without precise dimensions for now, or use image package.
      }

      // 6. Create SQLite Metadata
      final attachment = Attachment(
        id: id,
        localPath: localFile.path,
        mimeType: mimeType,
        checksumSha256: checksum,
        fileSize: fileSize,
        width: width,
        height: height,
        thumbnailPath: thumbnailPath,
        uploadStatus: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      final saveResult = await _repository.saveAttachment(attachment);
      return saveResult;
    } catch (e) {
      return Error(StorageFailure('Failed to process and save attachment: $e'));
    }
  }
}
