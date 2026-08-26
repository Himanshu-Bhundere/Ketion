import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/domain/repositories/sync_engine_repository.dart';

class SyncNowUseCase {
  final SyncEngineRepository repository;

  SyncNowUseCase(this.repository);

  Future<Result<void>> call() {
    return repository.syncNow();
  }
}
