import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ketion/features/sync/data/utils/conflict_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({'ketion_device_id': 'device-1'});

  group('ConflictResolver - Tuple Logic (updated_at, device_id)', () {
    test('Remote wins if remote updatedAt is higher, even with lower version', () async {
      // remote: version 1, updatedAt: 2000
      // local: version 100, updatedAt: 1000
      final remoteData = {'version': 1, 'updatedAt': 2000, 'deviceId': 'remote-1'};
      final localData = {'version': 100, 'updatedAt': 1000, 'deviceId': 'local-1'};

      final resolution = ConflictResolver.resolveConflictSync(
        localUpdatedAt: localData['updatedAt'] as int,
        localDeviceId: localData['deviceId'] as String,
        remoteUpdatedAt: remoteData['updatedAt'] as int,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.applyRemote);
    });

    test('Local wins if local updatedAt is higher, even with lower version', () async {
      // remote: version 100, updatedAt: 1000
      // local: version 1, updatedAt: 2000
      final remoteData = {'version': 100, 'updatedAt': 1000, 'deviceId': 'remote-1'};
      final localData = {'version': 1, 'updatedAt': 2000, 'deviceId': 'local-1'};

      final resolution = ConflictResolver.resolveConflictSync(
        localUpdatedAt: localData['updatedAt'] as int,
        localDeviceId: localData['deviceId'] as String,
        remoteUpdatedAt: remoteData['updatedAt'] as int,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.keepLocal);
    });

    test('If updatedAt are equal, lexicographical deviceId wins (Remote wins)', () async {
      // remote: deviceId "b"
      // local: deviceId "a"
      // "b" > "a", so Remote wins
      final remoteData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'b'};
      final localData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'a'};

      final resolution = ConflictResolver.resolveConflictSync(
        localUpdatedAt: localData['updatedAt'] as int,
        localDeviceId: localData['deviceId'] as String,
        remoteUpdatedAt: remoteData['updatedAt'] as int,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.applyRemote);
    });

    test('If updatedAt are equal, lexicographical deviceId wins (Local wins)', () async {
      // remote: deviceId "a"
      // local: deviceId "b"
      // "b" > "a", so Local wins
      final remoteData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'a'};
      final localData = {'version': 2, 'updatedAt': 1000, 'deviceId': 'b'};

      final resolution = ConflictResolver.resolveConflictSync(
        localUpdatedAt: localData['updatedAt'] as int,
        localDeviceId: localData['deviceId'] as String,
        remoteUpdatedAt: remoteData['updatedAt'] as int,
        remoteDeviceId: remoteData['deviceId'] as String,
      );

      expect(resolution, ConflictResolution.keepLocal);
    });
  });
}
