import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/result.dart';
import '../../../blocks/domain/entities/block.dart';
import '../../../blocks/presentation/providers/block_providers.dart';
import '../../domain/models/visible_block.dart';
import '../../domain/models/drop_intent.dart';
import '../../domain/services/block_tree_service.dart';
import '../../domain/services/sibling_position_manager.dart';
import '../../domain/usecases/move_block_use_case.dart';

final focusedBlockIdProvider = StateProvider<String?>((ref) => null);

class BlockFocusIntent {
  final String id;
  final String action;
  const BlockFocusIntent(this.id, this.action);
}

final pendingBlockFocusProvider = StateProvider<BlockFocusIntent?>((ref) => null);

final visibleBlocksProvider =
    Provider.family.autoDispose<List<VisibleBlock>, String>((ref, pageId) {
  final blocksAsync = ref.watch(editorStateProvider(pageId));
  return blocksAsync.maybeWhen(
    data: (blocks) => BlockTreeService.buildVisibleTree(blocks),
    orElse: () => const [],
  );
});

class EditorStateNotifier extends AutoDisposeFamilyAsyncNotifier<List<Block>, String> {
  late String _pageId;

  @override
  Future<List<Block>> build(String arg) async {
    _pageId = arg;
    final getPageBlocksUseCase = ref.watch(getPageBlocksUseCaseProvider);
    final result = await getPageBlocksUseCase(_pageId);

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
    final result = await ref.read(blockRepositoryProvider).createBlock(block);
    if (result.isError) throw Exception('Could not create block');
    final currentBlocks = state.valueOrNull ?? [];
    final newBlocks = List<Block>.from(currentBlocks);
    if (index == -1 || index > newBlocks.length) {
      newBlocks.add(block);
    } else {
      newBlocks.insert(index, block);
    }
    state = AsyncData(newBlocks);
  }

  Future<void> deleteBlockDirectly(String blockId) async {
    final deleteBlockUseCase = ref.read(deleteBlockUseCaseProvider);
    final result = await deleteBlockUseCase(blockId, expectedVersion: 1);
    if (result.isError) throw Exception('Could not delete block');
    final currentBlocks = state.valueOrNull ?? [];
    final nextBlocks = currentBlocks.where((b) => b.id != blockId).toList();
    state = AsyncData(nextBlocks);
  }

  Future<void> updateBlockDirectly(Block block) async {
    final updateBlockUseCase = ref.read(updateBlockUseCaseProvider);
    final result = await updateBlockUseCase(block);
    if (result.isError) throw Exception('Could not save block');
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((b) => b.id == block.id);
    if (index != -1) {
      final newBlocks = List<Block>.from(currentBlocks);
      newBlocks[index] = block;
      state = AsyncData(newBlocks);
    }
  }

  Future<void> splitBlockDirectly(Block updatedOriginalBlock, Block newBlock, int newBlockIndex) async {
    final splitBlockUseCase = ref.read(splitBlockUseCaseProvider);
    final result = await splitBlockUseCase(
      updatedOriginalBlock: updatedOriginalBlock,
      originalExpectedVersion: updatedOriginalBlock.version - 1,
      newBlock: newBlock,
    );
    if (result.isError) throw Exception('Could not split block');
    
    final currentBlocks = state.valueOrNull ?? [];
    final newBlocks = List<Block>.from(currentBlocks);
    final index = newBlocks.indexWhere((b) => b.id == updatedOriginalBlock.id);
    if (index != -1) {
      newBlocks[index] = updatedOriginalBlock;
      if (newBlockIndex == -1) {
        newBlockIndex = index + 1;
      }
    }
    if (newBlockIndex == -1 || newBlockIndex > newBlocks.length) {
      newBlocks.add(newBlock);
    } else {
      newBlocks.insert(newBlockIndex, newBlock);
    }
    state = AsyncData(newBlocks);
  }

