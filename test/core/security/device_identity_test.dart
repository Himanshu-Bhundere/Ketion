import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ketion/core/security/device_identity.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('generates and persists a new UUID on first call', () async {
    final id1 = await DeviceIdentity.getDeviceId();
    expect(id1, isNotEmpty);
    
    final id2 = await DeviceIdentity.getDeviceId();
    expect(id1, equals(id2));
  });
}
