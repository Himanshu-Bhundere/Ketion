import '../../../../core/utils/result.dart';
import '../repositories/tag_repository.dart';

class DeleteTagUseCase {
  final TagRepository _repository;

  DeleteTagUseCase(this._repository);

  Future<Result<void>> call(String id) {
    return _repository.deleteTag(id);
  }
}
