import '../../../../core/utils/result.dart';
import '../entities/block.dart';
import '../repositories/block_repository.dart';

class MergeBlocksUseCase {
  final BlockRepository _repository;

  MergeBlocksUseCase(this._repository);

  Future<Result<void>> call({
    required Block mergedBlock,
    required int survivorExpectedVersion,
    required String deletedBlockId,
    required int victimExpectedVersion,
  }) {
    return _repository.mergeBlocks(
      mergedBlock: mergedBlock,
      survivorExpectedVersion: survivorExpectedVersion,
      deletedBlockId: deletedBlockId,
      victimExpectedVersion: victimExpectedVersion,
    );
  }
}
