import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/auth/domain/services/auth_service.dart';
import 'package:ketion/features/auth/data/services/google_sign_in_service.dart';
import 'package:ketion/features/auth/data/repositories/auth_repository_impl.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return GoogleSignInService(authRepository);
});
