import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_toggle_keyboard_actions.dart';

void main() {
  group('isEmptyToggleExitLine', () {
    test('returns true for completely empty text', () {
      final node = ParagraphNode(
        id: '1',
        text: AttributedText(''),
      );
      expect(isEmptyToggleExitLine(node), isTrue);
    });

    test('returns true for spaces only', () {
      final node = ParagraphNode(
        id: '2',
        text: AttributedText('   '),
      );
      expect(isEmptyToggleExitLine(node), isTrue);
    });

    test('returns true for tabs and mixed whitespace', () {
      final node = ParagraphNode(
        id: '3',
        text: AttributedText('\t  \n  \t'),
      );
      expect(isEmptyToggleExitLine(node), isTrue);
    });

    test('returns false for text with content', () {
      final node = ParagraphNode(
        id: '4',
        text: AttributedText('Hello'),
      );
      expect(isEmptyToggleExitLine(node), isFalse);
    });

    test('returns false for whitespace surrounding text', () {
      final node = ParagraphNode(
        id: '5',
        text: AttributedText('  hello world  '),
      );
      expect(isEmptyToggleExitLine(node), isFalse);
    });
  });

  group('executeToggleBodyEnter empty and whitespace exit', () {
    test('exits toggle when child paragraph is whitespace only', () {
      final toggleNode = ParagraphNode(
        id: 'toggle-1',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockId': 'block-toggle-1',
          'blockType': 'toggle',
          'depth': 0,
        },
      );

      final childNode = ParagraphNode(
        id: 'child-1',
        text: AttributedText('   '),
        metadata: const {
          'blockId': 'block-child-1',
          'parentBlockId': 'block-toggle-1',
          'depth': 1,
        },
      );

      final document = MutableDocument(nodes: [toggleNode, childNode]);
      final composer = MutableDocumentComposer();
      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.cast<EditRequestHandler>(),
        ],
      );

      final result = executeToggleBodyEnter(
        editor: editor,
        document: document,
        node: childNode,
        caretOffset: 1,
      );

      expect(result, isNotNull);
      // Exiting the toggle moves depth from 1 to the toggle's depth (0)
      expect(result!.metadata['depth'], equals(0));
      // parentBlockId should be removed because toggle is root (depth 0)
      expect(result.metadata.containsKey('parentBlockId'), isFalse);
    });

    test('does not exit toggle when child paragraph has text', () {
      final toggleNode = ParagraphNode(
        id: 'toggle-1',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockId': 'block-toggle-1',
          'blockType': 'toggle',
          'depth': 0,
        },
      );

      final childNode = ParagraphNode(
        id: 'child-1',
        text: AttributedText('Child paragraph'),
        metadata: const {
          'blockId': 'block-child-1',
          'parentBlockId': 'block-toggle-1',
          'depth': 1,
        },
      );

      final document = MutableDocument(nodes: [toggleNode, childNode]);
      final composer = MutableDocumentComposer();
      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.cast<EditRequestHandler>(),
        ],
      );

      final result = executeToggleBodyEnter(
        editor: editor,
        document: document,
        node: childNode,
        caretOffset: childNode.text.length,
      );

      expect(result, isNotNull);
      // New sibling inserted within toggle keeps depth 1 and parentBlockId
      expect(result!.metadata['depth'], equals(1));
      expect(result.metadata['parentBlockId'], equals('block-toggle-1'));
    });
  });

  group('findNearestToggleAncestor', () {
    test('resolves toggle ancestor structurally when parentBlockId is missing', () {
      final toggleNode = ParagraphNode(
        id: 'toggle-1',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockId': 'block-toggle-1',
          'blockType': 'toggle',
          'depth': 0,
        },
      );

      final childNode = ParagraphNode(
        id: 'child-no-parent',
        text: AttributedText('Child without parentBlockId'),
        metadata: const {
          'blockId': 'block-child-1',
          'depth': 1,
        },
      );

      final document = MutableDocument(nodes: [toggleNode, childNode]);

      final ancestor = findNearestToggleAncestor(
        node: childNode,
        document: document,
      );

      expect(ancestor, isNotNull);
      expect(ancestor!.id, equals('toggle-1'));
    });

    test('does not associate with toggle across a non-toggle root boundary', () {
      final toggleNode = ParagraphNode(
        id: 'toggle-1',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockId': 'block-toggle-1',
          'blockType': 'toggle',
          'depth': 0,
        },
      );

      final rootNode = ParagraphNode(
        id: 'root-1',
        text: AttributedText('Root paragraph'),
        metadata: const {
          'blockId': 'block-root-1',
          'depth': 0,
        },
      );

      final orphanedChild = ParagraphNode(
        id: 'child-2',
        text: AttributedText('Orphaned deep child'),
        metadata: const {
          'blockId': 'block-child-2',
          'depth': 1,
        },
      );

      final document = MutableDocument(nodes: [toggleNode, rootNode, orphanedChild]);

      final ancestor = findNearestToggleAncestor(
        node: orphanedChild,
        document: document,
      );

      // Traversal backwards encounters rootNode (depth 0, not a toggle), so it stops.
      expect(ancestor, isNull);
    });
  });

  group('insertExitParagraphAfterToggle', () {
    test('inserts a new regular paragraph after toggle subtree', () {
      final toggleNode = ParagraphNode(
        id: 'toggle-1',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockId': 'block-toggle-1',
          'blockType': 'toggle',
          'depth': 0,
        },
      );

      final childNode = ParagraphNode(
        id: 'child-1',
        text: AttributedText('Toggle Child'),
        metadata: const {
          'blockId': 'block-child-1',
          'parentBlockId': 'block-toggle-1',
          'depth': 1,
        },
      );

      final document = MutableDocument(nodes: [toggleNode, childNode]);
      final composer = MutableDocumentComposer();
      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.cast<EditRequestHandler>(),
        ],
      );

      final result = insertExitParagraphAfterToggle(
        editor: editor,
        document: document,
        toggleNode: toggleNode,
      );

      expect(result, isNotNull);
      expect(document.nodeCount, equals(3));
      expect(document.getNodeAt(2)!.id, equals(result!.id));
      expect(result.metadata['depth'], equals(0));
    });
  });

  group('exitToggleBodyOnEscape', () {
    test('inserts a new paragraph after toggle, preserving child content', () {
      final toggleNode = ParagraphNode(
        id: 'toggle-1',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockId': 'block-toggle-1',
          'blockType': 'toggle',
          'depth': 0,
        },
      );

      final childNode = ParagraphNode(
        id: 'child-1',
        text: AttributedText('Child paragraph with text'),
        metadata: const {
          'blockId': 'block-child-1',
          'parentBlockId': 'block-toggle-1',
          'depth': 1,
        },
      );

      final document = MutableDocument(nodes: [toggleNode, childNode]);
      final composer = MutableDocumentComposer();
      final editor = Editor(
        editables: {
          Editor.documentKey: document,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          ...defaultRequestHandlers.cast<EditRequestHandler>(),
        ],
      );

      final result = exitToggleBodyOnEscape(
        editor: editor,
        document: document,
        node: childNode,
      );

      expect(result, isNotNull);
      expect(result!.text.toPlainText(), isEmpty);
      expect(result.metadata['depth'], equals(0));
      expect(result.metadata.containsKey('parentBlockId'), isFalse);
      expect(document.nodeCount, equals(3));
      expect(document.getNodeAt(0)!.id, equals('toggle-1'));
      expect(document.getNodeAt(1)!.id, equals('child-1'));
      expect(document.getNodeAt(2)!.id, equals(result.id));
      expect((document.getNodeAt(1) as TextNode).text.toPlainText(), equals('Child paragraph with text'));
    });
  });
}
