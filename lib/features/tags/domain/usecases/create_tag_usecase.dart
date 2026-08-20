import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

class CreateTagUseCase {
  final TagRepository _repository;
  final Uuid _uuid;

  CreateTagUseCase(this._repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<Result<Tag>> call({
    required String name,
    String? color,
  }) async {
    final tag = Tag(
      id: _uuid.v7(),
      name: name,
      color: color,
    );
    
    final result = await _repository.createTag(tag);
    return result.fold(
      (_) => Success(tag),
      (Failure failure) => Error(failure),
    );
  }
}
