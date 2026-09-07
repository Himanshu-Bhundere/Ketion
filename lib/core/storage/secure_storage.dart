abstract class SecureStorage {
  /// Save a secure value (e.g. token)
  Future<void> write({required String key, required String value});

  /// Read a secure value
  Future<String?> read({required String key});

  /// Delete a secure value
  Future<void> delete({required String key});

  /// Clear all secure values
  Future<void> clearAll();
}
