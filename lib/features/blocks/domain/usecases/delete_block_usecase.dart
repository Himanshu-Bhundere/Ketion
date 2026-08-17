import '../../../../core/utils/result.dart';
import '../repositories/block_repository.dart';

class DeleteBlockUseCase {
  final BlockRepository _repository;

  DeleteBlockUseCase(this._repository);

  Future<Result<void>> call(String id) {
    return _repository.deleteBlock(id);
  }
}
