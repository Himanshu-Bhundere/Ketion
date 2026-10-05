import '../../../../core/utils/result.dart';
import '../repositories/collection_repository.dart';

class SetPageCollectionsUseCase {
  final CollectionRepository _repository;

  SetPageCollectionsUseCase(this._repository);

  Future<Result<void>> call(String pageId, List<String> collectionIds) {
    return _repository.setPageCollections(pageId, collectionIds);
  }
}
