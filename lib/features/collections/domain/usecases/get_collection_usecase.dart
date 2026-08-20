import '../../../../core/utils/result.dart';
import '../entities/collection.dart';
import '../repositories/collection_repository.dart';

class GetCollectionUseCase {
  final CollectionRepository _repository;

  GetCollectionUseCase(this._repository);

  Future<Result<Collection>> call(String id) {
    return _repository.getCollection(id);
  }
}
