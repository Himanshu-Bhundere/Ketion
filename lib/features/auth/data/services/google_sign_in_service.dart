import 'package:google_sign_in/google_sign_in.dart';
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/auth/domain/services/auth_service.dart';
import 'package:ketion/features/auth/domain/repositories/auth_repository.dart';

class GoogleSignInService implements AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AuthRepository _authRepository;

  GoogleSignInService(this._authRepository);

  @override
  Future<Result<String>> signIn(List<String> scopes) async {
    try {
      // Re-initialize with requested scopes if needed
      final googleSignIn = GoogleSignIn(scopes: scopes);
      final account = await googleSignIn.signIn();
      if (account == null) {
        return const Error(UnknownFailure('User canceled sign in'));
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) {
        return const Error(UnknownFailure('Failed to get access token'));
      }

      // Store the token securely
      await _authRepository.saveAccessToken(accessToken);

      return Success(accessToken);
    } catch (e) {
      return Error(UnknownFailure('Sign in failed: $e'));
    }
  }

  @override
  Future<Result<String>> getAccessToken(List<String> scopes) async {
    try {
      final storedTokenResult = await _authRepository.getAccessToken();
      final storedToken = storedTokenResult.valueOrNull;
      if (storedToken != null) {
        // We have a stored token. In a real app we might validate expiry here.
        // For now, return the stored token if google_sign_in thinks we're signed in.
        final isSignedIn = await this.isSignedIn();
        if (isSignedIn) {
           return Success(storedToken);
        }
      }

      final googleSignIn = GoogleSignIn(scopes: scopes);
      var account = googleSignIn.currentUser;

      account ??= await googleSignIn.signInSilently();

      if (account == null) {
        return const Error(UnknownFailure('User not signed in'));
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) {
        return const Error(UnknownFailure('Failed to get access token'));
      }

      // Store the token securely
      await _authRepository.saveAccessToken(accessToken);

      return Success(accessToken);
    } catch (e) {
      return Error(UnknownFailure('Failed to get access token: $e'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _authRepository.clearTokens();
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure('Sign out failed: $e'));
    }
  }

  @override
  Future<bool> isSignedIn() async {
    final storedTokenResult = await _authRepository.getAccessToken();
    final hasStoredToken = storedTokenResult is Success<String?> && 
                           (storedTokenResult).value != null;
                           
    return hasStoredToken || _googleSignIn.currentUser != null ||
        await _googleSignIn.signInSilently() != null;
  }
}
