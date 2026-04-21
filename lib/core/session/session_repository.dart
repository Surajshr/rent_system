import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:rent_system/features/auth/domain/user_role.dart';

class SessionRepository {
  SessionRepository(this._box);

  final Box<String> _box;

  static const _keyUserJson = 'user_json';
  static const _keyFirstLaunch = 'first_launch_done';

  bool get isFirstLaunchComplete => _box.get(_keyFirstLaunch) == 'true';

  Future<void> setFirstLaunchComplete() async {
    await _box.put(_keyFirstLaunch, 'true');
  }

  SessionUser? readUser() {
    final raw = _box.get(_keyUserJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SessionUser.fromJson(map);
    } on Exception {
      return null;
    }
  }

  Future<void> writeUser(SessionUser user) async {
    await _box.put(_keyUserJson, jsonEncode(user.toJson()));
  }

  Future<void> clearUser() async {
    await _box.delete(_keyUserJson);
  }
}

class SessionUser {
  const SessionUser({
    required this.userId,
    required this.displayName,
    required this.role,
    this.phoneOrEmail = '',
  });

  /// Supabase `auth.users` / `profiles.id` when using cloud auth.
  final String userId;
  final String displayName;
  final UserRole role;
  final String phoneOrEmail;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'role': role.name,
        'phoneOrEmail': phoneOrEmail,
      };

  static SessionUser fromJson(Map<String, dynamic> json) {
    return SessionUser(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'User',
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.owner,
      ),
      phoneOrEmail: json['phoneOrEmail'] as String? ?? '',
    );
  }
}
