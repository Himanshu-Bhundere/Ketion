import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/collection.dart';
import '../repositories/collection_repository.dart';

class CreateCollectionUseCase {
  final CollectionRepository _repository;
  final Uuid _uuid;

  CreateCollectionUseCase(this._repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<Result<Collection>> call({
    required String name,
    String? icon,
    String? color,
  }) async {
    final collection = Collection(
      id: _uuid.v7(),
      name: name,
      icon: icon,
      color: color,
    );
    
    final result = await _repository.createCollection(collection);
    return result.fold(
      (_) => Success(collection),
      (Failure failure) => Error(failure),
    );
  }
}
