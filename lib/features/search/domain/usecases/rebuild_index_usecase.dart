import '../../../../core/utils/result.dart';
import '../repositories/search_repository.dart';

class RebuildIndexUseCase {
  final SearchRepository _repository;

  RebuildIndexUseCase(this._repository);

  Future<Result<void>> call() async {
    return _repository.rebuildIndex();
  }
}
