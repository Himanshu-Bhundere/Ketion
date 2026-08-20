import '../../../../core/utils/result.dart';
import '../entities/page.dart';
import '../repositories/page_repository.dart';

class GetPageUseCase {
  final PageRepository _repository;

  GetPageUseCase(this._repository);

  Future<Result<Page>> call(String id) {
    return _repository.getPage(id);
  }
}
