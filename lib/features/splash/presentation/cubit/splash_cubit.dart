import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/features/auth/domain/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(
    this._session,
    this._db, {
    SupabaseClient? supabaseClient,
  }) : _client = supabaseClient ?? Supabase.instance.client,
       super(const SplashState());

  final SessionRepository _session;
  final RentflowSupabaseService _db;
  final SupabaseClient _client;

  Future<void> start() async {
    emit(state.copyWith(loading: true));
    final sw = Stopwatch()..start();
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (sw.elapsedMilliseconds < 2200) {
      await Future<void>.delayed(
        Duration(milliseconds: 2200 - sw.elapsedMilliseconds),
      );
    }

    final remote = _client.auth.currentSession;
    if (remote != null) {
      try {
        final profile = await _db.fetchProfile(remote.user.id);
        if (profile != null) {
          final email = remote.user.email ?? '';
          await _session.writeUser(
            SessionUser(
              userId: profile.id,
              displayName: profile.displayName.isNotEmpty
                  ? profile.displayName
                  : 'User',
              role: profile.role,
              phoneOrEmail: email.isNotEmpty
                  ? email
                  : (profile.email ?? profile.phone ?? ''),
            ),
          );
          emit(
            state.copyWith(
              loading: false,
              target: profile.role == UserRole.owner
                  ? SplashTarget.ownerHome
                  : SplashTarget.renterHome,
            ),
          );
          return;
        }
        await _client.auth.signOut();
        await _session.clearUser();
        emit(state.copyWith(loading: false, target: SplashTarget.landing));
        return;
      } on Exception {
        await _client.auth.signOut();
        await _session.clearUser();
      }
    }

    final user = _session.readUser();
    if (user == null || user.userId.isEmpty) {
      emit(state.copyWith(loading: false, target: SplashTarget.landing));
    } else {
      emit(
        state.copyWith(
          loading: false,
          target: user.role == UserRole.owner
              ? SplashTarget.ownerHome
              : SplashTarget.renterHome,
        ),
      );
    }
  }
}
