import '../../../../core/utils/result.dart';
import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

class UpdateTagUseCase {
  final TagRepository _repository;

  UpdateTagUseCase(this._repository);

  Future<Result<void>> call(Tag tag) {
    final updatedTag = tag.copyWith(
      version: tag.version + 1,
    );
    return _repository.updateTag(updatedTag);
  }
}
