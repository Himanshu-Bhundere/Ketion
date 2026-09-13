import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/services/file_picker_service.dart';
import 'package:ketion/core/services/file_picker_service_factory.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/features/import_export/domain/services/export_repository.dart';
import 'package:ketion/features/import_export/domain/services/html_exporter.dart';
import 'package:ketion/features/import_export/domain/services/import_service.dart';
import 'package:ketion/features/import_export/domain/services/markdown_exporter.dart';
import 'package:ketion/features/import_export/domain/services/pdf_exporter.dart';
import 'package:ketion/features/import_export/domain/usecases/export_usecase.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';

final exportRepositoriesProvider = Provider<List<ExportRepository>>((ref) {
  return [
    MarkdownExporter(),
    HtmlExporter(),
    PdfExporter(),
  ];
});

final exportUseCaseProvider = Provider<ExportUseCase>((ref) {
  return ExportUseCase(ref.watch(exportRepositoriesProvider));
});

final filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return getFilePickerService();
});

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(
    ref.watch(createPageUseCaseProvider),
    ref.watch(createBlockUseCaseProvider),
    ref.watch(filePickerServiceProvider),
  );
});
