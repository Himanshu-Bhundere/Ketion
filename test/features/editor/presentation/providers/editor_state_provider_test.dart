import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/editor/domain/commands/editor_command.dart';
import 'package:ketion/features/editor/presentation/providers/editor_state_provider.dart';

class FailingCommand extends EditorCommand {
  @override
  Future<void> execute(EditorStateNotifier stateNotifier) async {
    throw Exception('Simulated DB/Queue failure');
  }

  @override
  Future<void> undo(EditorStateNotifier stateNotifier) async {
    // Should not be called
  }
}

class SuccessCommand extends EditorCommand {
  bool executed = false;
  bool undone = false;

  @override
  Future<void> execute(EditorStateNotifier stateNotifier) async {
    executed = true;
  }

  @override
  Future<void> undo(EditorStateNotifier stateNotifier) async {
    undone = true;
  }
}

void main() {
  group('EditorStateNotifier - Command State Consistency', () {
    test('executeCommand adds to undoStack and clears redoStack on success', () async {
      final container = ProviderContainer();
      final notifier = container.read(editorStateProvider('test_page').notifier);
      
      final command = SuccessCommand();
      await notifier.executeCommand(command);
      
      expect(command.executed, isTrue);
      // We can't directly read _undoStack, but we can call undo()
      // and verify that the command's undo() was called.
      await notifier.undo();
      expect(command.undone, isTrue);
    });

    test('executeCommand DOES NOT add to undoStack on failure', () async {
      final container = ProviderContainer();
      final notifier = container.read(editorStateProvider('test_page').notifier);
      
      // First, add a successful command so we know the stack has 1 item
      final successCommand = SuccessCommand();
      await notifier.executeCommand(successCommand);
      
      // Now, try a failing command
      final failingCommand = FailingCommand();
      try {
        await notifier.executeCommand(failingCommand);
        fail('Should have thrown');
      } catch (e) {
        expect(e.toString(), contains('Simulated DB/Queue failure'));
      }
      
      // Now, call undo. It should undo the FIRST command, not the failing one.
      await notifier.undo();
      expect(successCommand.undone, isTrue);
    });
  });
}
