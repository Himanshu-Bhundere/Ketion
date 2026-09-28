import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../blocks/domain/entities/block.dart';
import '../../../blocks/presentation/providers/block_providers.dart';
import '../../domain/commands/editor_command.dart';
import '../../domain/models/visible_block.dart';
import '../../domain/models/drop_intent.dart';
import '../../domain/services/block_tree_service.dart';

final focusedBlockIdProvider = StateProvider<String?>((ref) => null);

// A derived provider that builds the visible tree automatically
final visibleBlocksProvider =
    Provider.family<List<VisibleBlock>, String>((ref, pageId) {
  final blocksAsync = ref.watch(editorStateProvider(pageId));
  return blocksAsync.maybeWhen(
    data: (blocks) => BlockTreeService.buildVisibleTree(blocks),
    orElse: () => [],
  );
});

class EditorStateNotifier extends FamilyAsyncNotifier<List<Block>, String> {
  late String _pageId;

  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];

  @override
  Future<List<Block>> build(String arg) async {
    _pageId = arg;
    return _loadBlocks();
  }

  Future<void> executeCommand(EditorCommand command) async {
    await command.execute(this);
    _undoStack.add(command);
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    final command = _undoStack.removeLast();
    await command.undo(this);
    _redoStack.add(command);
  }

  Future<void> redo() async {
    if (_redoStack.isEmpty) return;
    final command = _redoStack.removeLast();
    await command.execute(this);
    _undoStack.add(command);
  }

  Future<List<Block>> _loadBlocks() async {
    final getPageBlocks = ref.read(getPageBlocksUseCaseProvider);
    final result = await getPageBlocks(_pageId);

    return result.fold(
      (blocks) {
        if (blocks.isEmpty) {
          return [];
        }

        final sorted = List<Block>.from(blocks);
        sorted.sort((a, b) => a.position.compareTo(b.position));
        return sorted;
      },
      (failure) {
        throw Exception(failure.message);
      },
    );
  }

  // --- Direct State Mutations for Commands ---

  Future<void> insertBlockDirectly(Block block, int index) async {
    final currentBlocks = state.valueOrNull ?? [];
    final newBlocks = List<Block>.from(currentBlocks);
    newBlocks.insert(index, block);
    state = AsyncData(newBlocks);

    // If block doesn't exist in DB (e.g. from scratch), create it.
    // The createBlockUseCase does creation from raw properties, but here we have the Block.
    // Instead of duplicating create vs update logic, we'll just use update (UPSERT behavior) or create if we can.
    // Assuming updateBlockUseCase can handle UPSERT or we just use it directly.
    final updateBlockUseCase = ref.read(updateBlockUseCaseProvider);
    await updateBlockUseCase(block);
  }

  Future<void> deleteBlockDirectly(String blockId) async {
    final currentBlocks = state.valueOrNull ?? [];
    final newBlocks = currentBlocks.where((b) => b.id != blockId).toList();
    state = AsyncData(newBlocks);

    final deleteBlockUseCase = ref.read(deleteBlockUseCaseProvider);
    await deleteBlockUseCase(blockId);
  }

  Future<void> updateBlockDirectly(Block block) async {
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((b) => b.id == block.id);
    if (index != -1) {
      final newBlocks = List<Block>.from(currentBlocks);
      newBlocks[index] = block;
      state = AsyncData(newBlocks);

      final updateBlockUseCase = ref.read(updateBlockUseCaseProvider);
      await updateBlockUseCase(block);
    }
  }

  // --- High-level actions ---

  Future<void> updateBlock(Block block) async {
    final currentBlocks = state.valueOrNull ?? [];
    final oldBlock = currentBlocks.firstWhere((b) => b.id == block.id);
    await executeCommand(
      UpdateBlockCommand(oldBlock: oldBlock, newBlock: block),
    );
  }

  Future<void> insertBlockAfter(Block existingBlock) async {
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((b) => b.id == existingBlock.id);
    if (index == -1) return;

    final newBlock = Block(
      id: const Uuid().v7(),
      pageId: _pageId,
      parentBlockId: existingBlock.parentBlockId,
      type: 'text',
      position: existingBlock.position +
          10.0, // Simplified for now, real app should use SiblingPositionManager
      data: '{"spans": [], "headingLevel": 0}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await executeCommand(InsertBlockCommand(block: newBlock, index: index + 1));
  }

  Future<void> deleteBlock(String blockId) async {
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    await executeCommand(
      DeleteBlockCommand(block: currentBlocks[index], index: index),
    );
  }

  Future<void> indentBlock(String blockId) async {
    final currentBlocks = state.valueOrNull ?? [];
    final oldBlock = currentBlocks.firstWhere((b) => b.id == blockId);
    final updatedBlocks = BlockTreeService.indentBlock(blockId, currentBlocks);
    if (updatedBlocks.isNotEmpty) {
      await executeCommand(
        UpdateBlockCommand(
          oldBlock: oldBlock,
          newBlock: updatedBlocks.first,
        ),
      );
    }
  }

  Future<void> outdentBlock(String blockId) async {
    final currentBlocks = state.valueOrNull ?? [];
    final oldBlock = currentBlocks.firstWhere((b) => b.id == blockId);
    final updatedBlocks = BlockTreeService.outdentBlock(blockId, currentBlocks);
    if (updatedBlocks.isNotEmpty) {
      await executeCommand(
        UpdateBlockCommand(
          oldBlock: oldBlock,
          newBlock: updatedBlocks.first,
        ),
      );
    }
  }

  Future<void> handleDropIntent(
    String draggedBlockId,
    DropIntent intent,
  ) async {
    final currentBlocks = state.valueOrNull ?? [];
    final oldBlock = currentBlocks.firstWhere((b) => b.id == draggedBlockId);
    final updatedBlocks =
        BlockTreeService.moveBlock(draggedBlockId, intent, currentBlocks);
    if (updatedBlocks.isNotEmpty) {
      await executeCommand(
        UpdateBlockCommand(
          oldBlock: oldBlock,
          newBlock: updatedBlocks.first,
        ),
      );
    }
  }
}

final editorStateProvider =
    AsyncNotifierProviderFamily<EditorStateNotifier, List<Block>, String>(
  () => EditorStateNotifier(),
);
