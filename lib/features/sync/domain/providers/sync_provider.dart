import 'package:ketion/core/utils/result.dart';

abstract class SyncProvider {
  /// The identifier of the provider, e.g. 'google_drive'
  String get providerId;

  /// Initialize the provider (e.g. create workspace, get folder IDs)
  Future<Result<void>> initialize(String accessToken);

  /// Upload an attachment to the remote storage
  Future<Result<String>> uploadAttachment(
    String localPath,
    String mimeType,
    String checksum,
  );

  /// Download an attachment from remote storage
  Future<Result<void>> downloadAttachment(
    String remoteFileId,
    String destinationPath,
  );

  /// Upload metadata/changes (in a batch)
  Future<Result<void>> uploadChanges(
    String batchId,
    Map<String, dynamic> payload,
  );

  /// Download unseen changes
  Future<Result<List<Map<String, dynamic>>>> downloadChanges(String? cursor);

  /// Get available storage information if applicable
  Future<Result<Map<String, dynamic>>> getAvailableStorage();
}
