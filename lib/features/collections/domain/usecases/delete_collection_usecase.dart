import '../../../../core/utils/result.dart';
import '../repositories/collection_repository.dart';

class DeleteCollectionUseCase {
  final CollectionRepository _repository;

  DeleteCollectionUseCase(this._repository);

  Future<Result<void>> call(String id) {
    return _repository.deleteCollection(id);
  }
}
