import '../../../../core/utils/result.dart';
import '../repositories/page_repository.dart';

class DeletePageUseCase {
  final PageRepository _repository;

  DeletePageUseCase(this._repository);

  Future<Result<void>> call(String id) {
    return _repository.deletePage(id);
  }
}
