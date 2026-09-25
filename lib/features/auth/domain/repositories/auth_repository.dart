import 'package:ketion/core/utils/result.dart';

abstract class AuthRepository {
  Future<Result<void>> saveAccessToken(String token);
  Future<Result<String?>> getAccessToken();
  Future<Result<void>> clearTokens();
}
