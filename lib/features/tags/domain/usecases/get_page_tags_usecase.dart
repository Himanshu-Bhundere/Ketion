import '../../../../core/utils/result.dart';
import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

class GetPageTagsUseCase {
  final TagRepository _repository;

  GetPageTagsUseCase(this._repository);

  Future<Result<List<Tag>>> call(String pageId) {
    return _repository.getTagsForPage(pageId);
  }
}
