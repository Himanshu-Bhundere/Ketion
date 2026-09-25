import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/core/security/secure_token_storage.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SecureTokenStorage _tokenStorage;

  AuthRepositoryImpl(this._tokenStorage);

  @override
  Future<Result<void>> saveAccessToken(String token) async {
    try {
      await _tokenStorage.saveTokens(accessToken: token);
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure('Failed to save access token: $e'));
    }
  }

  @override
  Future<Result<String?>> getAccessToken() async {
    try {
      final tokenResult = await _tokenStorage.getAccessToken();
      return Success(tokenResult.valueOrNull);
    } catch (e) {
      return Error(UnknownFailure('Failed to get access token: $e'));
    }
  }

  @override
  Future<Result<void>> clearTokens() async {
    try {
      await _tokenStorage.clearTokens();
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure('Failed to clear tokens: $e'));
    }
  }
}

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final secureTokenStorage = ref.watch(secureTokenStorageProvider);
  return AuthRepositoryImpl(secureTokenStorage);
});
