import '../../../../core/utils/result.dart';
import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

class GetTagUseCase {
  final TagRepository _repository;

  GetTagUseCase(this._repository);

  Future<Result<Tag>> call(String id) {
    return _repository.getTag(id);
  }
}
