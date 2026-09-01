import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../blocks/domain/entities/block.dart';
import '../../../blocks/presentation/providers/block_providers.dart';

final focusedBlockIdProvider = StateProvider<String?>((ref) => null);

class EditorStateNotifier extends FamilyAsyncNotifier<List<Block>, String> {
  late String _pageId;
  final List<List<Block>> _undoStack = [];
  final List<List<Block>> _redoStack = [];

  @override
  Future<List<Block>> build(String arg) async {
    _pageId = arg;
    return _loadBlocks();
  }

  void _saveStateToUndo() {
    final current = state.valueOrNull;
    if (current == null) return;
    
    // Create deep copy
    _undoStack.add(current.map((b) => b.copyWith()).toList());
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    final current = state.valueOrNull;
    if (current != null) {
      _redoStack.add(current.map((b) => b.copyWith()).toList());
    }
    
    final previousState = _undoStack.removeLast();
    state = AsyncData(previousState);
    
    final updateBlockUseCase = ref.read(updateBlockUseCaseProvider);
    for (var b in previousState) {
      await updateBlockUseCase(b);
    }
  }

  Future<void> redo() async {
    if (_redoStack.isEmpty) return;
    final current = state.valueOrNull;
    if (current != null) {
      _undoStack.add(current.map((b) => b.copyWith()).toList());
    }
    
    final nextState = _redoStack.removeLast();
    state = AsyncData(nextState);
    
    final updateBlockUseCase = ref.read(updateBlockUseCaseProvider);
    for (var b in nextState) {
      await updateBlockUseCase(b);
    }
  }

  Future<List<Block>> _loadBlocks() async {
    final getPageBlocks = ref.read(getPageBlocksUseCaseProvider);
    final result = await getPageBlocks(_pageId);

    return result.fold(
      (blocks) {
        if (blocks.isEmpty) {
          // Initialize with an empty text block if page is empty
          return [
            Block(
              id: const Uuid().v7(),
              pageId: _pageId,
              type: 'text',
              position: 0.0,
              data: '{"spans": [], "headingLevel": 0}',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ];
        }

        // Sort by position
        final sorted = List<Block>.from(blocks);
        sorted.sort((a, b) => a.position.compareTo(b.position));
        return sorted;
      },
      (failure) {
        throw Exception(failure.message);
      },
    );
  }

  Future<void> updateBlock(Block block) async {
    _saveStateToUndo();
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((b) => b.id == block.id);

    if (index != -1) {
      final updatedBlock = block.copyWith(updatedAt: DateTime.now());
      final newBlocks = List<Block>.from(currentBlocks);
      newBlocks[index] = updatedBlock;
      state = AsyncData(newBlocks);

      // Persist via UseCase
      final updateBlockUseCase = ref.read(updateBlockUseCaseProvider);
      await updateBlockUseCase(updatedBlock);
    }
  }

  Future<void> insertBlockAfter(Block existingBlock) async {
    _saveStateToUndo();
    final createBlockUseCase = ref.read(createBlockUseCaseProvider);

    // Create via usecase to get DB persisted block with correct ID and timestamps
    final result = await createBlockUseCase(
      pageId: _pageId,
      type: 'text',
      position: existingBlock.position + 10, // Approximate for now
      data: '{"spans": [], "headingLevel": 0}',
    );

    result.fold(
      (newBlock) {
        final currentBlocks = state.valueOrNull ?? [];
        final index = currentBlocks.indexWhere((b) => b.id == existingBlock.id);

        if (index != -1) {
          final newBlocks = List<Block>.from(currentBlocks);
          newBlocks.insert(index + 1, newBlock);
          state = AsyncData(newBlocks);
        }
      },
      (failure) {
        // Handle error quietly or log
      },
    );
  }

  Future<void> reorderBlocks(int oldIndex, int newIndex) async {
    _saveStateToUndo();
    final currentBlocks = state.valueOrNull ?? [];
    if (oldIndex < 0 ||
        oldIndex >= currentBlocks.length ||
        newIndex < 0 ||
        newIndex > currentBlocks.length) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final newBlocks = List<Block>.from(currentBlocks);
    final block = newBlocks.removeAt(oldIndex);
    newBlocks.insert(newIndex, block);

    // Calculate new position
    double newPosition;
    if (newBlocks.length == 1) {
      newPosition = 0;
    } else if (newIndex == 0) {
      newPosition = newBlocks[1].position - 1000;
    } else if (newIndex == newBlocks.length - 1) {
      newPosition = newBlocks[newIndex - 1].position + 1000;
    } else {
      newPosition = (newBlocks[newIndex - 1].position +
              newBlocks[newIndex + 1].position) /
          2;
    }

    final updatedBlock = block.copyWith(
      position: newPosition,
      updatedAt: DateTime.now(),
    );
    newBlocks[newIndex] = updatedBlock;

    state = AsyncData(newBlocks);

    final updateBlockUseCase = ref.read(updateBlockUseCaseProvider);
    await updateBlockUseCase(updatedBlock);
  }

  Future<void> deleteBlock(String blockId) async {
    _saveStateToUndo();
    final currentBlocks = state.valueOrNull ?? [];
    final newBlocks = currentBlocks.where((b) => b.id != blockId).toList();

    state = AsyncData(newBlocks);

    final deleteBlockUseCase = ref.read(deleteBlockUseCaseProvider);
    await deleteBlockUseCase(blockId);
  }
}

final editorStateProvider =
    AsyncNotifierProviderFamily<EditorStateNotifier, List<Block>, String>(
  () => EditorStateNotifier(),
);
