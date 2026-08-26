import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/domain/repositories/sync_engine_repository.dart';

class EnqueueSyncUseCase {
  final SyncEngineRepository repository;

  EnqueueSyncUseCase(this.repository);

  Future<Result<void>> call(String table, String entityId, String operation, {String? payload}) {
    return repository.enqueueOperation(table, entityId, operation, payload: payload);
  }
}
