import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ketion/features/sync/data/utils/conflict_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({'ketion_device_id': 'device-1'});

  group('ConflictResolver - Tuple Logic (version, updated_at, device_id)', () {
    test('Remote wins if remote version is higher, even with lower updatedAt',
        () async {
      // remote: version 2, updatedAt: 1000
      // local: version 1, updatedAt: 2000
      final remoteData = {
        'version': 2,
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
        'deviceId': 'remote-1'
      };
      final localData = {
        'version': 1,
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(2000, isUtc: true),
        'deviceId': 'local-1'
      };

      final resolution = ConflictResolver.resolveConflictSync(
        localVersion: localData['version'] as int,
        localUpdatedAtUtc: localData['updatedAt'] as DateTime,
        localDeviceId: localData['deviceId'] as String,
        remoteVersion: remoteData['version'] as int,
        remoteUpdatedAtUtc: remoteData['updatedAt'] as DateTime,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.applyRemote);
    });

    test('Local wins if local version is higher, even with lower updatedAt',
        () async {
      // remote: version 1, updatedAt: 2000
      // local: version 2, updatedAt: 1000
      final remoteData = {
        'version': 1,
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(2000, isUtc: true),
        'deviceId': 'remote-1'
      };
      final localData = {
        'version': 2,
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
        'deviceId': 'local-1'
      };

      final resolution = ConflictResolver.resolveConflictSync(
        localVersion: localData['version'] as int,
        localUpdatedAtUtc: localData['updatedAt'] as DateTime,
        localDeviceId: localData['deviceId'] as String,
        remoteVersion: remoteData['version'] as int,
        remoteUpdatedAtUtc: remoteData['updatedAt'] as DateTime,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.keepLocal);
    });

    test('If version is equal, higher updatedAt wins (Remote wins)', () async {
      final remoteData = {
        'version': 2,
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(2000, isUtc: true),
        'deviceId': 'a'
      };
      final localData = {
        'version': 2,
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
        'deviceId': 'a'
      };

      final resolution = ConflictResolver.resolveConflictSync(
        localVersion: localData['version'] as int,
        localUpdatedAtUtc: localData['updatedAt'] as DateTime,
        localDeviceId: localData['deviceId'] as String,
        remoteVersion: remoteData['version'] as int,
        remoteUpdatedAtUtc: remoteData['updatedAt'] as DateTime,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.applyRemote);
    });

    test(
        'If version and updatedAt are equal, lexicographical deviceId wins (Remote wins)',
        () async {
      // remote: deviceId "b"
      // local: deviceId "a"
      // "b" > "a", so Remote wins
      final remoteData = {
        'version': 2,
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
        'deviceId': 'b'
      };
      final localData = {
        'version': 2,
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
        'deviceId': 'a'
      };

      final resolution = ConflictResolver.resolveConflictSync(
        localVersion: localData['version'] as int,
        localUpdatedAtUtc: localData['updatedAt'] as DateTime,
        localDeviceId: localData['deviceId'] as String,
        remoteVersion: remoteData['version'] as int,
        remoteUpdatedAtUtc: remoteData['updatedAt'] as DateTime,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.applyRemote);
    });

    test(
        'If version and updatedAt are equal, lexicographical deviceId wins (Local wins)',
        () async {
      // remote: deviceId "a"
      // local: deviceId "b"
      // "b" > "a", so Local wins
      final remoteData = {
        'version': 2,
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
        'deviceId': 'a'
      };
      final localData = {
        'version': 2,
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
        'deviceId': 'b'
      };

      final resolution = ConflictResolver.resolveConflictSync(
        localVersion: localData['version'] as int,
        localUpdatedAtUtc: localData['updatedAt'] as DateTime,
        localDeviceId: localData['deviceId'] as String,
        remoteVersion: remoteData['version'] as int,
        remoteUpdatedAtUtc: remoteData['updatedAt'] as DateTime,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.keepLocal);
    });
  });
}
