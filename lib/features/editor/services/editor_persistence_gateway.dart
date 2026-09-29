import '../../blocks/domain/entities/block.dart';
import '../../blocks/domain/repositories/block_repository.dart';
import 'editor_persistence_coordinator.dart';
import 'editor_persistence_mutations.dart';

class RepositoryEditorPersistenceGateway implements EditorPersistenceGateway {
  final BlockRepository repository;

  RepositoryEditorPersistenceGateway({required this.repository});

  @override
  Future<void> executeMutation(EditorPersistenceMutation mutation) async {

    if (mutation is UpdateBlockMutation) {
      final block = await _persistedBlock(mutation.blockId);
      if (block != null) {
        final updated = block.copyWith(
          data: mutation.data,
          type: mutation.type,
          parentBlockId: mutation.parentBlockId ?? block.parentBlockId,
          position: mutation.position,
        );
        final result = await repository.updateBlock(updated, expectedVersion: mutation.expectedVersion);
        if (result.isError) throw Exception(result.fold((_) => '', (f) => f.toString()));
      } else {
        throw StateError('Block ${mutation.blockId} is unavailable for update');
      }
    } else if (mutation is InsertBlockMutation) {
      final block = Block(
        id: mutation.blockId,
        pageId: mutation.pageId,
        parentBlockId: mutation.parentBlockId,
        type: mutation.type,
        position: mutation.position,
        data: mutation.data,
        createdAt: mutation.createdAt,
        updatedAt: mutation.createdAt,
      );
      final result = await repository.createBlock(block);
      if (result.isError) throw Exception(result.fold((_) => '', (f) => f.toString()));
    } else if (mutation is DeleteBlockMutation) {
      final result = await repository.deleteBlock(mutation.blockId, expectedVersion: mutation.expectedVersion);
      if (result.isError) throw Exception(result.fold((_) => '', (f) => f.toString()));
    } else if (mutation is RestoreBlockMutation) {
      final result = await repository.restoreBlock(
        mutation.blockId,
        mutation.data,
        mutation.parentBlockId,
        mutation.position,
      );
      if (result.isError) throw Exception(result.fold((_) => '', (f) => f.toString()));
    } else if (mutation is SplitBlockMutation) {
      final oldBlock = await _persistedBlock(mutation.originalBlockId);
      if (oldBlock != null) {
        final updatedOld = oldBlock.copyWith(data: mutation.originalData);
        final newBlock = Block(
          id: mutation.newBlockId,
          pageId: mutation.pageId,
          parentBlockId: mutation.newParentBlockId ?? oldBlock.parentBlockId,
          type: mutation.newType,
          position: mutation.newPosition,
          data: mutation.newData,
          createdAt: mutation.createdAt,
          updatedAt: mutation.createdAt,
        );
        final result = await repository.splitBlock(
          updatedOriginalBlock: updatedOld,
          originalExpectedVersion: mutation.expectedVersion,
          newBlock: newBlock,
        );
        if (result.isError) throw Exception(result.fold((_) => '', (f) => f.toString()));
      } else {
        throw StateError(
          'Block ${mutation.originalBlockId} is unavailable for split',
        );
      }
    } else if (mutation is MergeBlocksMutation) {
      final survivor = await _persistedBlock(mutation.survivorBlockId);
      if (survivor != null) {
        final updatedSurvivor = survivor.copyWith(data: mutation.survivorData);
        final result = await repository.mergeBlocks(
          mergedBlock: updatedSurvivor,
          survivorExpectedVersion: mutation.survivorExpectedVersion,
          deletedBlockId: mutation.victimBlockId,
          victimExpectedVersion: mutation.victimExpectedVersion,
        );
        if (result.isError) throw Exception(result.fold((_) => '', (f) => f.toString()));
      } else {
        throw StateError(
          'Block ${mutation.survivorBlockId} is unavailable for merge',
        );
      }
    } else if (mutation is MoveBlockMutation) {
      final block = await _persistedBlock(mutation.blockId);
      if (block != null) {
        final updated = block.copyWith(
          parentBlockId: mutation.parentBlockId,
          position: mutation.position,
        );
        final result = await repository.updateBlock(updated, expectedVersion: mutation.expectedVersion);
        if (result.isError) throw Exception(result.fold((_) => '', (f) => f.toString()));
      }
    } else if (mutation is ChangeBlockTypeMutation) {
      final block = await _persistedBlock(mutation.blockId);
      if (block != null) {
        final updated = block.copyWith(
          type: mutation.newType,
          data: mutation.newData,
        );
        final result = await repository.updateBlock(updated, expectedVersion: mutation.expectedVersion);
        if (result.isError) throw Exception(result.fold((_) => '', (f) => f.toString()));
      }
    }
  }

  Future<Block?> _persistedBlock(String blockId) async {
    final result = await repository.getBlock(blockId);
    return result.valueOrNull;
  }
}
