import '../../../../core/utils/result.dart';
import '../entities/block.dart';
import '../repositories/block_repository.dart';

class SplitBlockUseCase {
  final BlockRepository _repository;

  SplitBlockUseCase(this._repository);

  Future<Result<void>> call({
    required Block updatedOriginalBlock,
    required int originalExpectedVersion,
    required Block newBlock,
  }) {
    return _repository.splitBlock(
      updatedOriginalBlock: updatedOriginalBlock,
      originalExpectedVersion: originalExpectedVersion,
      newBlock: newBlock,
    );
  }
}
