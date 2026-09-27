import '../../../blocks/domain/entities/block.dart';
import '../../presentation/providers/editor_state_provider.dart';

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

class MoveBlocksCommand implements EditorCommand {
  final List<Block> oldBlocks;
  final List<Block> newBlocks;

  MoveBlocksCommand({required this.oldBlocks, required this.newBlocks});

  @override
  Future<void> execute(EditorStateNotifier controller) async {
    for (var b in newBlocks) {
      await controller.updateBlockDirectly(b);
    }
  }

  @override
  Future<void> undo(EditorStateNotifier controller) async {
    for (var b in oldBlocks) {
      await controller.updateBlockDirectly(b);
    }
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
