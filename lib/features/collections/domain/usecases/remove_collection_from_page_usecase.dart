import '../../../../core/utils/result.dart';
import '../repositories/collection_repository.dart';

class RemoveCollectionFromPageUseCase {
  final CollectionRepository _repository;

  RemoveCollectionFromPageUseCase(this._repository);

  Future<Result<void>> call(String pageId, String collectionId) {
    return _repository.removeCollectionFromPage(pageId, collectionId);
  }
}
