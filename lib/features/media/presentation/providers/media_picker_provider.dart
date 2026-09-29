import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/attachment.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../../data/repositories/attachment_repository_impl.dart';

final mediaPickerProvider = Provider<MediaPickerService>((ref) {
  final repository = ref.watch(attachmentRepositoryProvider);
  return MediaPickerService(repository);
});

class MediaPickerService {
  final AttachmentRepository _repository;
  final ImagePicker _imagePicker = ImagePicker();

  MediaPickerService(this._repository);

  Future<Attachment?> pickImage({
    required String pageId,
    required String blockId,
    Future<bool> Function(int sizeInBytes)? onCheckSize,
  }) async {
    final xFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return null;

    final size = await xFile.length();

    if (onCheckSize != null) {
      final shouldProceed = await onCheckSize(size);
      if (!shouldProceed) return null;
    }

    try {
      final platformFile = PlatformFile(
        name: xFile.name,
        size: size,
        path: xFile.path,
        bytes: kIsWeb ? await xFile.readAsBytes() : null,
      );

      final attachment = await _repository.saveAttachment(
        pageId: pageId,
        blockId: blockId,
        sourceFile: platformFile,
        mimeType: 'image/jpeg',
      );
      return attachment;
    } catch (e) {
      return null;
    }
  }

  Future<Attachment?> pickFile({
    required String pageId,
    required String blockId,
    Future<bool> Function(int sizeInBytes)? onCheckSize,
  }) async {
    final result = await FilePicker.platform.pickFiles(withData: kIsWeb);
    if (result == null || result.files.isEmpty) return null;

    final platformFile = result.files.single;
    final size = platformFile.size;

    if (onCheckSize != null) {
      final shouldProceed = await onCheckSize(size);
      if (!shouldProceed) return null;
    }

    try {
      // Improved mimeType detection (rudimentary)
      String mimeType = 'application/octet-stream';
      final extension = platformFile.extension ??
          platformFile.name.split('.').last.toLowerCase();
      if (['mp4', 'mov', 'avi'].contains(extension)) {
        mimeType = 'video/$extension';
      }
      if (['mp3', 'wav', 'm4a'].contains(extension)) {
        mimeType = 'audio/$extension';
      }
      if (extension == 'pdf') mimeType = 'application/pdf';

      final attachment = await _repository.saveAttachment(
        pageId: pageId,
        blockId: blockId,
        sourceFile: platformFile,
        mimeType: mimeType,
      );
      return attachment;
    } catch (e) {
      return null;
    }
  }
}
