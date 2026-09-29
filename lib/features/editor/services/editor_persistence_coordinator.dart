import 'dart:async';
import 'package:flutter/foundation.dart';
import 'editor_persistence_mutations.dart';

enum CoordinatorState { active, flushing, closing, closed }

abstract class EditorPersistenceGateway {
  Future<void> executeMutation(EditorPersistenceMutation mutation);
}

class EditorPersistenceCoordinator {
  final EditorPersistenceGateway gateway;

  CoordinatorState _state = CoordinatorState.active;
  final List<EditorPersistenceMutation> _queue = [];
  final List<EditorPersistenceMutation> _failed = [];
  final List<EditorPersistenceMutation> _blocked = [];
  
  final Map<String, UpdateBlockMutation> _pendingUpdates = {};
  final Map<String, int> _pendingVersionState = {};
  bool _isProcessing = false;

  final _successController = StreamController<EditorPersistenceMutation>.broadcast();
  Stream<EditorPersistenceMutation> get onMutationSuccess => _successController.stream;

  EditorPersistenceCoordinator({required this.gateway});

  bool get hasPendingMutations =>
      _queue.isNotEmpty || _pendingUpdates.isNotEmpty || _failed.isNotEmpty || _blocked.isNotEmpty;
  bool get hasFailedMutations => _failed.isNotEmpty;

  /// Synchronously accepts ownership of the mutation.
  /// Returns false if the coordinator is closed and rejected the mutation.
  /// Returns true if accepted.
  bool enqueue(EditorPersistenceMutation mutation) {
    if (_state == CoordinatorState.closed) {
      debugPrint('KETION: Coordinator closed, rejecting mutation');
      return false;
    }

    if (mutation is UpdateBlockMutation) {
      final existing = _pendingUpdates[mutation.blockId];
      if (existing != null) {
        // Coalescing is the replacement of a queued mutation.
        // It does NOT consume a new version transition.
        _pendingUpdates[mutation.blockId] = UpdateBlockMutation(
          pageId: mutation.pageId,
          blockId: mutation.blockId,
          data: mutation.data,
          type: mutation.type,
          parentBlockId: mutation.parentBlockId,
          position: mutation.position,
          expectedVersion: existing.expectedVersion, // Keep original expected version
          blockCreatedAt: existing.blockCreatedAt,
          contentHash: mutation.contentHash,
          createdAt: mutation.createdAt,
        );
      } else {
        // Look for the last mutation in _queue affecting this block
        EditorPersistenceMutation? lastQueued;
        int lastQueuedIndex = -1;
        for (int i = _queue.length - 1; i >= 0; i--) {
          if (_queue[i].affectedBlockIds.contains(mutation.blockId)) {
            lastQueued = _queue[i];
            lastQueuedIndex = i;
            break;
          }
        }

        if (lastQueued != null && lastQueued is UpdateBlockMutation) {
          // Coalescing is the replacement of a queued mutation.
          // It does NOT consume a new version transition.
          _queue[lastQueuedIndex] = UpdateBlockMutation(
            pageId: mutation.pageId,
            blockId: mutation.blockId,
            data: mutation.data,
            type: mutation.type,
            parentBlockId: mutation.parentBlockId,
            position: mutation.position,
            expectedVersion: lastQueued.expectedVersion, // Keep original expected version
            blockCreatedAt: lastQueued.blockCreatedAt,
            contentHash: mutation.contentHash,
            createdAt: mutation.createdAt,
          );
        } else {
          final rebased = mutation.rebase(_pendingVersionState) as UpdateBlockMutation;
          _applyTransitions(rebased);
          _pendingUpdates[rebased.blockId] = rebased;
        }
      }
    } else {
      _flushPendingUpdatesToQueue();
      final rebased = mutation.rebase(_pendingVersionState);
      _applyTransitions(rebased);
      _queue.add(rebased);
    }
    
    _scheduleProcessing();
    return true;
  }

  void _applyTransitions(EditorPersistenceMutation mutation) {
    for (final transition in mutation.versionTransitions) {
      final currentExpected = _pendingVersionState[transition.blockId] ?? _getPreconditionVersion(mutation, transition.blockId) ?? 0;
      if (transition.operation == VersionChangeOperation.increment) {
        _pendingVersionState[transition.blockId] = currentExpected + 1;
      } else if (transition.operation == VersionChangeOperation.create) {
        _pendingVersionState[transition.blockId] = 1;
      } else if (transition.operation == VersionChangeOperation.softDelete) {
        _pendingVersionState[transition.blockId] = currentExpected + 1;
      }
    }
  }

  int? _getPreconditionVersion(EditorPersistenceMutation mutation, String blockId) {
    for (final pre in mutation.versionPreconditions) {
      if (pre.blockId == blockId) return pre.expectedVersion;
    }
    return null;
  }

  void _flushPendingUpdatesToQueue() {
    if (_pendingUpdates.isNotEmpty) {
      _queue.addAll(_pendingUpdates.values);
      _pendingUpdates.clear();
    }
  }

  void _scheduleProcessing() {
    if (!_isProcessing) Future.microtask(_processQueue);
  }

  bool _dependsOn(EditorPersistenceMutation later, EditorPersistenceMutation earlier) {
    return later.affectedBlockIds.intersection(earlier.affectedBlockIds).isNotEmpty;
  }

  bool _isBlocked(EditorPersistenceMutation mutation) {
    for (final failed in _failed) {
      if (_dependsOn(mutation, failed)) return true;
    }
    for (final blocked in _blocked) {
      if (_dependsOn(mutation, blocked)) return true;
    }
    return false;
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      while (_queue.isNotEmpty || _pendingUpdates.isNotEmpty) {
        _flushPendingUpdatesToQueue();
        if (_queue.isEmpty) break;
        
        final mutation = _queue.removeAt(0);

        if (_isBlocked(mutation)) {
          debugPrint('KETION: Mutation blocked due to dependencies: ${mutation.runtimeType}');
          _blocked.add(mutation);
          continue;
        }

        try {
          await gateway.executeMutation(mutation);
          _successController.add(mutation);
        } catch (error) {
          debugPrint('KETION: Mutation failed: $error');
          _failed.add(mutation);
        }
      }
    } finally {
      _isProcessing = false;
      if (_queue.isNotEmpty || _pendingUpdates.isNotEmpty) _scheduleProcessing();
    }
  }

  Future<bool> flush() async {
    if (_state == CoordinatorState.closed) return false;
    final previousState = _state;
    _state = CoordinatorState.flushing;
    _flushPendingUpdatesToQueue();
    _scheduleProcessing();
    while (_queue.isNotEmpty || _pendingUpdates.isNotEmpty || _isProcessing) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    if (previousState == CoordinatorState.active) _state = CoordinatorState.active;
    return _failed.isEmpty && _blocked.isEmpty;
  }

  Future<bool> retryFailed() async {
    if (_failed.isEmpty && _blocked.isEmpty) return true;
    
    // Put failed and blocked mutations back into the queue in order
    final toRetry = <EditorPersistenceMutation>[..._failed, ..._blocked];
    _failed.clear();
    _blocked.clear();
    
    _queue.insertAll(0, toRetry);
    _scheduleProcessing();
    return flush();
  }

  void close() {
    _state = CoordinatorState.closed;
    _successController.close();
  }
}
