import 'dart:typed_data';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart' as ip;
import 'file_picker_service.dart';

class FilePickerServiceImpl implements FilePickerService {
  final ip.ImagePicker _imagePicker = ip.ImagePicker();

  @override
  Future<List<PickedFile>> pickFiles({bool allowMultiple = false, List<String>? allowedExtensions}) async {
    final result = await fp.FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: allowedExtensions != null ? fp.FileType.custom : fp.FileType.any,
      allowedExtensions: allowedExtensions,
      withData: true, // Need bytes especially for web
    );

    if (result == null) return [];

    return result.files.map((file) {
      return PickedFile(
        name: file.name,
        bytes: file.bytes ?? Uint8List(0),
      );
    }).toList();
  }

  @override
  Future<PickedFile?> pickImage() async {
    final result = await _imagePicker.pickImage(source: ip.ImageSource.gallery);
    if (result == null) return null;

    final bytes = await result.readAsBytes();
    return PickedFile(
      name: result.name,
      bytes: bytes,
    );
  }
}
