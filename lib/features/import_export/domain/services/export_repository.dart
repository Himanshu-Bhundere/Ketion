import 'dart:typed_data';
import 'package:ketion/features/import_export/domain/models/document_model.dart';

abstract class ExportRepository {
  /// Exports the given document and returns the bytes of the exported file.
  Future<Uint8List> exportDocument(ExportDocument document);

  /// The file extension produced by this exporter (e.g., 'md', 'html', 'pdf').
  String get fileExtension;
}
