import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../blocks/domain/entities/block.dart';
import '../../../blocks/presentation/providers/block_providers.dart';
import '../../domain/commands/editor_command.dart';
import '../../domain/models/visible_block.dart';
import '../../domain/models/drop_intent.dart';
import '../../domain/services/block_tree_service.dart';
import '../../domain/services/sibling_position_manager.dart';

final focusedBlockIdProvider = StateProvider<String?>((ref) => null);
final pendingBlockFocusProvider = StateProvider<String?>((ref) => null);

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
    final result = await ref.read(blockRepositoryProvider).createBlock(block);
    if (result.isError) throw Exception('Could not create block');
    final newBlocks = List<Block>.from(currentBlocks)..insert(index, block);
    state = AsyncData(newBlocks);
  }

  Future<void> deleteBlockDirectly(String blockId) async {
    final currentBlocks = state.valueOrNull ?? [];
    final deleteBlockUseCase = ref.read(deleteBlockUseCaseProvider);
    final result = await deleteBlockUseCase(blockId);
    if (result.isError) throw Exception('Could not delete block');
    state = AsyncData(currentBlocks.where((b) => b.id != blockId).toList());
  }

  Future<void> updateBlockDirectly(Block block) async {
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((b) => b.id == block.id);
    if (index != -1) {
      final updateBlockUseCase = ref.read(updateBlockUseCaseProvider);
      final result = await updateBlockUseCase(block);
      if (result.isError) throw Exception('Could not save block');
      final newBlocks = List<Block>.from(currentBlocks);
      newBlocks[index] = block;
      state = AsyncData(newBlocks);
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

    final siblings = currentBlocks
        .where((block) => block.parentBlockId == existingBlock.parentBlockId && !block.deleted)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final siblingIndex = siblings.indexWhere((block) => block.id == existingBlock.id);
    final nextSibling = siblingIndex >= 0 && siblingIndex < siblings.length - 1
        ? siblings[siblingIndex + 1]
        : null;
    final newBlock = Block(
      id: const Uuid().v7(),
      pageId: _pageId,
      parentBlockId: existingBlock.parentBlockId,
      type: 'text',
      position: SiblingPositionManager.calculatePositionBetweenBlocks(existingBlock, nextSibling),
      data: '{"spans": [], "headingLevel": 0}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await executeCommand(InsertBlockCommand(block: newBlock, index: index + 1));
    ref.read(pendingBlockFocusProvider.notifier).state = newBlock.id;
  }

  Future<void> splitTextBlock(Block block, String before, String after) async {
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((item) => item.id == block.id);
    if (index == -1) return;
    final updated = block.copyWith(data: _textData(before));
    final siblings = currentBlocks.where((item) => item.parentBlockId == block.parentBlockId && !item.deleted).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final siblingIndex = siblings.indexWhere((item) => item.id == block.id);
    final next = siblingIndex >= 0 && siblingIndex < siblings.length - 1 ? siblings[siblingIndex + 1] : null;
    final inserted = Block(
      id: const Uuid().v7(), pageId: _pageId, parentBlockId: block.parentBlockId,
      type: 'text', position: SiblingPositionManager.calculatePositionBetweenBlocks(block, next),
      data: _textData(after), createdAt: DateTime.now().toUtc(), updatedAt: DateTime.now().toUtc(),
    );
    await executeCommand(
      BatchCommand([
        UpdateBlockCommand(oldBlock: block, newBlock: updated),
        InsertBlockCommand(block: inserted, index: index + 1),
      ]),
    );
    ref.read(pendingBlockFocusProvider.notifier).state = inserted.id;
  }

  Future<void> mergeEmptyBlockWithPrevious(Block block) async {
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((item) => item.id == block.id);
    if (index == -1) return;
    final siblings = currentBlocks.where((item) => item.parentBlockId == block.parentBlockId && !item.deleted).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final siblingIndex = siblings.indexWhere((item) => item.id == block.id);
    if (siblingIndex <= 0) return;
    final previous = siblings[siblingIndex - 1];
    await executeCommand(DeleteBlockCommand(block: block, index: index));
    ref.read(pendingBlockFocusProvider.notifier).state = previous.id;
  }

  String _textData(String text) => jsonEncode({
        'spans': [
          {'text': text, 'bold': false, 'italic': false, 'underline': false, 'strikethrough': false, 'code': false},
        ],
        'headingLevel': 0,
      });

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
