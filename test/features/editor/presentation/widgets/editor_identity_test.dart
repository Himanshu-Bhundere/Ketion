import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/editor/presentation/widgets/editor_identity_registry.dart';

void main() {
  group('EditorIdentityRegistry', () {
    late EditorIdentityRegistry registry;

    setUp(() {
      registry = EditorIdentityRegistry();
    });

    test('Test 1: Initial mapping establishes correctly', () {
      registry.registerMapping(nodeId: 'node-1', blockId: 'block-1');
      expect(registry.containsNode('node-1'), isTrue);
      expect(registry.containsBlock('block-1'), isTrue);
      expect(registry.blockIdForNode('node-1'), 'block-1');
      expect(registry.nodeIdForBlock('block-1'), 'node-1');
    });

    test('Test 2: Reverse mapping round-trip', () {
      registry.registerMapping(nodeId: 'node-2', blockId: 'block-2');
      final blockId = registry.blockIdForNode('node-2');
      final nodeId = registry.nodeIdForBlock(blockId!);
      expect(nodeId, 'node-2');
    });

    test('Test 3: Unique mapping (1:1 constraint) and Test 10: Duplicate mapping rejected', () {
      registry.registerMapping(nodeId: 'node-1', blockId: 'block-1');
      
      // Try to map existing node to a new block
      expect(
        () => registry.registerMapping(nodeId: 'node-1', blockId: 'block-2'),
        throwsA(isA<AssertionError>()),
      );
      
      // Try to map existing block to a new node
      expect(
        () => registry.registerMapping(nodeId: 'node-2', blockId: 'block-1'),
        throwsA(isA<AssertionError>()),
      );
      
      // Mapping should remain unchanged
      expect(registry.blockIdForNode('node-1'), 'block-1');
      expect(registry.nodeIdForBlock('block-1'), 'node-1');
      expect(registry.containsNode('node-2'), isFalse);
      expect(registry.containsBlock('block-2'), isFalse);
    });

    test('Test 4: Delete mapping clears both sides (removeMappingForNode)', () {
      registry.registerMapping(nodeId: 'node-1', blockId: 'block-1');
      registry.removeMappingForNode('node-1');
      
      expect(registry.containsNode('node-1'), isFalse);
      expect(registry.containsBlock('block-1'), isFalse);
      expect(registry.blockIdForNode('node-1'), isNull);
      expect(registry.nodeIdForBlock('block-1'), isNull);
    });

    test('Test 4: Delete mapping clears both sides (removeMappingForBlock)', () {
      registry.registerMapping(nodeId: 'node-1', blockId: 'block-1');
      registry.removeMappingForBlock('block-1');
      
      expect(registry.containsNode('node-1'), isFalse);
      expect(registry.containsBlock('block-1'), isFalse);
    });

    test('Clear removes all mappings', () {
      registry.registerMapping(nodeId: 'node-1', blockId: 'block-1');
      registry.registerMapping(nodeId: 'node-2', blockId: 'block-2');
      
      registry.clear();
      
      expect(registry.containsNode('node-1'), isFalse);
      expect(registry.containsNode('node-2'), isFalse);
      expect(registry.mappedNodeIds.isEmpty, isTrue);
    });

    test('assertConsistent passes for valid state', () {
      registry.registerMapping(nodeId: 'node-1', blockId: 'block-1');
      expect(() => registry.assertConsistent(), returnsNormally);
    });
  });
}
