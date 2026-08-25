import '../../../../core/utils/result.dart';
import 'package:ketion/features/widgets/domain/usecases/update_widgets_usecase.dart';
import '../repositories/page_repository.dart';

class DeletePageUseCase {
  final PageRepository _repository;
  final UpdateWidgetsUseCase _updateWidgetsUseCase;

  DeletePageUseCase(this._repository, this._updateWidgetsUseCase);

  Future<Result<void>> call(String id) async {
    final result = await _repository.deletePage(id);
    if (result is Success) {
      await _updateWidgetsUseCase();
    }
    return result;
  }
}
