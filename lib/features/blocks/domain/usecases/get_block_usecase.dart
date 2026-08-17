import '../../../../core/utils/result.dart';
import '../entities/block.dart';
import '../repositories/block_repository.dart';

class GetBlockUseCase {
  final BlockRepository _repository;

  GetBlockUseCase(this._repository);

  Future<Result<Block>> call(String id) {
    return _repository.getBlock(id);
  }
}
