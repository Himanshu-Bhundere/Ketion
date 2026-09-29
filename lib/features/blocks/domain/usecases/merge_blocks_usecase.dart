import '../../../../core/utils/result.dart';
import '../entities/block.dart';
import '../repositories/block_repository.dart';

class MergeBlocksUseCase {
  final BlockRepository _repository;

  MergeBlocksUseCase(this._repository);

  Future<Result<void>> call({
    required Block mergedBlock,
    required String deletedBlockId,
  }) {
    return _repository.mergeBlocks(
      mergedBlock: mergedBlock,
      deletedBlockId: deletedBlockId,
    );
  }
}
