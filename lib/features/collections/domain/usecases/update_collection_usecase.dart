import '../../../../core/utils/result.dart';
import '../entities/collection.dart';
import '../repositories/collection_repository.dart';

class UpdateCollectionUseCase {
  final CollectionRepository _repository;

  UpdateCollectionUseCase(this._repository);

  Future<Result<void>> call(Collection collection) {
    final updatedCollection = collection.copyWith(
      version: collection.version + 1,
    );
    return _repository.updateCollection(updatedCollection);
  }
}
