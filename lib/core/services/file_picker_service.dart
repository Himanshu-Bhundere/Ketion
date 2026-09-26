import 'dart:typed_data';

class PickedFile {
  final String name;
  final Uint8List bytes;

  PickedFile({required this.name, required this.bytes});
}

abstract class FilePickerService {
  Future<List<PickedFile>> pickFiles(
      {bool allowMultiple = false, List<String>? allowedExtensions});
  Future<PickedFile?> pickImage();
}
