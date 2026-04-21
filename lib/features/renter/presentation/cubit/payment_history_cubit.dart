import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/features/renter/domain/entities/renter_models.dart';

class PaymentHistoryState extends Equatable {
  const PaymentHistoryState({
    this.items = const [],
    this.loading = false,
  });

  final List<RenterPaymentHistoryItem> items;
  final bool loading;

  double get totalYtd => items.fold<double>(0, (a, b) => a + b.amount);

  double get average =>
      items.isEmpty ? 0 : totalYtd / items.length;

  PaymentHistoryState copyWith({
    List<RenterPaymentHistoryItem>? items,
    bool? loading,
  }) {
    return PaymentHistoryState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [items, loading];
}

class PaymentHistoryCubit extends Cubit<PaymentHistoryState> {
  PaymentHistoryCubit({
    required SessionRepository session,
    required RentflowSupabaseService db,
  })  : _session = session,
        _db = db,
        super(const PaymentHistoryState(loading: true)) {
    load();
  }

  final SessionRepository _session;
  final RentflowSupabaseService _db;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true));
    final uid = _session.readUser()?.userId ?? '';
    if (uid.isEmpty) {
      if (!isClosed) emit(state.copyWith(items: [], loading: false));
      return;
    }
    try {
      final items = await _db.fetchRenterPaymentHistory(uid);
      if (!isClosed) emit(state.copyWith(items: items, loading: false));
    } on Exception {
      if (!isClosed) emit(state.copyWith(items: [], loading: false));
    }
  }
}
