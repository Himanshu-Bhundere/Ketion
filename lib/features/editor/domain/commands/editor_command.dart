import '../../../blocks/domain/entities/block.dart';
import '../../presentation/providers/editor_state_provider.dart';
import '../models/drop_intent.dart';

abstract class EditorCommand {
  /// Executes the command and returns the modified state.
  Future<void> execute(EditorStateNotifier controller);

  /// Undoes the command and returns the modified state.
  Future<void> undo(EditorStateNotifier controller);
}

class InsertBlockCommand implements EditorCommand {
  final Block block;
  final int index;

  InsertBlockCommand({required this.block, required this.index});

  @override
  Future<void> execute(EditorStateNotifier controller) async {
    await controller.insertBlockDirectly(block, index);
  }

  @override
  Future<void> undo(EditorStateNotifier controller) async {
    await controller.deleteBlockDirectly(block.id);
  }
}

class UpdateBlockCommand implements EditorCommand {
  final Block oldBlock;
  final Block newBlock;

  UpdateBlockCommand({required this.oldBlock, required this.newBlock});

  @override
  Future<void> execute(EditorStateNotifier controller) async {
    await controller.updateBlockDirectly(newBlock);
  }

  @override
  Future<void> undo(EditorStateNotifier controller) async {
    await controller.updateBlockDirectly(oldBlock);
  }
}

class DeleteBlockCommand implements EditorCommand {
  final Block block;
  final int index;

  DeleteBlockCommand({required this.block, required this.index});

  @override
  Future<void> execute(EditorStateNotifier controller) async {
    await controller.deleteBlockDirectly(block.id);
  }

  @override
  Future<void> undo(EditorStateNotifier controller) async {
    await controller.insertBlockDirectly(block, index);
  }
}

class BatchCommand implements EditorCommand {
  final List<EditorCommand> commands;

  BatchCommand(this.commands);

  @override
  Future<void> execute(EditorStateNotifier controller) async {
    for (final cmd in commands) {
      await cmd.execute(controller);
    }
  }

  @override
  Future<void> undo(EditorStateNotifier controller) async {
    for (final cmd in commands.reversed) {
      await cmd.undo(controller);
    }
  }
}

class SplitBlockCommand implements EditorCommand {
  final Block originalBlock;
  final Block updatedOriginalBlock;
  final Block newBlock;
  final int index;

  SplitBlockCommand({
    required this.originalBlock,
    required this.updatedOriginalBlock,
    required this.newBlock,
    required this.index,
  });

  @override
  Future<void> execute(EditorStateNotifier controller) async {
    await controller.splitBlockDirectly(updatedOriginalBlock, newBlock, index + 1);
  }

  @override
  Future<void> undo(EditorStateNotifier controller) async {
    await controller.mergeBlocksDirectly(originalBlock, newBlock.id);
  }
}

class MergeBlocksCommand implements EditorCommand {
  final Block previousBlock;
  final Block currentBlock;
  final Block mergedBlock;
  final int currentBlockIndex;

  MergeBlocksCommand({
    required this.previousBlock,
    required this.currentBlock,
    required this.mergedBlock,
    required this.currentBlockIndex,
  });

  @override
  Future<void> execute(EditorStateNotifier controller) async {
    await controller.mergeBlocksDirectly(mergedBlock, currentBlock.id);
  }

  @override
  Future<void> undo(EditorStateNotifier controller) async {
    await controller.splitBlockDirectly(previousBlock, currentBlock, currentBlockIndex);
  }
}

class ConvertBlockCommand extends UpdateBlockCommand {
  ConvertBlockCommand({required super.oldBlock, required super.newBlock});
}

class DuplicateBlockCommand implements EditorCommand {
  final Block duplicatedBlock;
  final int insertIndex;

  DuplicateBlockCommand({
    required this.duplicatedBlock,
    required this.insertIndex,
  });

  @override
  Future<void> execute(EditorStateNotifier controller) async {
    await controller.insertBlockDirectly(duplicatedBlock, insertIndex);
  }

  @override
  Future<void> undo(EditorStateNotifier controller) async {
    await controller.deleteBlockDirectly(duplicatedBlock.id);
  }
}

class MoveBlockCommand implements EditorCommand {
  final String blockId;
  final String targetBlockId;
  final DropIntent intent;
  final String? originalParentBlockId;
  final double originalPosition;

  MoveBlockCommand({
    required this.blockId,
    required this.targetBlockId,
    required this.intent,
    required this.originalParentBlockId,
    required this.originalPosition,
  });

  bool _isExecuted = false;
  String? appliedParentBlockId;
  double? appliedPosition;

  @override
  Future<void> execute(EditorStateNotifier controller) async {
    if (!_isExecuted) {
      final result = await controller.moveBlockToIntent(
        sourceBlockId: blockId, 
        targetBlockId: targetBlockId, 
        intent: intent,
      );
      appliedParentBlockId = result.parentBlockId;
      appliedPosition = result.position;
      _isExecuted = true;
    } else {
      if (appliedPosition != null) {
        await controller.moveBlockToPosition(
          blockId: blockId,
          parentBlockId: appliedParentBlockId,
          position: appliedPosition!,
        );
      }
    }
  }

  @override
  Future<void> undo(EditorStateNotifier controller) async {
    await controller.moveBlockToPosition(
      blockId: blockId, 
      parentBlockId: originalParentBlockId, 
      position: originalPosition,
    );
  }
}
