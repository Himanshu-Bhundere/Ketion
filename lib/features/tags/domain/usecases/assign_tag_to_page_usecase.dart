import '../../../../core/utils/result.dart';
import '../repositories/tag_repository.dart';

class AssignTagToPageUseCase {
  final TagRepository _repository;

  AssignTagToPageUseCase(this._repository);

  Future<Result<void>> call(String pageId, String tagId) {
    return _repository.assignTagToPage(pageId, tagId);
  }
}
