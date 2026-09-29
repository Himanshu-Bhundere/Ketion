import 'package:flutter/foundation.dart';

enum VersionChangeOperation { increment, create, softDelete, none }

class BlockVersionPrecondition {
  final String blockId;
  final int? expectedVersion;

  const BlockVersionPrecondition({
    required this.blockId,
    this.expectedVersion,
  });
}

class BlockVersionTransition {
  final String blockId;
  final VersionChangeOperation operation;

  const BlockVersionTransition({
    required this.blockId,
    required this.operation,
  });
}

@immutable
sealed class EditorPersistenceMutation {
  final String pageId;
  final Set<String> affectedBlockIds;
  final DateTime createdAt; // Time the mutation was built

  // Preconditions required before this mutation may execute atomically.
  List<BlockVersionPrecondition> get versionPreconditions;
  
  List<BlockVersionTransition> get versionTransitions;

  EditorPersistenceMutation rebase(Map<String, int> currentVersions);

  const EditorPersistenceMutation({
    required this.pageId,
    required this.affectedBlockIds,
    required this.createdAt,
  });
}

abstract class ContentMutation extends EditorPersistenceMutation {
  const ContentMutation({
    required super.pageId,
    required super.affectedBlockIds,
    required super.createdAt,
  });
}

abstract class StructuralMutation extends EditorPersistenceMutation {
  const StructuralMutation({
    required super.pageId,
    required super.affectedBlockIds,
    required super.createdAt,
  });
}

class UpdateBlockMutation extends ContentMutation {
  final String blockId;
  final String data;
  final String type;
  final String? parentBlockId;
  final double position;
  final int expectedVersion;
  final String? contentHash;
  final DateTime blockCreatedAt;

  UpdateBlockMutation({
    required super.pageId,
    required this.blockId,
    required this.data,
    required this.type,
    this.parentBlockId,
    required this.position,
    required this.expectedVersion,
    this.contentHash,
    required this.blockCreatedAt,
    required super.createdAt,
  }) : super(affectedBlockIds: {blockId});

  @override
  List<BlockVersionPrecondition> get versionPreconditions => [
    BlockVersionPrecondition(blockId: blockId, expectedVersion: expectedVersion),
  ];

  @override
  List<BlockVersionTransition> get versionTransitions => [
    BlockVersionTransition(blockId: blockId, operation: VersionChangeOperation.increment),
  ];

  @override
  EditorPersistenceMutation rebase(Map<String, int> currentVersions) {
    if (currentVersions.containsKey(blockId) && currentVersions[blockId] != expectedVersion) {
      return UpdateBlockMutation(
        pageId: pageId,
        blockId: blockId,
        data: data,
        type: type,
        parentBlockId: parentBlockId,
        position: position,
        expectedVersion: currentVersions[blockId]!,
        contentHash: contentHash,
        blockCreatedAt: blockCreatedAt,
        createdAt: createdAt,
      );
    }
    return this;
  }
}

class InsertBlockMutation extends StructuralMutation {
  final String blockId;
  final String data;
  final String? parentBlockId;
  final double position;
  final String type;
  final int expectedVersion; // For sync matching if needed

  InsertBlockMutation({
    required super.pageId,
    required this.blockId,
    required this.data,
    this.parentBlockId,
    required this.position,
    required this.type,
    required this.expectedVersion,
    required super.createdAt,
  }) : super(affectedBlockIds: {blockId});

  @override
  List<BlockVersionPrecondition> get versionPreconditions => [];

  @override
  List<BlockVersionTransition> get versionTransitions => [
    BlockVersionTransition(blockId: blockId, operation: VersionChangeOperation.create),
  ];

  @override
  EditorPersistenceMutation rebase(Map<String, int> currentVersions) {
    // Inserts don't typically have preconditions that need rebasing, but just in case
    if (currentVersions.containsKey(blockId) && currentVersions[blockId] != expectedVersion) {
      return InsertBlockMutation(
        pageId: pageId,
        blockId: blockId,
        data: data,
        parentBlockId: parentBlockId,
        position: position,
        type: type,
        expectedVersion: currentVersions[blockId]!,
        createdAt: createdAt,
      );
    }
    return this;
  }
}

class DeleteBlockMutation extends StructuralMutation {
  final String blockId;
  final int expectedVersion;

  DeleteBlockMutation({
    required super.pageId,
    required this.blockId,
    required this.expectedVersion,
    required super.createdAt,
  }) : super(affectedBlockIds: {blockId});

