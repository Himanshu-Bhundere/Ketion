import '../../../../core/utils/result.dart';
import '../repositories/tag_repository.dart';

class RemoveTagFromPageUseCase {
  final TagRepository _repository;

  RemoveTagFromPageUseCase(this._repository);

  Future<Result<void>> call(String pageId, String tagId) {
    return _repository.removeTagFromPage(pageId, tagId);
  }
}
