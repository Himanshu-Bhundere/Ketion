import 'package:google_sign_in/google_sign_in.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/auth/domain/services/auth_service.dart';

class GoogleSignInService implements AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Future<Result<String>> signIn(List<String> scopes) async {
    try {
      // Re-initialize with requested scopes if needed
      final googleSignIn = GoogleSignIn(scopes: scopes);
      final account = await googleSignIn.signIn();
      if (account == null) {
        return const Error(Failure('User canceled sign in'));
      }
      
      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) {
        return const Error(Failure('Failed to get access token'));
      }

      return Success(accessToken);
    } catch (e) {
      return Error(Failure('Sign in failed: $e'));
    }
  }

  @override
  Future<Result<String>> getAccessToken(List<String> scopes) async {
    try {
      final googleSignIn = GoogleSignIn(scopes: scopes);
      var account = googleSignIn.currentUser;
      
      if (account == null) {
        account = await googleSignIn.signInSilently();
      }

      if (account == null) {
        return const Error(Failure('User not signed in'));
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) {
        return const Error(Failure('Failed to get access token'));
      }

      return Success(accessToken);
    } catch (e) {
      return Error(Failure('Failed to get access token: $e'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _googleSignIn.signOut();
      return const Success(null);
    } catch (e) {
      return Error(Failure('Sign out failed: $e'));
    }
  }

  @override
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}
