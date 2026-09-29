import '../../../../core/utils/result.dart';
import '../repositories/block_repository.dart';

class RestoreBlockUseCase {
  final BlockRepository _repository;

  RestoreBlockUseCase(this._repository);

  Future<Result<void>> call(String id, String data, String? parentBlockId, double position) async {
    return _repository.restoreBlock(id, data, parentBlockId, position);
  }
}
