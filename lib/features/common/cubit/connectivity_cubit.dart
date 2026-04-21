import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rent_system/core/network/network_info.dart';

enum ConnectivityStatus { checking, online, offline }

class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  ConnectivityCubit() : super(ConnectivityStatus.checking) {
    _check(); // immediate first check
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  Timer? _timer;

  Future<void> _check() async {
    if (isClosed) return;
    final connected = await NetworkInfo.isConnected();
    if (isClosed) return;
    final next = connected ? ConnectivityStatus.online : ConnectivityStatus.offline;
    if (state != next) emit(next);
  }

  /// Force an immediate re-check (e.g. after the user taps "Retry").
  Future<void> retry() => _check();

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
