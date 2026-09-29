import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/editor/services/editor_persistence_coordinator.dart';
import 'package:ketion/features/editor/services/editor_persistence_mutations.dart';

class _Gateway implements EditorPersistenceGateway {
  bool fail = false;
  Duration delay = Duration.zero;
  final mutations = <EditorPersistenceMutation>[];

  @override
  Future<void> executeMutation(EditorPersistenceMutation mutation) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    mutations.add(mutation);
    if (fail) throw StateError('SQLite transaction failed');
  }
}

UpdateBlockMutation _update(String data) => UpdateBlockMutation(
      pageId: 'page',
      blockId: 'block',
      data: data,
      type: 'text',
      expectedVersion: 1,
      blockCreatedAt: DateTime.now().toUtc(),
      createdAt: DateTime.now().toUtc(),
      position: 1.0,
    );

void main() {
  test('enqueue accepts ownership synchronously and gateway commits asynchronously', () async {
    final gateway = _Gateway();
    final coordinator = EditorPersistenceCoordinator(gateway: gateway);

    final persisted = coordinator.enqueue(_update('Hello'));

    expect(persisted, isTrue);
    expect(await coordinator.flush(), isTrue);
    expect(gateway.mutations, hasLength(1));
  });

  test('failed mutations remain pending and make flush unsuccessful', () async {
    final gateway = _Gateway()..fail = true;
    final coordinator = EditorPersistenceCoordinator(gateway: gateway);

    expect(coordinator.enqueue(_update('Hello')), isTrue);
    expect(await coordinator.flush(), isFalse);
    expect(coordinator.hasFailedMutations, isTrue);
    expect(coordinator.hasPendingMutations, isTrue);

    gateway.fail = false;
    expect(await coordinator.retryFailed(), isTrue);
    expect(coordinator.hasPendingMutations, isFalse);
  });

  test('coalesced updates persist the latest immutable payload', () async {
    final gateway = _Gateway();
    final coordinator = EditorPersistenceCoordinator(gateway: gateway);

    final first = coordinator.enqueue(_update('Hel'));
    final second = coordinator.enqueue(_update('Hello'));

    expect(first, isTrue);
    expect(second, isTrue);
    await coordinator.flush();
    expect(gateway.mutations, hasLength(1));
    expect((gateway.mutations.single as UpdateBlockMutation).data, 'Hello');
  });

  test('Failure / Recovery: dependent mutation remains blocked until retry', () async {
    final gateway = _Gateway()..fail = true;
    final coordinator = EditorPersistenceCoordinator(gateway: gateway);

    // Enqueue A and let it fail
    coordinator.enqueue(_update('A_failed'));
    await coordinator.flush();
    expect(coordinator.hasFailedMutations, isTrue);
    expect(gateway.mutations, hasLength(1));

    // Enqueue dependent mutation B
    // It will be rebased against _pendingVersionState which was already incremented optimistically for A
    coordinator.enqueue(_update('A_dependent'));
    
    // Flush to ensure B is processed by the loop and put into _blocked
    await coordinator.flush();

    // B should be blocked, A is failed
    expect(coordinator.hasPendingMutations, isTrue);
    expect(gateway.mutations, hasLength(1)); // B was blocked, not sent to gateway
    
    // Now retry and succeed
    gateway.fail = false;
    expect(await coordinator.retryFailed(), isTrue);

    // Both should have executed now
    expect(gateway.mutations, hasLength(3)); // 1st failed A + retried A + B
    
    // Check version sequencing
    expect((gateway.mutations[1] as UpdateBlockMutation).data, 'A_failed');
    expect((gateway.mutations[1] as UpdateBlockMutation).expectedVersion, 1);
    expect((gateway.mutations[2] as UpdateBlockMutation).data, 'A_dependent');
    expect((gateway.mutations[2] as UpdateBlockMutation).expectedVersion, 2); // Dependent advanced to 2
  });

  test('Delayed SQLite: Convert block then type content (version sequence correctness)', () async {
    final gateway = _Gateway()..delay = const Duration(milliseconds: 50);
    final coordinator = EditorPersistenceCoordinator(gateway: gateway);

    final first = coordinator.enqueue(UpdateBlockMutation(
      pageId: 'page', blockId: 'block', data: 'A', type: 'bullet', 
      expectedVersion: 1, position: 1.0, 
      blockCreatedAt: DateTime.now().toUtc(), createdAt: DateTime.now().toUtc(),
    ),);

    // While the first one is running (delayed), we enqueue a second update
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final second = coordinator.enqueue(UpdateBlockMutation(
      pageId: 'page', blockId: 'block', data: 'AB', type: 'bullet', 
      expectedVersion: 2, position: 1.0, 
      blockCreatedAt: DateTime.now().toUtc(), createdAt: DateTime.now().toUtc(),
    ),);

    expect(first, isTrue);
    expect(second, isTrue);

    await coordinator.flush();
    expect(gateway.mutations, hasLength(2));
    
    expect((gateway.mutations[0] as UpdateBlockMutation).expectedVersion, 1);
    expect((gateway.mutations[1] as UpdateBlockMutation).expectedVersion, 2);
  });

  test('Coalescing after execution begins', () async {
    final gateway = _Gateway()..delay = const Duration(milliseconds: 50);
    final coordinator = EditorPersistenceCoordinator(gateway: gateway);

    // Starts executing immediately
    coordinator.enqueue(_update('A'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    
    // B and C arrive while A is in flight
    coordinator.enqueue(_update('B'));
    coordinator.enqueue(_update('C'));
    
    await coordinator.flush();
    
    // A writes (v1->v2), B and C coalesce and write (v2->v3)
    expect(gateway.mutations, hasLength(2));
    expect((gateway.mutations[0] as UpdateBlockMutation).data, 'A');
    expect((gateway.mutations[0] as UpdateBlockMutation).expectedVersion, 1);
    expect((gateway.mutations[1] as UpdateBlockMutation).data, 'C');
    expect((gateway.mutations[1] as UpdateBlockMutation).expectedVersion, 2);
  });

  test('Split then immediate edit', () async {
    final gateway = _Gateway();
    final coordinator = EditorPersistenceCoordinator(gateway: gateway);

    final split = SplitBlockMutation(
      pageId: 'page', originalBlockId: 'block', newBlockId: 'block2',
      originalData: 'Hel', newData: 'lo', expectedVersion: 1, newType: 'text',
      originalPosition: 1.0, newPosition: 2.0,
      originalBlockCreatedAt: DateTime.now().toUtc(), createdAt: DateTime.now().toUtc(),
    );
    coordinator.enqueue(split);

    // Edit the new block immediately
    final update = UpdateBlockMutation(
      pageId: 'page', blockId: 'block2', data: 'lo!', type: 'text',
      expectedVersion: 1, position: 2.0,
      blockCreatedAt: DateTime.now().toUtc(), createdAt: DateTime.now().toUtc(),
    );
    coordinator.enqueue(update);

    await coordinator.flush();
    
    expect(gateway.mutations, hasLength(2));
    
    // The new block 'block2' was created in Split, its expected version should be correctly initialized
    expect(gateway.mutations[0], isA<SplitBlockMutation>());
    expect((gateway.mutations[1] as UpdateBlockMutation).expectedVersion, 1); 
  });

  test('Merge pending mutation', () async {
    final gateway = _Gateway();
    final coordinator = EditorPersistenceCoordinator(gateway: gateway);

    // Edit block2
    final update = UpdateBlockMutation(
      pageId: 'page', blockId: 'block2', data: 'lo!', type: 'text',
      expectedVersion: 2, position: 2.0,
      blockCreatedAt: DateTime.now().toUtc(), createdAt: DateTime.now().toUtc(),
    );
    coordinator.enqueue(update);
    
    // Merge block2 into block1 while update is enqueued
    final merge = MergeBlocksMutation(
      pageId: 'page', survivorBlockId: 'block1', victimBlockId: 'block2',
      survivorData: 'Hello!', survivorExpectedVersion: 1, victimExpectedVersion: 2,
      survivorBlockCreatedAt: DateTime.now().toUtc(), createdAt: DateTime.now().toUtc(),
    );
    coordinator.enqueue(merge);

    await coordinator.flush();

    expect(gateway.mutations, hasLength(2));
    expect((gateway.mutations[0] as UpdateBlockMutation).blockId, 'block2');
    expect((gateway.mutations[1] as MergeBlocksMutation).victimExpectedVersion, 3); // Victim version was expected to be 2, then updated to 3 because of the pending update!
  });
}
