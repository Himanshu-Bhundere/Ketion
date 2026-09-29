import '../../../../core/utils/result.dart';
import '../entities/block.dart';
import '../repositories/block_repository.dart';

class UpdateBlockUseCase {
  final BlockRepository _repository;

  UpdateBlockUseCase(this._repository);

  /// The repository transaction is the sole authority for block versions and
  /// timestamps, so callers can safely submit a stale editor model.
  Future<Result<void>> call(Block block) => _repository.updateBlock(block, expectedVersion: block.version);
}
