import 'package:ketion/core/utils/result.dart';

abstract class AuthService {
  /// Sign in and return an access token for the requested scopes
  Future<Result<String>> signIn(List<String> scopes);

  /// Get the current access token if already signed in, or attempt silent sign in
  Future<Result<String>> getAccessToken(List<String> scopes);

  /// Sign out the current user
  Future<Result<void>> signOut();

  /// Check if a user is currently signed in
  Future<bool> isSignedIn();
}
