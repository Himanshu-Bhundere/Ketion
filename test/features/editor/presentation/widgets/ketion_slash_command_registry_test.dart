import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import 'package:ketion/features/editor/presentation/table/ketion_table_node.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_slash_command_registry.dart';

void main() {
  group('KetionSlashCommandRegistry - inheritedPlacementMetadata', () {
    test('returns empty map when node is not found in document', () {
      final doc = MutableDocument(nodes: []);
      final metadata = KetionSlashCommandRegistry.inheritedPlacementMetadata(
        'non-existent-id',
        doc,
      );

      expect(metadata, isEmpty);
    });

    test('returns empty map when node has no placement metadata', () {
      final node = ParagraphNode(
        id: 'node-1',
        text: AttributedText('Regular paragraph'),
      );
      final doc = MutableDocument(nodes: [node]);

      final metadata = KetionSlashCommandRegistry.inheritedPlacementMetadata(
        'node-1',
        doc,
      );

      expect(metadata, isEmpty);
    });

    test('extracts both parentBlockId and depth when present on node', () {
      final node = ParagraphNode(
        id: 'child-node',
        text: AttributedText('Toggle child paragraph'),
        metadata: const {
          'parentBlockId': 'toggle-block-123',
          'depth': 2,
        },
      );
      final doc = MutableDocument(nodes: [node]);

      final metadata = KetionSlashCommandRegistry.inheritedPlacementMetadata(
        'child-node',
        doc,
      );

      expect(metadata['parentBlockId'], 'toggle-block-123');
      expect(metadata['depth'], 2);
      expect(metadata.length, 2);
    });

    test('extracts parentBlockId only when depth is missing', () {
      final node = ParagraphNode(
        id: 'child-node',
        text: AttributedText('Child'),
        metadata: const {
          'parentBlockId': 'parent-456',
        },
      );
      final doc = MutableDocument(nodes: [node]);

      final metadata = KetionSlashCommandRegistry.inheritedPlacementMetadata(
        'child-node',
        doc,
      );

      expect(metadata['parentBlockId'], 'parent-456');
      expect(metadata.containsKey('depth'), isFalse);
    });

    test('extracts depth only when parentBlockId is missing', () {
      final node = ParagraphNode(
        id: 'child-node',
        text: AttributedText('Indented block'),
        metadata: const {
          'depth': 3,
        },
      );
      final doc = MutableDocument(nodes: [node]);

      final metadata = KetionSlashCommandRegistry.inheritedPlacementMetadata(
        'child-node',
        doc,
      );

      expect(metadata['depth'], 3);
      expect(metadata.containsKey('parentBlockId'), isFalse);
    });

    test('ignores empty parentBlockId string and invalid depth types', () {
      final node = ParagraphNode(
        id: 'child-node',
        text: AttributedText('Node'),
        metadata: const {
          'parentBlockId': '',
          'depth': 'invalid-depth',
        },
      );
      final doc = MutableDocument(nodes: [node]);

      final metadata = KetionSlashCommandRegistry.inheritedPlacementMetadata(
        'child-node',
        doc,
      );

      expect(metadata, isEmpty);
    });
  });

  group('KetionSlashCommandRegistry - slash insertions preserve placement', () {
    late MutableDocument doc;
    late ParagraphNode toggleChild;

    setUp(() {
      toggleChild = ParagraphNode(
        id: 'toggle-child-p',
        text: AttributedText('/'),
        metadata: const {
          'parentBlockId': 'toggle-header-block',
          'depth': 1,
        },
      );
      doc = MutableDocument(nodes: [toggleChild]);
    });

    test('divider slash command preserves parentBlockId and depth on HorizontalRuleNode', () {
      final dividerCommand = KetionSlashCommandRegistry.allCommands
          .firstWhere((cmd) => cmd.id == 'divider');

      final requests = dividerCommand.getEditRequestsWithDoc('toggle-child-p', doc);
      expect(requests, isNotEmpty);
      expect(requests.first, isA<InsertNodeBeforeNodeRequest>());

      final insertReq = requests.first as InsertNodeBeforeNodeRequest;
      final insertedNode = insertReq.newNode;
      expect(insertedNode, isA<HorizontalRuleNode>());
      expect(insertedNode.metadata['parentBlockId'], 'toggle-header-block');
      expect(insertedNode.metadata['depth'], 1);
    });

    test('table slash command preserves parentBlockId and depth on KetionTableNode', () {
      final tableCommand = KetionSlashCommandRegistry.allCommands
          .firstWhere((cmd) => cmd.id == 'table');

      final requests = tableCommand.getEditRequestsWithDoc('toggle-child-p', doc);
      expect(requests, isNotEmpty);
      expect(requests.first, isA<InsertNodeBeforeNodeRequest>());

      final insertReq = requests.first as InsertNodeBeforeNodeRequest;
      final insertedNode = insertReq.newNode;
      expect(insertedNode, isA<KetionTableNode>());
      expect(insertedNode.metadata['parentBlockId'], 'toggle-header-block');
      expect(insertedNode.metadata['depth'], 1);
      expect(insertedNode.metadata['columnCount'], 3);
    });

    test('media slash commands (image, video, audio, pdf, file) inherit placement metadata', () {
      final mediaCommands = ['image', 'video', 'audio', 'pdf', 'file'];

      for (final cmdId in mediaCommands) {
        final command = KetionSlashCommandRegistry.allCommands
            .firstWhere((cmd) => cmd.id == cmdId);

        final requests = command.getEditRequestsWithDoc('toggle-child-p', doc);
        expect(requests, isNotEmpty, reason: 'Command $cmdId should return requests');
        expect(requests.first, isA<InsertNodeAfterNodeRequest>());

        final insertReq = requests.first as InsertNodeAfterNodeRequest;
        final insertedNode = insertReq.newNode;
        expect(
          insertedNode.metadata['parentBlockId'],
          'toggle-header-block',
          reason: '$cmdId must inherit parentBlockId',
        );
        expect(
          insertedNode.metadata['depth'],
          1,
          reason: '$cmdId must inherit depth',
        );
      }
    });
  });
}
