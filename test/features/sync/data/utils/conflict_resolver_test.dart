import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/sync/data/utils/conflict_resolver.dart';
void main() {
  group('ConflictResolver - Tuple Logic (version, updated_at, device_id)', () {
    test('Local wins if remote version is lower', () async {
      // remote: version 1
      // local: version 2
      final remoteData = {'version': 1, 'updatedAt': 1000, 'deviceId': 'remote-1'};
      final localData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'local-1'};

      final resolution = ConflictResolver.resolveConflictSync(
        localVersion: localData['version'] as int,
        localUpdatedAt: localData['updatedAt'] as int,
        localDeviceId: localData['deviceId'] as String,
        remoteVersion: remoteData['version'] as int,
        remoteUpdatedAt: remoteData['updatedAt'] as int,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.keepLocal);
    });

    test('Remote wins if remote version is higher', () async {
      // remote: version 3
      // local: version 2
      final remoteData = {'version': 3, 'updatedAt': 1000, 'deviceId': 'remote-1'};
      final localData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'local-1'};

      final resolution = ConflictResolver.resolveConflictSync(
        localVersion: localData['version'] as int,
        localUpdatedAt: localData['updatedAt'] as int,
        localDeviceId: localData['deviceId'] as String,
        remoteVersion: remoteData['version'] as int,
        remoteUpdatedAt: remoteData['updatedAt'] as int,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.applyRemote);
    });

    test('If versions are equal, higher updatedAt wins (Remote wins)', () async {
      // remote: version 2, updatedAt: 2000
      // local: version 2, updatedAt: 1000
      final remoteData = {'version': 2, 'updatedAt': 2000, 'deviceId': 'remote-1'};
      final localData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'local-1'};

      final resolution = ConflictResolver.resolveConflictSync(
        localVersion: localData['version'] as int,
        localUpdatedAt: localData['updatedAt'] as int,
        localDeviceId: localData['deviceId'] as String,
        remoteVersion: remoteData['version'] as int,
        remoteUpdatedAt: remoteData['updatedAt'] as int,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.applyRemote);
    });

    test('If versions are equal, higher updatedAt wins (Local wins)', () async {
      // remote: version 2, updatedAt: 1000
      // local: version 2, updatedAt: 2000
      final remoteData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'remote-1'};
      final localData = {'version': 2, 'updatedAt': 2000, 'deviceId': 'local-1'};

      final resolution = ConflictResolver.resolveConflictSync(
        localVersion: localData['version'] as int,
        localUpdatedAt: localData['updatedAt'] as int,
        localDeviceId: localData['deviceId'] as String,
        remoteVersion: remoteData['version'] as int,
        remoteUpdatedAt: remoteData['updatedAt'] as int,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.keepLocal);
    });

    test('If versions and updatedAt are equal, lexicographical deviceId wins (Remote wins)', () async {
      // remote: deviceId "b"
      // local: deviceId "a"
      // "b" > "a", so Remote wins
      final remoteData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'b'};
      final localData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'a'};

      final resolution = ConflictResolver.resolveConflictSync(
        localVersion: localData['version'] as int,
        localUpdatedAt: localData['updatedAt'] as int,
        localDeviceId: localData['deviceId'] as String,
        remoteVersion: remoteData['version'] as int,
        remoteUpdatedAt: remoteData['updatedAt'] as int,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.applyRemote);
    });

    test('If versions and updatedAt are equal, lexicographical deviceId wins (Local wins)', () async {
      // remote: deviceId "a"
      // local: deviceId "b"
      // "b" > "a", so Local wins
      final remoteData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'a'};
      final localData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'b'};

      final resolution = ConflictResolver.resolveConflictSync(
        localVersion: localData['version'] as int,
        localUpdatedAt: localData['updatedAt'] as int,
        localDeviceId: localData['deviceId'] as String,
        remoteVersion: remoteData['version'] as int,
        remoteUpdatedAt: remoteData['updatedAt'] as int,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.keepLocal);
    });
  });
}
