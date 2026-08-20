import '../../../../core/utils/result.dart';
import '../entities/page.dart';
import '../repositories/page_repository.dart';

class UpdatePageUseCase {
  final PageRepository _repository;

  UpdatePageUseCase(this._repository);

  Future<Result<void>> call(Page page) {
    final updatedPage = page.copyWith(
      updatedAt: DateTime.now(),
      version: page.version + 1,
    );
    return _repository.updatePage(updatedPage);
  }
}
