import '../../../../core/utils/result.dart';
import '../entities/block.dart';
import '../repositories/block_repository.dart';

class UpdateBlockUseCase {
  final BlockRepository _repository;

  UpdateBlockUseCase(this._repository);

  Future<Result<void>> call(Block block) {
    final updatedBlock = block.copyWith(
      updatedAt: DateTime.now(),
      version: block.version + 1,
    );
    return _repository.updateBlock(updatedBlock);
  }
}
