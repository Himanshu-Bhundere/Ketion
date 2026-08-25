import '../../../../core/utils/result.dart';
import 'package:ketion/features/widgets/domain/usecases/update_widgets_usecase.dart';
import '../entities/page.dart';
import '../repositories/page_repository.dart';

class UpdatePageUseCase {
  final PageRepository _repository;
  final UpdateWidgetsUseCase _updateWidgetsUseCase;

  UpdatePageUseCase(this._repository, this._updateWidgetsUseCase);

  Future<Result<void>> call(Page page) async {
    final updatedPage = page.copyWith(
      updatedAt: DateTime.now(),
      version: page.version + 1,
    );
    final result = await _repository.updatePage(updatedPage);
    if (result is Success) {
      await _updateWidgetsUseCase();
    }
    return result;
  }
}
