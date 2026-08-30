import '../../../../core/utils/result.dart';
import 'package:ketion/features/widgets/domain/usecases/update_widgets_usecase.dart';
import '../entities/page.dart';
import '../repositories/page_repository.dart';

class UpdatePageUseCase {
  final PageRepository _repository;
  final UpdateWidgetsUseCase _updateWidgetsUseCase;

  UpdatePageUseCase(this._repository, this._updateWidgetsUseCase);

  Future<Result<void>> call(Page page) async {
    // The repository transaction owns the authoritative timestamp and version.
    // Callers can safely submit a stale page model without creating a competing
    // versioning policy in the presentation/application layers.
    final result = await _repository.updatePage(page);
    if (result is Success) {
      await _updateWidgetsUseCase();
    }
    return result;
  }
}
