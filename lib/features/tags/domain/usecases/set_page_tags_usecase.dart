import '../../../../core/utils/result.dart';
import '../repositories/tag_repository.dart';

class SetPageTagsUseCase {
  final TagRepository _repository;

  SetPageTagsUseCase(this._repository);

  Future<Result<void>> call(String pageId, List<String> tagIds) {
    return _repository.setPageTags(pageId, tagIds);
  }
}
