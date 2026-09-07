import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentity {
  static const _storage = FlutterSecureStorage();
  static const _keyDeviceId = 'ketion_device_id';
  static String? _cachedDeviceId;

  /// Retrieves the unique device identity.
  /// If one does not exist, generates and securely stores a new one.
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
    } catch (_) {
      // Ignore read errors and generate a new one
    }

    final newId = const Uuid().v4();
    try {
      await _storage.write(key: _keyDeviceId, value: newId);
    } catch (_) {
      // If we can't persist it securely, just use it for this session.
    }
    _cachedDeviceId = newId;
    return newId;
  }
}
