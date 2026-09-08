import 'dart:convert';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/data/utils/drive_constants.dart';
import 'package:ketion/features/sync/domain/providers/sync_provider.dart';

class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GoogleDriveSyncProvider implements SyncProvider {
  drive.DriveApi? _driveApi;
  String? _rootFolderId;
  String? _syncFolderId;
  String? _attachmentsFolderId;

  @override
  String get providerId => 'google_drive';

  @override
  Future<Result<void>> initialize(String accessToken) async {
    try {
      final authClient = _AuthenticatedClient({
        'Authorization': 'Bearer $accessToken',
      });
      _driveApi = drive.DriveApi(authClient);

      // Locate or create Root Folder
      _rootFolderId =
          await _getOrCreateFolder(DriveConstants.rootFolder, 'root');
      if (_rootFolderId == null) {
        return const Error(
          SyncFailure('Failed to locate or create root folder on Drive'),
        );
      }

      // Locate or create Database/Sync Folder
      _syncFolderId = await _getOrCreateFolder(
        DriveConstants.databaseFolder,
        _rootFolderId!,
      );

      // Locate or create Attachments Folder
      _attachmentsFolderId = await _getOrCreateFolder(
        DriveConstants.attachmentsFolder,
        _rootFolderId!,
      );

      return const Success(null);
    } catch (e) {
      return Error(SyncFailure('Google Drive initialization error: $e'));
    }
  }

  Future<String?> _getOrCreateFolder(String folderName, String parentId) async {
    if (_driveApi == null) return null;
    try {
      final q =
          "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and '$parentId' in parents and trashed = false";
      final list = await _driveApi!.files.list(q: q);
      if (list.files != null && list.files!.isNotEmpty) {
        return list.files!.first.id;
      }

      final folderMetadata = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [parentId];

      final createdFolder = await _driveApi!.files.create(folderMetadata);
      return createdFolder.id;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Result<String>> uploadAttachment(
    String localPath,
    String mimeType,
    String checksum,
  ) async {
    if (_driveApi == null || _attachmentsFolderId == null) {
      return const Error(SyncFailure('Drive API not initialized'));
    }
    try {
      // 1. Check if an attachment with this checksum already exists
      final q = "'$_attachmentsFolderId' in parents and appProperties has { key='checksum' and value='$checksum' } and trashed = false";
      final fileList = await _driveApi!.files.list(q: q);
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return Success(fileList.files!.first.id ?? '');
      }

      final file = File(localPath);
      if (!await file.exists()) {
        return const Error(SyncFailure('Local file does not exist'));
      }

      final fileName = file.uri.pathSegments.last;
      final media = drive.Media(file.openRead(), await file.length());
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [_attachmentsFolderId!]
        ..appProperties = {'checksum': checksum};

      final uploaded = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      return Success(uploaded.id ?? '');
    } catch (e) {
      return Error(SyncFailure('Failed to upload attachment: $e'));
    }
  }

  @override
  Future<Result<void>> downloadAttachment(
    String remoteFileId,
    String destinationPath,
  ) async {
    if (_driveApi == null) {
      return const Error(SyncFailure('Drive API not initialized'));
    }
    try {
      final drive.Media media = await _driveApi!.files.get(
        remoteFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final file = File(destinationPath);
      final sink = file.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      return const Success(null);
    } catch (e) {
      return Error(SyncFailure('Failed to download attachment: $e'));
    }
  }

  Future<int> _incrementAndGetGeneration() async {
    final folder = await _driveApi!.files.get(
      _syncFolderId!,
      $fields: 'appProperties',
    ) as drive.File;
    
    int currentGen = 0;
    if (folder.appProperties != null && folder.appProperties!['generation'] != null) {
      currentGen = int.tryParse(folder.appProperties!['generation']!) ?? 0;
    }
    
    int nextGen = currentGen + 1;
    
    final updateMetadata = drive.File()
      ..appProperties = {'generation': nextGen.toString()};
    await _driveApi!.files.update(updateMetadata, _syncFolderId!);
    
    return nextGen;
  }

  @override
  Future<Result<void>> uploadChanges(
    String batchId,
    Map<String, dynamic> payload,
  ) async {
    if (_driveApi == null || _syncFolderId == null) {
      return const Error(SyncFailure('Drive API not initialized'));
    }
    try {
      final generation = await _incrementAndGetGeneration();
      final genString = generation.toString().padLeft(10, '0');
      
      final content = jsonEncode(payload);
      final bytes = utf8.encode(content);
      final stream = Stream.value(bytes);
      final media = drive.Media(stream, bytes.length);

      final driveFile = drive.File()
        ..name = 'gen_$genString.json'
        ..parents = [_syncFolderId!];

      await _driveApi!.files.create(driveFile, uploadMedia: media);
      return const Success(null);
    } catch (e) {
      return Error(SyncFailure('Failed to upload batch changes: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> downloadChanges(
    String? cursor,
  ) async {
    if (_driveApi == null || _syncFolderId == null) {
      return const Error(SyncFailure('Drive API not initialized'));
    }
    try {
      int currentCursor = int.tryParse(cursor ?? '0') ?? 0;
      final q =
          "'$_syncFolderId' in parents and mimeType = 'application/json' and trashed = false";
      // We sort by name client-side as Drive's orderBy='name' can be flaky, but we'll try to request it anyway
      final fileList = await _driveApi!.files.list(q: q, orderBy: 'name');

      final results = <Map<String, dynamic>>[];
      if (fileList.files != null) {
        // Sort explicitly just in case
        final files = fileList.files!.where((f) => f.name?.startsWith('gen_') ?? false).toList();
        files.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

        for (final file in files) {
          if (file.id == null || file.name == null) continue;
          
          final match = RegExp(r'gen_(\d+)\.json').firstMatch(file.name!);
          if (match == null) continue;
          final fileGen = int.parse(match.group(1)!);
          
          if (fileGen > currentCursor) {
            final drive.Media media = await _driveApi!.files.get(
              file.id!,
              downloadOptions: drive.DownloadOptions.fullMedia,
            ) as drive.Media;

            final contentBytes = await media.stream.fold<List<int>>(
              [],
              (previous, element) => previous..addAll(element),
            );
            final contentString = utf8.decode(contentBytes);
            final data = jsonDecode(contentString) as Map<String, dynamic>;
            
            final changes = data['changes'] as List<dynamic>? ?? [];
            for (final change in changes) {
              if (change is Map<String, dynamic>) {
                change['batchId'] = fileGen.toString();
                results.add(change);
              }
            }
          }
        }
      }

      return Success(results);
    } catch (e) {
      return Error(SyncFailure('Failed to download changes: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getAvailableStorage() async {
    if (_driveApi == null) {
      return const Error(SyncFailure('Drive API not initialized'));
    }
    try {
      final about = await _driveApi!.about.get($fields: 'storageQuota');
      final quota = about.storageQuota;
      return Success({
        'limit': quota?.limit,
        'usage': quota?.usage,
        'usageInDrive': quota?.usageInDrive,
      });
    } catch (e) {
      return Error(SyncFailure('Failed to fetch storage info: $e'));
    }
  }
}
