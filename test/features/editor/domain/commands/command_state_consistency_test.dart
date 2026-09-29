import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/blocks/domain/repositories/block_repository.dart';
import 'package:ketion/features/blocks/presentation/providers/block_providers.dart';
import 'package:ketion/features/editor/domain/commands/editor_command.dart';
import 'package:ketion/features/editor/presentation/providers/editor_state_provider.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/features/editor/domain/models/drop_intent.dart';

class FailingBlockRepository implements BlockRepository {
  final BlockRepository _realRepo;
  bool shouldFailUpdate = false;
  bool shouldFailCreate = false;

  FailingBlockRepository(this._realRepo);

  @override
  Future<Result<void>> createBlock(Block block) async {
    if (shouldFailCreate) return const Error(StorageFailure('Simulated create failure'));
    return _realRepo.createBlock(block);
  }

  @override
  Future<Result<void>> updateBlock(Block block) async {
    if (shouldFailUpdate) return const Error(StorageFailure('Simulated update failure'));
    return _realRepo.updateBlock(block);
  }

  @override
  Future<Result<void>> deleteBlock(String id) async {
    return _realRepo.deleteBlock(id);
  }

  @override
  Future<Result<Block>> getBlock(String id) async {
    return _realRepo.getBlock(id);
  }

  @override
  Future<Result<List<Block>>> getBlocksForPage(String pageId) async {
    return _realRepo.getBlocksForPage(pageId);
  }

  @override
  Future<Result<List<Block>>> getChildBlocks(String parentBlockId) async {
    return _realRepo.getChildBlocks(parentBlockId);
  }

  @override
  Future<Result<List<Block>>> moveBlock(String sourceBlockId, DropIntent intent) async {
    return _realRepo.moveBlock(sourceBlockId, intent);
  }

  @override
  Future<Result<void>> splitBlock({
    required Block updatedOriginalBlock,
    required Block newBlock,
  }) async {
    if (shouldFailCreate || shouldFailUpdate) return const Error(StorageFailure('Simulated split failure'));
    return _realRepo.splitBlock(
      updatedOriginalBlock: updatedOriginalBlock,
      newBlock: newBlock,
    );
  }

  @override
  Future<Result<void>> mergeBlocks({
    required Block mergedBlock,
    required String deletedBlockId,
  }) async {
    if (shouldFailUpdate) return const Error(StorageFailure('Simulated merge failure'));
    return _realRepo.mergeBlocks(
      mergedBlock: mergedBlock,
      deletedBlockId: deletedBlockId,
    );
  }
}

class InMemoryFakeBlockRepository implements BlockRepository {
  List<Block> blocks = [];

