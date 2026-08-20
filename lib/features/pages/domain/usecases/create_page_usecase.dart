import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/page.dart';
import '../repositories/page_repository.dart';

class CreatePageUseCase {
  final PageRepository _repository;
  final Uuid _uuid;

  CreatePageUseCase(this._repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<Result<Page>> call({
    required String title,
    String? parentPageId,
    String? icon,
    String? coverImage,
  }) async {
    final now = DateTime.now();
    final page = Page(
      id: _uuid.v7(),
      parentPageId: parentPageId,
      title: title,
      icon: icon,
      coverImage: coverImage,
      createdAt: now,
      updatedAt: now,
    );
    
    final result = await _repository.createPage(page);
    return result.fold(
      (_) => Success(page),
      (Failure failure) => Error(failure),
    );
  }
}
