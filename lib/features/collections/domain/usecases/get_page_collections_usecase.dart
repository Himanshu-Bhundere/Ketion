import '../../../../core/utils/result.dart';
import '../entities/collection.dart';
import '../repositories/collection_repository.dart';

class GetPageCollectionsUseCase {
  final CollectionRepository _repository;

  GetPageCollectionsUseCase(this._repository);

  Future<Result<List<Collection>>> call(String pageId) {
    return _repository.getCollectionsForPage(pageId);
  }
}
