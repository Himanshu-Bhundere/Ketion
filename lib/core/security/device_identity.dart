import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentity {
  static const _storage = FlutterSecureStorage();
  static const _keyDeviceId = 'ketion_device_id';
  static String? _cachedDeviceId;

  /// Retrieves the unique device identity.
  /// If one does not exist, generates and securely stores a new one.
  /// Throws [DeviceIdentityException] if secure storage operations fail.
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      final storedId = await _storage.read(key: _keyDeviceId);
      if (storedId != null && storedId.isNotEmpty) {
        _cachedDeviceId = storedId;
        return storedId;
      }

      final newId = const Uuid().v4();
      await _storage.write(key: _keyDeviceId, value: newId);

      _cachedDeviceId = newId;
      return newId;
    } catch (e) {
      throw DeviceIdentityException('Failed to access secure storage: $e');
    }
  }
}

class DeviceIdentityException implements Exception {
  final String message;
  DeviceIdentityException(this.message);

  @override
  String toString() => 'DeviceIdentityException: $message';
}
