import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/domain/repositories/sync_engine_repository.dart';
import 'package:ketion/features/media/domain/services/attachment_sync_service.dart';

class SyncNowUseCase {
  final SyncEngineRepository repository;
  final AttachmentSyncService attachmentSyncService;

  SyncNowUseCase(
    this.repository,
    this.attachmentSyncService,
  );

  Future<Result<void>> call() async {
    final result = await repository.syncNow();
    if (result is Success) {
      // Sync attachments after data sync succeeds
      await attachmentSyncService.syncPendingAttachments();
    }
    return result;
  }
}
