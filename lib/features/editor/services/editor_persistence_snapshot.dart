import 'package:flutter/foundation.dart';
import 'editor_persistence_mutations.dart';

@immutable
class BlockSnapshot {
  final String blockId;
  final String pageId;
  final int version;
  final String? parentBlockId;
  final double position;
  final String type;
  final DateTime createdAt;
  final String? contentHash;
  final bool deleted;

  const BlockSnapshot({
    required this.blockId,
    required this.pageId,
    required this.version,
    this.parentBlockId,
    required this.position,
    required this.type,
    required this.createdAt,
    this.contentHash,
    required this.deleted,
  });

  BlockSnapshot copyWith({
    int? version,
    String? parentBlockId,
    double? position,
    String? type,
    String? contentHash,
    bool? deleted,
  }) {
    return BlockSnapshot(
      blockId: blockId,
      pageId: pageId,
      version: version ?? this.version,
      parentBlockId: parentBlockId ?? this.parentBlockId,
      position: position ?? this.position,
      type: type ?? this.type,
      createdAt: createdAt,
      contentHash: contentHash ?? this.contentHash,
      deleted: deleted ?? this.deleted,
    );
  }
}

class EditorPersistenceSnapshot {
  final String pageId;
  final Map<String, BlockSnapshot> _blocks;

  EditorPersistenceSnapshot(this.pageId, Map<String, BlockSnapshot> initialBlocks) 
    : _blocks = Map.of(initialBlocks);

  BlockSnapshot? getBlock(String blockId) => _blocks[blockId];
  
  Iterable<BlockSnapshot> get activeBlocks => _blocks.values.where((b) => !b.deleted);
  Iterable<BlockSnapshot> get allBlocks => _blocks.values;

  void updateBlock(BlockSnapshot block) {
    _blocks[block.blockId] = block;
  }

  void removeBlock(String blockId) {
    _blocks.remove(blockId);
  }

  void applyMutation(EditorPersistenceMutation mutation) {
    // 1. Apply structural changes
    if (mutation is SplitBlockMutation) {
      updateBlock(BlockSnapshot(
        blockId: mutation.newBlockId,
        pageId: mutation.pageId,
        version: 0, // will be updated by transition
        parentBlockId: mutation.newParentBlockId,
        position: mutation.newPosition,
        type: mutation.newType,
        createdAt: mutation.createdAt,
        contentHash: null,
        deleted: false,
      ),);
    } else if (mutation is InsertBlockMutation) {
      updateBlock(BlockSnapshot(
        blockId: mutation.blockId,
        pageId: mutation.pageId,
        version: 0, // will be updated by transition
        parentBlockId: mutation.parentBlockId,
        position: mutation.position,
        type: mutation.type,
        createdAt: mutation.createdAt,
        contentHash: null,
        deleted: false,
      ),);
    } else if (mutation is MoveBlockMutation) {
      final block = getBlock(mutation.blockId);
      if (block != null) {
        updateBlock(block.copyWith(
          parentBlockId: mutation.parentBlockId,
          position: mutation.position,
        ),);
      }
    } else if (mutation is ChangeBlockTypeMutation) {
      final block = getBlock(mutation.blockId);
      if (block != null) {
        updateBlock(block.copyWith(
          type: mutation.newType,
        ),);
      }
    } else if (mutation is UpdateBlockMutation) {
      final block = getBlock(mutation.blockId);
      if (block != null) {
        updateBlock(block.copyWith(
          contentHash: mutation.contentHash,
        ),);
      }
    }

    // 2. Apply strict version transitions to maintain sync with Coordinator
    for (final transition in mutation.versionTransitions) {
      final block = getBlock(transition.blockId);
      if (block == null) continue;

      if (transition.operation == VersionChangeOperation.increment) {
        updateBlock(block.copyWith(version: block.version + 1));
      } else if (transition.operation == VersionChangeOperation.create) {
        updateBlock(block.copyWith(version: 1));
      } else if (transition.operation == VersionChangeOperation.softDelete) {
        updateBlock(block.copyWith(deleted: true, version: block.version + 1));
      }
    }
  }
}
