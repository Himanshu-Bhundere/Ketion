import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../../blocks/domain/entities/block.dart';
import '../../../blocks/domain/repositories/block_repository.dart';
import '../../../blocks/presentation/providers/block_providers.dart';
import '../models/drop_intent.dart';

final moveBlockUseCaseProvider = Provider<MoveBlockUseCase>((ref) {
  return MoveBlockUseCase(ref.read(blockRepositoryProvider));
});

class MoveBlockUseCase {
  final BlockRepository _repository;

  MoveBlockUseCase(this._repository);

  Future<Result<List<Block>>> call({
    required String sourceBlockId,
    required DropIntent intent,
  }) async {
    return await _repository.moveBlock(sourceBlockId, intent);
  }
}
