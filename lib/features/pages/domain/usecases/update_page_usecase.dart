import '../../../../core/utils/result.dart';
import '../entities/page.dart';
import '../repositories/page_repository.dart';

class UpdatePageUseCase {
  final PageRepository _repository;

  UpdatePageUseCase(this._repository);

  Future<Result<void>> call(Page page) async {
    // The repository transaction owns the authoritative timestamp and version.
    // Callers can safely submit a stale page model without creating a competing
    // versioning policy in the presentation/application layers.
    return await _repository.updatePage(page);
  }
}