  Future<void> mergeBlocksDirectly(Block mergedBlock, String deletedBlockId) async {
    final mergeBlocksUseCase = ref.read(mergeBlocksUseCaseProvider);
    final result = await mergeBlocksUseCase(
      mergedBlock: mergedBlock,
      survivorExpectedVersion: mergedBlock.version - 1,
      victimExpectedVersion: 1,
      deletedBlockId: deletedBlockId,
    );
    if (result.isError) throw Exception('Could not merge blocks');

    final currentBlocks = state.valueOrNull ?? [];
    final newBlocks = List<Block>.from(currentBlocks);
    final index = newBlocks.indexWhere((b) => b.id == mergedBlock.id);
    if (index != -1) {
      newBlocks[index] = mergedBlock;
    }
    newBlocks.removeWhere((b) => b.id == deletedBlockId);
    state = AsyncData(newBlocks);
  }

  Future<void> restoreBlockDirectly(String blockId, String data, String? parentBlockId, double position) async {
    final restoreBlockUseCase = ref.read(restoreBlockUseCaseProvider);
    final result = await restoreBlockUseCase(
      blockId,
      data,
      parentBlockId,
      position,
    );
    if (result.isError) throw Exception('Could not restore block');

    final getPageBlocksUseCase = ref.read(getPageBlocksUseCaseProvider);
    final pageBlocksResult = await getPageBlocksUseCase(_pageId);

    pageBlocksResult.fold(
      (blocks) {
        final sorted = List<Block>.from(blocks);
        sorted.sort((a, b) => a.position.compareTo(b.position));
        state = AsyncData(sorted);
      },
      (failure) {
        throw Exception(failure.message);
      },
    );
  }


  // --- High-level actions ---

  void focusPreviousBlock(String currentBlockId) {
    final blocks = state.valueOrNull ?? [];
    final visibleBlocks = BlockTreeService.buildVisibleTree(blocks);
    final index = visibleBlocks.indexWhere((vb) => vb.block.id == currentBlockId);
    if (index > 0) {
      ref.read(pendingBlockFocusProvider.notifier).state = BlockFocusIntent(visibleBlocks[index - 1].block.id, 'end');
    }
  }

  void focusNextBlock(String currentBlockId) {
    final blocks = state.valueOrNull ?? [];
    final visibleBlocks = BlockTreeService.buildVisibleTree(blocks);
    final index = visibleBlocks.indexWhere((vb) => vb.block.id == currentBlockId);
    if (index >= 0 && index < visibleBlocks.length - 1) {
      ref.read(pendingBlockFocusProvider.notifier).state = BlockFocusIntent(visibleBlocks[index + 1].block.id, 'start');
    }
  }

  Future<void> updateBlock(Block block) async {
    await updateBlockDirectly(block);
  }

