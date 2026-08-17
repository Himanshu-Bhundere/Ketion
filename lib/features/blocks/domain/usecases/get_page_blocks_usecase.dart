import '../../../../core/utils/result.dart';
import '../entities/block.dart';
import '../repositories/block_repository.dart';

class GetPageBlocksUseCase {
  final BlockRepository _repository;

  GetPageBlocksUseCase(this._repository);

  Future<Result<List<Block>>> call(String pageId) {
    return _repository.getBlocksForPage(pageId);
  }
}
