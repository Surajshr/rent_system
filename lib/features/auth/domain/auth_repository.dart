import 'package:rent_system/features/auth/domain/user_role.dart';

abstract class AuthRepository {
  Future<void> signIn({
    required String identifier,
    required String password,
    required UserRole role,
  });

  Future<void> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
    required bool agreedToTerms,
    required UserRole role,
  });

  Future<void> signOut();
}