  @override
  Future<Result<void>> createBlock(Block block) async {
    blocks.add(block);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateBlock(Block block) async {
    final index = blocks.indexWhere((b) => b.id == block.id);
    if (index != -1) blocks[index] = block;
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteBlock(String id) async {
    final index = blocks.indexWhere((b) => b.id == id);
    if (index != -1) {
      blocks[index] = blocks[index].copyWith(deleted: true);
    }
    return const Success(null);
  }

  @override
  Future<Result<Block>> getBlock(String id) async {
    final block = blocks.firstWhere((b) => b.id == id);
    return Success(block);
  }

  @override
  Future<Result<List<Block>>> getBlocksForPage(String pageId) async {
    return Success(blocks.where((b) => b.pageId == pageId && !b.deleted).toList());
  }

  @override
  Future<Result<List<Block>>> getChildBlocks(String parentBlockId) async {
    return Success(blocks.where((b) => b.parentBlockId == parentBlockId && !b.deleted).toList());
  }

  @override
  Future<Result<List<Block>>> moveBlock(String sourceBlockId, DropIntent intent) async {
    return const Success([]);
  }

  @override
  Future<Result<void>> splitBlock({
    required Block updatedOriginalBlock,
    required Block newBlock,
  }) async {
    final index = blocks.indexWhere((b) => b.id == updatedOriginalBlock.id);
    if (index != -1) blocks[index] = updatedOriginalBlock;
    blocks.add(newBlock);
    return const Success(null);
  }

  @override
  Future<Result<void>> mergeBlocks({
    required Block mergedBlock,
    required String deletedBlockId,
  }) async {
    final index = blocks.indexWhere((b) => b.id == mergedBlock.id);
    if (index != -1) blocks[index] = mergedBlock;
    final delIndex = blocks.indexWhere((b) => b.id == deletedBlockId);
    if (delIndex != -1) {
      blocks[delIndex] = blocks[delIndex].copyWith(deleted: true);
    }
    return const Success(null);
  }
}

void main() {
  group('Command State Consistency', () {
    late ProviderContainer container;
    late FailingBlockRepository failingRepo;
    late InMemoryFakeBlockRepository memoryRepo;

    setUp(() {
      memoryRepo = InMemoryFakeBlockRepository();
      memoryRepo.blocks = [
        Block(
          id: 'b1',
          pageId: 'p1',
          type: 'text',
          position: 0,
          data: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      failingRepo = FailingBlockRepository(memoryRepo);

      container = ProviderContainer(
        overrides: [
          blockRepositoryProvider.overrideWithValue(failingRepo),
        ],
      );
    });

    test('InsertBlockCommand consistency on failure', () async {
      final notifier = container.read(editorStateProvider('p1').notifier);
      await notifier.build('p1');

      failingRepo.shouldFailCreate = true;

      final newBlock = Block(
        id: 'b2',
        pageId: 'p1',
        type: 'text',
        position: 100,
        data: 'test2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final command = InsertBlockCommand(block: newBlock, index: 1);

      try {
        await notifier.executeCommand(command);
        fail('Should throw');
      } catch (e) {
        // Expected
      }

      // Verify UI state is unchanged
      final state = notifier.state.valueOrNull!;
      expect(state.length, 1);
      expect(state[0].id, 'b1');

      // Verify DB is unchanged
      expect(memoryRepo.blocks.length, 1);

      // Verify Undo stack is empty
      await notifier.undo();
      expect(notifier.state.valueOrNull!.length, 1);
    });

    test('SplitBlockCommand consistency on partial failure', () async {
      final notifier = container.read(editorStateProvider('p1').notifier);
      await notifier.build('p1');

      // Simulate update succeeding, but create failing
      failingRepo.shouldFailUpdate = false;
      failingRepo.shouldFailCreate = true;

      final b1 = memoryRepo.blocks[0];
      final updatedB1 = b1.copyWith(data: 'te');
      final newB2 = Block(
        id: 'b2',
        pageId: 'p1',
        type: 'text',
        position: 100,
        data: 'st',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final command = SplitBlockCommand(
        originalBlock: b1,
        updatedOriginalBlock: updatedB1,
        newBlock: newB2,
        index: 0,
      );

      try {
        await notifier.executeCommand(command);
        fail('Should throw');
      } catch (e) {
        // Expected
      }

      // Verify UI state is unchanged (or rolled back)
      final state = notifier.state.valueOrNull!;
      expect(state.length, 1);
      
      // If we don't have atomicity, this will fail because the update succeeded and mutated the UI
      expect(state[0].data, 'test'); 

      // Verify DB is unchanged
      expect(memoryRepo.blocks[0].data, 'test');

      // Verify Undo stack is empty
      await notifier.undo();
      expect(notifier.state.valueOrNull![0].data, 'test');
    });
    test('MergeBlocksCommand consistency on partial failure', () async {
      memoryRepo.blocks.add(Block(
        id: 'b2',
        pageId: 'p1',
        type: 'text',
        position: 1,
        data: 'test2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),);

      final notifier = container.read(editorStateProvider('p1').notifier);
      await notifier.build('p1');

      failingRepo.shouldFailUpdate = true;

      final b1 = memoryRepo.blocks[0];
      final b2 = memoryRepo.blocks[1];
      
      final mergedB1 = b1.copyWith(data: 'testtest2');

      final command = MergeBlocksCommand(
        previousBlock: b1,
        currentBlock: b2,
        mergedBlock: mergedB1,
        currentBlockIndex: 1,
      );

      try {
        await notifier.executeCommand(command);
        fail('Should throw');
      } catch (e) {
        // Expected
      }

      // Verify UI state is unchanged
      final state = notifier.state.valueOrNull!;
      expect(state.length, 2);
      expect(state[0].data, 'test'); 
      expect(state[1].data, 'test2'); 

      // Verify DB is unchanged
      expect(memoryRepo.blocks[0].data, 'test');
      expect(memoryRepo.blocks.length, 2);
      expect(memoryRepo.blocks[1].deleted, false);

      // Verify Undo stack is empty
      await notifier.undo();
      expect(notifier.state.valueOrNull!.length, 2);
    });
  });
}