  @override
  List<BlockVersionPrecondition> get versionPreconditions => [
    BlockVersionPrecondition(blockId: blockId, expectedVersion: expectedVersion),
  ];

  @override
  List<BlockVersionTransition> get versionTransitions => [
    BlockVersionTransition(blockId: blockId, operation: VersionChangeOperation.softDelete),
  ];

  @override
  EditorPersistenceMutation rebase(Map<String, int> currentVersions) {
    if (currentVersions.containsKey(blockId) && currentVersions[blockId] != expectedVersion) {
      return DeleteBlockMutation(
        pageId: pageId,
        blockId: blockId,
        expectedVersion: currentVersions[blockId]!,
        createdAt: createdAt,
      );
    }
    return this;
  }
}

class RestoreBlockMutation extends StructuralMutation {
  final String blockId;
  final String data;
  final String type;
  final String? parentBlockId;
  final double position;
  final int expectedVersion;
  final DateTime blockCreatedAt;

  RestoreBlockMutation({
    required super.pageId,
    required this.blockId,
    required this.data,
    required this.type,
    this.parentBlockId,
    required this.position,
    required this.expectedVersion,
    required this.blockCreatedAt,
    required super.createdAt,
  }) : super(affectedBlockIds: {blockId});

  @override
  List<BlockVersionPrecondition> get versionPreconditions => [
    BlockVersionPrecondition(blockId: blockId, expectedVersion: expectedVersion),
  ];

  @override
  List<BlockVersionTransition> get versionTransitions => [
    BlockVersionTransition(blockId: blockId, operation: VersionChangeOperation.increment),
  ];

  @override
  EditorPersistenceMutation rebase(Map<String, int> currentVersions) {
    if (currentVersions.containsKey(blockId) && currentVersions[blockId] != expectedVersion) {
      return RestoreBlockMutation(
        pageId: pageId,
        blockId: blockId,
        data: data,
        type: type,
        parentBlockId: parentBlockId,
        position: position,
        expectedVersion: currentVersions[blockId]!,
        blockCreatedAt: blockCreatedAt,
        createdAt: createdAt,
      );
    }
    return this;
  }
}

class SplitBlockMutation extends StructuralMutation {
  final String originalBlockId;
  final String originalData;
  final int expectedVersion;
  final String? originalParentBlockId;
  final double originalPosition;
  final DateTime originalBlockCreatedAt;
  
  final String newBlockId;
  final String newData;
  final String newType;
  final String? newParentBlockId;
  final double newPosition;

  SplitBlockMutation({
    required super.pageId,
    required this.originalBlockId,
    required this.originalData,
    required this.expectedVersion,
    this.originalParentBlockId,
    required this.originalPosition,
    required this.originalBlockCreatedAt,
    required this.newBlockId,
    required this.newData,
    required this.newType,
    this.newParentBlockId,
    required this.newPosition,
    required super.createdAt,
  }) : super(affectedBlockIds: {originalBlockId, newBlockId});

  @override
  List<BlockVersionPrecondition> get versionPreconditions => [
    BlockVersionPrecondition(blockId: originalBlockId, expectedVersion: expectedVersion),
  ];

  @override
  List<BlockVersionTransition> get versionTransitions => [
    BlockVersionTransition(blockId: originalBlockId, operation: VersionChangeOperation.increment),
    BlockVersionTransition(blockId: newBlockId, operation: VersionChangeOperation.create),
  ];

  @override
  EditorPersistenceMutation rebase(Map<String, int> currentVersions) {
    if (currentVersions.containsKey(originalBlockId) && currentVersions[originalBlockId] != expectedVersion) {
      return SplitBlockMutation(
        pageId: pageId,
        originalBlockId: originalBlockId,
        originalData: originalData,
        expectedVersion: currentVersions[originalBlockId]!,
        originalParentBlockId: originalParentBlockId,
        originalPosition: originalPosition,
        originalBlockCreatedAt: originalBlockCreatedAt,
        newBlockId: newBlockId,
        newData: newData,
        newType: newType,
        newParentBlockId: newParentBlockId,
        newPosition: newPosition,
        createdAt: createdAt,
      );
    }
    return this;
  }
}

class MergeBlocksMutation extends StructuralMutation {
  final String survivorBlockId;
  final String survivorData;
  final int survivorExpectedVersion;
  final DateTime survivorBlockCreatedAt;
  
  final String victimBlockId;
  final int victimExpectedVersion;

