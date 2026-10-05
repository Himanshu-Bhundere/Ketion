import '../../../../core/utils/result.dart';
import '../repositories/collection_repository.dart';

class AssignCollectionToPageUseCase {
  final CollectionRepository _repository;

  AssignCollectionToPageUseCase(this._repository);

  Future<Result<void>> call(String pageId, String collectionId) {
    return _repository.assignCollectionToPage(pageId, collectionId);
  }
}
