import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/core/errors/failures.dart';

class SecureTokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'google_access_token';
  static const _keyRefreshToken = 'google_refresh_token';
  static const _keyExpiry = 'google_token_expiry';

  Future<Result<void>> saveTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? expiry,
  }) async {
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);

      if (refreshToken != null) {
        await _storage.write(key: _keyRefreshToken, value: refreshToken);
      }

      if (expiry != null) {
        await _storage.write(key: _keyExpiry, value: expiry.toIso8601String());
      }

      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure('Failed to securely store tokens: $e'));
    }
  }

  Future<Result<String?>> getAccessToken() async {
    try {
      final token = await _storage.read(key: _keyAccessToken);
      return Success(token);
    } catch (e) {
      return Error(UnknownFailure('Failed to read access token: $e'));
    }
  }

  Future<Result<String?>> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _keyRefreshToken);
      return Success(token);
    } catch (e) {
      return Error(UnknownFailure('Failed to read refresh token: $e'));
    }
  }

  Future<Result<DateTime?>> getTokenExpiry() async {
    try {
      final expiryString = await _storage.read(key: _keyExpiry);
      if (expiryString == null) return const Success(null);
      return Success(DateTime.tryParse(expiryString));
    } catch (e) {
      return Error(UnknownFailure('Failed to read token expiry: $e'));
    }
  }

  Future<Result<void>> clearTokens() async {
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyExpiry);
      return const Success(null);
    } catch (e) {
      return Error(
          UnknownFailure('Failed to clear securely stored tokens: $e'));
    }
  }
}