  MergeBlocksMutation({
    required super.pageId,
    required this.survivorBlockId,
    required this.survivorData,
    required this.survivorExpectedVersion,
    required this.survivorBlockCreatedAt,
    required this.victimBlockId,
    required this.victimExpectedVersion,
    required super.createdAt,
  }) : super(affectedBlockIds: {survivorBlockId, victimBlockId});

  @override
  List<BlockVersionPrecondition> get versionPreconditions => [
    BlockVersionPrecondition(blockId: survivorBlockId, expectedVersion: survivorExpectedVersion),
    BlockVersionPrecondition(blockId: victimBlockId, expectedVersion: victimExpectedVersion),
  ];

  @override
  List<BlockVersionTransition> get versionTransitions => [
    BlockVersionTransition(blockId: survivorBlockId, operation: VersionChangeOperation.increment),
    BlockVersionTransition(blockId: victimBlockId, operation: VersionChangeOperation.softDelete),
  ];

  @override
  EditorPersistenceMutation rebase(Map<String, int> currentVersions) {
    bool changed = false;
    int rebasedSurvivorVersion = survivorExpectedVersion;
    int rebasedVictimVersion = victimExpectedVersion;
    
    if (currentVersions.containsKey(survivorBlockId) && currentVersions[survivorBlockId] != survivorExpectedVersion) {
      rebasedSurvivorVersion = currentVersions[survivorBlockId]!;
      changed = true;
    }
    if (currentVersions.containsKey(victimBlockId) && currentVersions[victimBlockId] != victimExpectedVersion) {
      rebasedVictimVersion = currentVersions[victimBlockId]!;
      changed = true;
    }
    
    if (changed) {
      return MergeBlocksMutation(
        pageId: pageId,
        survivorBlockId: survivorBlockId,
        survivorData: survivorData,
        survivorExpectedVersion: rebasedSurvivorVersion,
        survivorBlockCreatedAt: survivorBlockCreatedAt,
        victimBlockId: victimBlockId,
        victimExpectedVersion: rebasedVictimVersion,
        createdAt: createdAt,
      );
    }
    return this;
  }
}

class MoveBlockMutation extends StructuralMutation {
  final String blockId;
  final String? parentBlockId;
  final double position;
  final int expectedVersion;
  final DateTime blockCreatedAt;

  MoveBlockMutation({
    required super.pageId,
    required this.blockId,
    this.parentBlockId,
    required this.position,
    required this.expectedVersion,
    required this.blockCreatedAt,
    required super.createdAt,
  }) : super(affectedBlockIds: {blockId});

  @override
  List<BlockVersionPrecondition> get versionPreconditions => [
    BlockVersionPrecondition(blockId: blockId, expectedVersion: expectedVersion),
  ];

  @override
  List<BlockVersionTransition> get versionTransitions => [
    BlockVersionTransition(blockId: blockId, operation: VersionChangeOperation.increment),
  ];

  @override
  EditorPersistenceMutation rebase(Map<String, int> currentVersions) {
    if (currentVersions.containsKey(blockId) && currentVersions[blockId] != expectedVersion) {
      return MoveBlockMutation(
        pageId: pageId,
        blockId: blockId,
        parentBlockId: parentBlockId,
        position: position,
        expectedVersion: currentVersions[blockId]!,
        blockCreatedAt: blockCreatedAt,
        createdAt: createdAt,
      );
    }
    return this;
  }
}

class ChangeBlockTypeMutation extends StructuralMutation {
  final String blockId;
  final String newType;
  final String newData;
  final int expectedVersion;
  final DateTime blockCreatedAt;

  ChangeBlockTypeMutation({
    required super.pageId,
    required this.blockId,
    required this.newType,
    required this.newData,
    required this.expectedVersion,
    required this.blockCreatedAt,
    required super.createdAt,
  }) : super(affectedBlockIds: {blockId});

  @override
  List<BlockVersionPrecondition> get versionPreconditions => [
    BlockVersionPrecondition(blockId: blockId, expectedVersion: expectedVersion),
  ];

  @override
  List<BlockVersionTransition> get versionTransitions => [
    BlockVersionTransition(blockId: blockId, operation: VersionChangeOperation.increment),
  ];

  @override
  EditorPersistenceMutation rebase(Map<String, int> currentVersions) {
    if (currentVersions.containsKey(blockId) && currentVersions[blockId] != expectedVersion) {
      return ChangeBlockTypeMutation(
        pageId: pageId,
        blockId: blockId,
        newType: newType,
        newData: newData,
        expectedVersion: currentVersions[blockId]!,
        blockCreatedAt: blockCreatedAt,
        createdAt: createdAt,
      );
    }
    return this;
  }
}
