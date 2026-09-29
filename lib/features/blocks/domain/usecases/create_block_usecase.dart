import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/block.dart';
import '../repositories/block_repository.dart';

class CreateBlockUseCase {
  final BlockRepository _repository;
  final Uuid _uuid;

  CreateBlockUseCase(this._repository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  Future<Result<Block>> call({
    required String pageId,
    String? parentBlockId,
    required String type,
    required double position,
    required String data,
  }) async {
    final now = DateTime.now().toUtc();
    final block = Block(
      id: _uuid.v7(),
      pageId: pageId,
      parentBlockId: parentBlockId,
      type: type,
      position: position,
      data: data,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );

    final result = await _repository.createBlock(block);
    return result.fold(
      (_) => Success(block),
      (Failure failure) => Error(failure),
    );
  }
}
