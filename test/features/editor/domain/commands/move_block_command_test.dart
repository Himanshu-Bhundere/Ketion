import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/domain/commands/editor_command.dart';
import 'package:ketion/features/editor/domain/models/drop_intent.dart';
import 'package:ketion/features/editor/presentation/providers/editor_state_provider.dart';

class FakeEditorStateNotifier extends EditorStateNotifier {
  final List<String> log = [];

  @override
  Future<List<Block>> build(String arg) async {
    return [];
  }

  @override
  Future<({String? parentBlockId, double position})> moveBlockToIntent({
    required String sourceBlockId,
    required String targetBlockId,
    required DropIntent intent,
  }) async {
    log.add('moveBlockToIntent($sourceBlockId, $targetBlockId, $intent)');
    return (parentBlockId: 'newParent', position: 10.0);
  }

  @override
  Future<void> moveBlockToPosition({
    required String blockId,
    required String? parentBlockId,
    required double position,
  }) async {
    log.add('moveBlockToPosition($blockId, $parentBlockId, $position)');
  }
}

void main() {
  group('MoveBlockCommand', () {
    test('execute calls moveBlockToIntent on first run', () async {
      final notifier = FakeEditorStateNotifier();
      final command = MoveBlockCommand(
        blockId: 'block_1',
        targetBlockId: 'block_2',
        intent: const DropIntent.after('block_2'),
        originalParentBlockId: null,
        originalPosition: 0.0,
      );

      await command.execute(notifier);

      expect(notifier.log.length, 1);
      expect(notifier.log[0], 'moveBlockToIntent(block_1, block_2, DropIntent.after(targetBlockId: block_2))');
    });

    test('execute calls moveBlockToPosition on subsequent runs (redo)', () async {
      final notifier = FakeEditorStateNotifier();
      final command = MoveBlockCommand(
        blockId: 'block_1',
        targetBlockId: 'block_2',
        intent: const DropIntent.after('block_2'),
        originalParentBlockId: null,
        originalPosition: 0.0,
      );

      await command.execute(notifier);
      notifier.log.clear();

      // Redo
      await command.execute(notifier);

      expect(notifier.log.length, 1);
      expect(notifier.log[0], 'moveBlockToPosition(block_1, newParent, 10.0)');
    });

    test('undo calls moveBlockToPosition with original position', () async {
      final notifier = FakeEditorStateNotifier();
      final command = MoveBlockCommand(
        blockId: 'block_1',
        targetBlockId: 'block_2',
        intent: const DropIntent.after('block_2'),
        originalParentBlockId: 'oldParent',
        originalPosition: 5.0,
      );

      await command.execute(notifier);
      notifier.log.clear();

      await command.undo(notifier);

      expect(notifier.log.length, 1);
      expect(notifier.log[0], 'moveBlockToPosition(block_1, oldParent, 5.0)');
    });
  });
}
