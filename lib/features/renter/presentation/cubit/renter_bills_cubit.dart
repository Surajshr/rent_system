import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/features/renter/domain/entities/renter_models.dart';

enum RenterBillFilter { all, paid, pending, overdue }

class RenterBillsState extends Equatable {
  const RenterBillsState({
    this.items = const [],
    this.filter = RenterBillFilter.all,
    this.loading = false,
  });

  final List<RenterBill> items;
  final RenterBillFilter filter;
  final bool loading;

  RenterBillsState copyWith({
    List<RenterBill>? items,
    RenterBillFilter? filter,
    bool? loading,
  }) {
    return RenterBillsState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [items, filter, loading];
}

class RenterBillsCubit extends Cubit<RenterBillsState> {
  RenterBillsCubit({
    required SessionRepository session,
    required RentflowSupabaseService db,
  })  : _session = session,
        _db = db,
        super(const RenterBillsState(loading: true)) {
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
      final items = await _db.fetchRenterBills(uid);
      if (!isClosed) emit(state.copyWith(items: items, loading: false));
    } on Exception {
      if (!isClosed) emit(state.copyWith(items: [], loading: false));
    }
  }

  void setFilter(RenterBillFilter f) => emit(state.copyWith(filter: f));

  List<RenterBill> visible() {
    switch (state.filter) {
      case RenterBillFilter.paid:
        return state.items.where((b) => b.status == RenterBillStatus.paid).toList();
      case RenterBillFilter.pending:
        return state.items.where((b) => b.status == RenterBillStatus.pending).toList();
      case RenterBillFilter.overdue:
        return state.items.where((b) => b.status == RenterBillStatus.overdue).toList();
      case RenterBillFilter.all:
        return List.of(state.items);
    }
  }
}