  Future<void> insertBlockAfter(Block existingBlock, {String type = 'text', String? data}) async {
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
    
    final blockData = data ?? _textData('');
    
    final newBlock = Block(
      id: const Uuid().v7(),
      pageId: _pageId,
      parentBlockId: existingBlock.parentBlockId,
      type: type,
      position: SiblingPositionManager.calculatePositionBetweenBlocks(existingBlock, nextSibling),
      data: blockData,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await insertBlockDirectly(newBlock, index + 1);
    ref.read(pendingBlockFocusProvider.notifier).state = BlockFocusIntent(newBlock.id, 'start');
  }

  Future<void> splitTextBlock(Block block, String before, String after) async {
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((item) => item.id == block.id);
    if (index == -1) return;
    
    int headingLevel = 0;
    try {
      final json = jsonDecode(block.data);
      headingLevel = json['headingLevel'] as int? ?? 0;
    } catch (_) {}

    final beforeDataString = jsonEncode({
      'spans': [{'text': before, 'bold': false, 'italic': false, 'underline': false, 'strikethrough': false, 'code': false}],
      'headingLevel': headingLevel,
    });
    
    final updated = block.copyWith(data: beforeDataString);
    final siblings = currentBlocks.where((item) => item.parentBlockId == block.parentBlockId && !item.deleted).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final siblingIndex = siblings.indexWhere((item) => item.id == block.id);
    final next = siblingIndex >= 0 && siblingIndex < siblings.length - 1 ? siblings[siblingIndex + 1] : null;
    final inserted = Block(
      id: const Uuid().v7(), pageId: _pageId, parentBlockId: block.parentBlockId,
      type: 'text', position: SiblingPositionManager.calculatePositionBetweenBlocks(block, next),
      data: _textData(after), createdAt: DateTime.now().toUtc(), updatedAt: DateTime.now().toUtc(),
    );
    await splitBlockDirectly(updated, inserted, index + 1);
    ref.read(pendingBlockFocusProvider.notifier).state = BlockFocusIntent(inserted.id, 'start');
  }

  Future<void> splitListBlock(Block block, String before, String after) async {
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((item) => item.id == block.id);
    if (index == -1) return;
    
    // Parse list type
    String listType = 'bullet';
    try {
      final json = jsonDecode(block.data);
      listType = json['listType'] as String? ?? 'bullet';
    } catch (_) {}

    // If both before and after are empty (double enter on empty list item), 
    // convert it to a text block instead of splitting
    if (before.isEmpty && after.isEmpty) {
       Block updated = block.copyWith(
         type: 'text',
         data: _textData(''),
         updatedAt: DateTime.now().toUtc(),
       );
       
       await updateBlockDirectly(updated);

       if (updated.parentBlockId != null) {
         await outdentBlock(updated.id);
       }
       
       ref.read(pendingBlockFocusProvider.notifier).state = BlockFocusIntent(updated.id, 'start');
       return;
    }

    String listData(String text) => jsonEncode({
          'spans': [{'text': text, 'bold': false, 'italic': false, 'underline': false, 'strikethrough': false, 'code': false}],
          'listType': listType,
          'checked': false,
        });

    final updated = block.copyWith(data: listData(before));
    final siblings = currentBlocks.where((item) => item.parentBlockId == block.parentBlockId && !item.deleted).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final siblingIndex = siblings.indexWhere((item) => item.id == block.id);
    final next = siblingIndex >= 0 && siblingIndex < siblings.length - 1 ? siblings[siblingIndex + 1] : null;
    final inserted = Block(
      id: const Uuid().v7(), pageId: _pageId, parentBlockId: block.parentBlockId,
      type: 'list', position: SiblingPositionManager.calculatePositionBetweenBlocks(block, next),
      data: listData(after), createdAt: DateTime.now().toUtc(), updatedAt: DateTime.now().toUtc(),
    );
    await splitBlockDirectly(updated, inserted, index + 1);
    ref.read(pendingBlockFocusProvider.notifier).state = BlockFocusIntent(inserted.id, 'start');
  }

  Future<void> mergeBlockWithPrevious(Block block, String textToMerge) async {
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((item) => item.id == block.id);
    if (index == -1) return;
    
    final visibleBlocks = BlockTreeService.buildVisibleTree(currentBlocks);
    final visibleIndex = visibleBlocks.indexWhere((vb) => vb.block.id == block.id);
    
    if (textToMerge.isEmpty) {
      if (visibleIndex > 0) {
        final previousVisible = visibleBlocks[visibleIndex - 1].block;
        await deleteBlock(block.id);
        ref.read(pendingBlockFocusProvider.notifier).state = BlockFocusIntent(previousVisible.id, 'end');
      } else {
        if (currentBlocks.where((b) => !b.deleted).length > 1) {
           await deleteBlock(block.id);
           if (visibleBlocks.length > 1) {
             ref.read(pendingBlockFocusProvider.notifier).state = BlockFocusIntent(visibleBlocks[1].block.id, 'start');
           }
        }
      }
      return;
    }

    if (visibleIndex <= 0) return;
    final previous = visibleBlocks[visibleIndex - 1].block;

    if (block.type != 'text' && block.type != 'list') return;
    if (previous.type != 'text' && previous.type != 'list') return;
    
    if (previous.type == 'list' && block.type == 'list') {
       String prevListType = 'bullet';
       String curListType = 'bullet';
       try {
         final prevJson = jsonDecode(previous.data) as Map<String, dynamic>;
         prevListType = prevJson['listType'] as String? ?? 'bullet';
         final curJson = jsonDecode(block.data) as Map<String, dynamic>;
         curListType = curJson['listType'] as String? ?? 'bullet';
       } catch (_) {}
       
       if (prevListType != curListType) {
         return; 
       }
    } else if (previous.type != block.type) {
       int prevHeadingLevel = 0;
       int curHeadingLevel = 0;
       try {
         final prevJson = jsonDecode(previous.data) as Map<String, dynamic>;
         prevHeadingLevel = prevJson['headingLevel'] as int? ?? 0;
         final curJson = jsonDecode(block.data) as Map<String, dynamic>;
         curHeadingLevel = curJson['headingLevel'] as int? ?? 0;
       } catch (_) {}
       if (previous.type != block.type || prevHeadingLevel != curHeadingLevel) {
          return;
       }
    }
    
    String previousText = '';
    Map<String, dynamic>? previousJson;
    try {
      previousJson = jsonDecode(previous.data) as Map<String, dynamic>;
      final spans = previousJson['spans'] as List?;
      if (spans != null && spans.isNotEmpty) {
        previousText = spans[0]['text'] as String? ?? '';
      }
    } catch (_) {}
    
    final mergedText = previousText + textToMerge;
    
    String newDataString;
    if (previousJson != null) {
      previousJson['spans'] = [{'text': mergedText, 'bold': false, 'italic': false, 'underline': false, 'strikethrough': false, 'code': false}];
      newDataString = jsonEncode(previousJson);
    } else {
      newDataString = _textData(mergedText);
    }

    final updatedPrevious = previous.copyWith(data: newDataString);

    await mergeBlocksDirectly(updatedPrevious, block.id);
    ref.read(pendingBlockFocusProvider.notifier).state = BlockFocusIntent(previous.id, 'offset:${previousText.length}');
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

    await deleteBlockDirectly(blockId);
  }

  Future<void> duplicateBlock(String blockId) async {
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final original = currentBlocks[index];
    final siblings = currentBlocks
        .where((block) => block.parentBlockId == original.parentBlockId && !block.deleted)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final siblingIndex = siblings.indexWhere((block) => block.id == original.id);
    final nextSibling = siblingIndex >= 0 && siblingIndex < siblings.length - 1
        ? siblings[siblingIndex + 1]
        : null;

    final duplicated = Block(
      id: const Uuid().v7(),
      pageId: _pageId,
      parentBlockId: original.parentBlockId,
      type: original.type,
      position: SiblingPositionManager.calculatePositionBetweenBlocks(original, nextSibling),
      data: original.data,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await insertBlockDirectly(duplicated, index + 1);
    ref.read(pendingBlockFocusProvider.notifier).state = BlockFocusIntent(duplicated.id, 'start');
  }

  Future<void> convertBlock(String blockId, String newType) async {
    final currentBlocks = state.valueOrNull ?? [];
    final index = currentBlocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;

    final original = currentBlocks[index];
    if (original.type == newType) return;

    final updated = original.copyWith(type: newType, updatedAt: DateTime.now().toUtc());
    await updateBlockDirectly(updated);
  }

  Future<void> indentBlock(String blockId) async {
    final currentBlocks = state.valueOrNull ?? [];
    final oldBlock = currentBlocks.firstWhere((b) => b.id == blockId);
    
    final siblings = currentBlocks
        .where((b) => b.parentBlockId == oldBlock.parentBlockId && !b.deleted)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final siblingIndex = siblings.indexWhere((b) => b.id == blockId);
    if (siblingIndex <= 0) return; // Cannot indent first sibling

    final previousSibling = siblings[siblingIndex - 1];
    
    // Check cycle and depth via moveBlock simulation
    final updatedBlocks = BlockTreeService.moveBlock(blockId, DropIntent.child(previousSibling.id), currentBlocks);
    if (updatedBlocks.isEmpty) return;

    // Execute the move directly by taking the result from BlockTreeService simulation
    // and updating blocks. For now, since moveBlockToIntent already does DB + state updates:
    await moveBlockToIntent(
      sourceBlockId: blockId,
      targetBlockId: previousSibling.id,
      intent: DropIntent.child(previousSibling.id),
    );
  }

  Future<void> outdentBlock(String blockId) async {
    final currentBlocks = state.valueOrNull ?? [];
    final oldBlock = currentBlocks.firstWhere((b) => b.id == blockId);
    if (oldBlock.parentBlockId == null) return;
    
    final updatedBlocks = BlockTreeService.moveBlock(blockId, DropIntent.unnest(blockId), currentBlocks);
    if (updatedBlocks.isEmpty) return;

    await moveBlockToIntent(
      sourceBlockId: blockId,
      targetBlockId: blockId,
      intent: DropIntent.unnest(blockId),
    );
  }

  Future<void> handleDropIntent(
    String draggedBlockId,
    DropIntent intent,
  ) async {
    final currentBlocks = state.valueOrNull ?? [];
    final oldBlock = currentBlocks.firstWhere((b) => b.id == draggedBlockId, orElse: () => currentBlocks.first);
    if (oldBlock.id != draggedBlockId) return; // Block deleted/missing

    final targetId = intent.when(
      before: (id) => id,
      after: (id) => id,
      child: (id) => id,
      unnest: (id) => id,
    );

    final targetBlock = currentBlocks.firstWhere((b) => b.id == targetId, orElse: () => currentBlocks.first);
    if (targetBlock.id != targetId) return; // Target deleted
    if (oldBlock.pageId != targetBlock.pageId) return; // Cross-page rejection

    await moveBlockToIntent(
      sourceBlockId: draggedBlockId,
      targetBlockId: targetId,
      intent: intent,
    );
  }

  Future<({String? parentBlockId, double position})> moveBlockToIntent({
    required String sourceBlockId,
    required String targetBlockId,
    required DropIntent intent,
  }) async {
    final currentBlocks = state.valueOrNull ?? [];
    final sourceBlock = currentBlocks.firstWhere((b) => b.id == sourceBlockId);

    final moveBlockUseCase = ref.read(moveBlockUseCaseProvider);
    final result = await moveBlockUseCase(
      sourceBlockId: sourceBlockId,
      intent: intent,
    );

    if (result.isError) {
      return (parentBlockId: sourceBlock.parentBlockId, position: sourceBlock.position);
    }
    
    final updatedBlocks = (result as Success<List<Block>>).value;
    if (updatedBlocks.isEmpty) {
      return (parentBlockId: sourceBlock.parentBlockId, position: sourceBlock.position);
    }

    final newBlock = updatedBlocks.firstWhere((b) => b.id == sourceBlockId, orElse: () => updatedBlocks.first);

    // Update state directly because the repository already updated DB
    final newBlocks = List<Block>.from(currentBlocks);
    for (final updatedBlock in updatedBlocks) {
      final index = newBlocks.indexWhere((b) => b.id == updatedBlock.id);
      if (index != -1) {
        newBlocks[index] = updatedBlock;
      }
    }
    state = AsyncData(newBlocks);

    return (parentBlockId: newBlock.parentBlockId, position: newBlock.position);
  }

  Future<void> moveBlockToPosition({
    required String blockId,
    required String? parentBlockId,
    required double position,
  }) async {
    final currentBlocks = state.valueOrNull ?? [];
    final sourceBlock = currentBlocks.firstWhere((b) => b.id == blockId);
    
    final updatedBlock = sourceBlock.copyWith(
      parentBlockId: parentBlockId,
      position: position,
      updatedAt: DateTime.now().toUtc(),
    );
    
    await updateBlockDirectly(updatedBlock);
  }
}

final editorStateProvider =
    AsyncNotifierProvider.autoDispose.family<EditorStateNotifier, List<Block>, String>(
  EditorStateNotifier.new,
);
