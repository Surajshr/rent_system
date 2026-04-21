import 'dart:io';

import 'package:rent_system/core/errors/app_exception.dart';
import 'package:rent_system/core/network/network_info.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/core/utils/auth_validators.dart';
import 'package:rent_system/features/auth/domain/auth_repository.dart';
import 'package:rent_system/features/auth/domain/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts a phone number or email into the email field Supabase Auth needs.
///
/// If [identifier] looks like an email it is used directly.
/// If it looks like a phone number we derive a deterministic pseudo-email
/// `<digits>@rentflow.app` — Supabase never sends mail to it because email
/// confirmation is disabled.  Users only ever see / type their phone number.
String _toSupabaseEmail(String identifier) {
  final v = identifier.trim();
  if (AuthValidators.looksLikeEmail(v)) return v.toLowerCase();
  final digits = v.replaceAll(RegExp(r'\D'), '');
  return '$digits@rentflow.app';
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required SessionRepository session,
    required RentflowSupabaseService db,
    SupabaseClient? client,
  })  : _session = session,
        _db = db,
        _client = client ?? Supabase.instance.client;

  final SessionRepository _session;
  final RentflowSupabaseService _db;
  final SupabaseClient _client;

  Future<void> _persistSessionUser(User user, ProfileRow profile) async {
    await _session.writeUser(
      SessionUser(
        userId: user.id,
        displayName: profile.displayName.isNotEmpty
            ? profile.displayName
            : (user.userMetadata?['display_name'] as String? ?? 'User'),
        role: profile.role,
        phoneOrEmail: user.email ?? profile.email ?? profile.phone ?? '',
      ),
    );
  }

  AppException _authError(Object e) {
    if (e is AppException) return e;
    if (e is SocketException || NetworkInfo.isNetworkError(e)) {
      return const AppException(NetworkInfo.offlineMessage, code: 'offline');
    }
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
        return const AppException('Incorrect phone number / email or password.');
      }
      if (msg.contains('email not confirmed')) {
        return const AppException(
          'Please verify your email first. Check your inbox for a confirmation link.',
        );
      }
      if (msg.contains('user already registered') ||
          msg.contains('already been registered')) {
        return const AppException(
          'An account with this phone / email already exists. Please sign in.',
        );
      }
      if (msg.contains('email signups are disabled') ||
          msg.contains('signups not allowed')) {
        return const AppException(
          'Sign-up is temporarily unavailable. Please contact support.',
        );
      }
      if (msg.contains('rate limit') ||
          msg.contains('over_email_send_rate_limit') ||
          msg.contains('email rate limit') ||
          e.statusCode == '429') {
        return const AppException(
          'Too many attempts. Please wait a few minutes and try again.',
        );
      }
      if (msg.contains('password')) {
        return const AppException('Password must be at least 6 characters.');
      }
      if (msg.contains('weak password')) {
        return const AppException(
          'Password is too weak. Use at least 8 characters with letters and numbers.',
        );
      }
      if (msg.contains('invalid email') ||
          msg.contains('unable to validate email')) {
        return const AppException('Please enter a valid phone number or email.');
      }
      return AppException(e.message.isNotEmpty ? e.message : 'Authentication failed.');
    }
    return const AppException('Something went wrong. Please try again.');
  }

  @override
  Future<void> signIn({
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    final supabaseEmail = _toSupabaseEmail(identifier);
    try {
      final res = await _client.auth.signInWithPassword(
        email: supabaseEmail,
        password: password,
      );
      final user = res.user;
      if (user == null) {
        throw const AppException('Sign-in failed. Please try again.');
      }
      var profile = await _db.fetchProfile(user.id);
      if (profile == null) {
        final inferredRole = UserRole.values.firstWhere(
          (e) => e.name == (user.userMetadata?['role'] as String? ?? 'owner'),
          orElse: () => UserRole.owner,
        );
        await _db.upsertProfileFromSignup(
          userId: user.id,
          displayName:
              user.userMetadata?['display_name'] as String? ?? identifier.trim(),
          role: inferredRole,
          phone: AuthValidators.looksLikePhone(identifier) ? identifier.trim() : '',
          email: AuthValidators.looksLikeEmail(identifier) ? identifier.trim() : '',
        );
        profile = await _db.fetchProfile(user.id);
      }
      if (profile == null) {
        throw const AppException(
          'Profile not found. Please sign up first.',
        );
      }
      if (profile.role != role) {
        await _client.auth.signOut();
        await _session.clearUser();
        // role = what the user tried to sign in as (the page they are on)
        // profile.role = what the account actually is
        // Tell them clearly: what their account is, and which button to tap.
        if (role == UserRole.owner) {
          // Tried to sign in as owner, but account is a renter.
          throw const AppException(
            'This account is registered as a renter. '
            "Please go back and tap 'I'm a Renter'.",
            code: 'wrong_role_renter',
          );
        } else {
          // Tried to sign in as renter, but account is an owner.
          throw const AppException(
            'This account is registered as an owner. '
            "Please go back and tap 'I'm an Owner'.",
            code: 'wrong_role_owner',
          );
        }
      }
      await _persistSessionUser(user, profile);
    } on AppException {
      rethrow;
    } on Exception catch (e) {
      throw _authError(e);
    }
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
    if (!agreedToTerms) {
      throw const AppException('Please accept Terms & Conditions');
    }
    if (password != confirmPassword) {
      throw const AppException('Passwords do not match');
    }

    // Email is the mandatory identifier; use it directly as Supabase auth email.
    // Phone is optional and stored only in the profile row.
    final supabaseEmail = email.trim().toLowerCase();

    try {
      final res = await _client.auth.signUp(
        email: supabaseEmail,
        password: password,
        data: {
          'display_name': fullName.trim(),
          'role': role.name,
          'phone': phone.trim(),
        },
      );
      final user = res.user;
      if (user == null) {
        throw const AppException(
          'Could not create account. Please try again.',
        );
      }

      // The DB trigger (handle_new_user) fires synchronously on auth.users
      // INSERT and creates the profile row.  Fetch it; retry a couple of
      // times in case of any micro-latency on the Supabase side.
      ProfileRow? profile;
      for (var attempt = 0; attempt < 3; attempt++) {
        profile = await _db.fetchProfile(user.id);
        if (profile != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }

      // Trigger didn't run (shouldn't happen) — fall back to explicit RPC.
      if (profile == null) {
        await _db.upsertProfileFromSignup(
          userId: user.id,
          displayName: fullName.trim(),
          role: role,
          phone: phone.trim(),
          email: email.trim().isNotEmpty ? email.trim() : '',
        );
        profile = await _db.fetchProfile(user.id);
      }

      if (profile == null) {
        throw const AppException(
          'Account created but profile setup failed. Please sign in.',
        );
      }
      await _persistSessionUser(user, profile);
    } on AppException {
      rethrow;
    } on Exception catch (e) {
      throw _authError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on Exception {
      // Ignore sign-out errors (e.g. already signed out or offline).
    }
    await _session.clearUser();
  }
}
