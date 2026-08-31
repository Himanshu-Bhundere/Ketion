import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:ketion/core/utils/logger.dart';

abstract class AttachmentLauncher {
  Future<void> launch(String filePath);
}

class OpenFileLauncher implements AttachmentLauncher {
  final AppLogger _logger;

  OpenFileLauncher(this._logger);

  @override
  Future<void> launch(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        _logger.e('Failed to open file $filePath: ${result.message}');
      }
    } catch (e, st) {
      _logger.e('Exception opening file $filePath', e, st);
    }
  }
}

final attachmentLauncherProvider = Provider<AttachmentLauncher>((ref) {
  return OpenFileLauncher(appLogger);
});
