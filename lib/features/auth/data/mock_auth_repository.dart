import 'package:rent_system/core/errors/app_exception.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/features/auth/domain/auth_repository.dart';
import 'package:rent_system/features/auth/domain/user_role.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._session);

  final SessionRepository _session;

  @override
  Future<void> signIn({
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final id = identifier.trim().toLowerCase();
    if (password.length < 4) {
      throw const AppException('Incorrect password');
    }
    if (id == 'locked@example.com') {
      throw const AppException(
        'Account locked due to multiple failed attempts. Try after 15 minutes.',
        code: 'locked',
      );
    }
    if (id == 'missing@example.com') {
      throw const AppException('No account found. Please sign up.');
    }
    final name = id.contains('@') ? id.split('@').first : 'Owner';
    await _session.writeUser(
      SessionUser(
        userId: 'mock-${role.name}-${name.hashCode}',
        displayName: name.isEmpty ? 'User' : name,
        role: role,
        phoneOrEmail: identifier.trim(),
      ),
    );
  }

  @override
  Future<void> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
    required bool agreedToTerms,
    required UserRole role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!agreedToTerms) {
      throw const AppException('Please accept Terms & Conditions');
    }
    if (password != confirmPassword) {
      throw const AppException('Passwords do not match');
    }
    await _session.writeUser(
      SessionUser(
        userId: 'mock-${role.name}-${email.trim().hashCode}',
        displayName: fullName.trim(),
        role: role,
        phoneOrEmail: email.trim().isNotEmpty ? email.trim() : phone.trim(),
      ),
    );
  }

  @override
  Future<void> signOut() => _session.clearUser();
}
