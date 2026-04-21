import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/features/owner/domain/entities/owner_models.dart';

enum PaymentDateFilter { thisMonth, last3Months, custom }

enum PaymentStatusFilter { all, paid, pending, overdue, cancelled }

class PaymentTrackingState extends Equatable {
  const PaymentTrackingState({
    this.items = const [],
    this.dateFilter = PaymentDateFilter.thisMonth,
    this.statusFilter = PaymentStatusFilter.all,
    this.loading = false,
  });

  final List<PaymentRow> items;
  final PaymentDateFilter dateFilter;
  final PaymentStatusFilter statusFilter;
  final bool loading;

  double get totalCollected => items
      .where((p) => p.status == PaymentStatus.paid)
      .fold<double>(0, (a, b) => a + b.amount);

  double get totalPending => items
      .where((p) => p.status == PaymentStatus.pending)
      .fold<double>(0, (a, b) => a + b.amount);

  double get totalOverdue => items
      .where((p) => p.status == PaymentStatus.overdue)
      .fold<double>(0, (a, b) => a + b.amount);

  PaymentTrackingState copyWith({
    List<PaymentRow>? items,
    PaymentDateFilter? dateFilter,
    PaymentStatusFilter? statusFilter,
    bool? loading,
  }) {
    return PaymentTrackingState(
      items: items ?? this.items,
      dateFilter: dateFilter ?? this.dateFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [items, dateFilter, statusFilter, loading];
}

class PaymentTrackingCubit extends Cubit<PaymentTrackingState> {
  PaymentTrackingCubit({
    required SessionRepository session,
    required RentflowSupabaseService db,
  })  : _session = session,
        _db = db,
        super(const PaymentTrackingState(loading: true)) {
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
      final items = await _db.fetchOwnerPayments(uid);
      if (!isClosed) emit(state.copyWith(items: items, loading: false));
    } on Exception {
      if (!isClosed) emit(state.copyWith(items: [], loading: false));
    }
  }

  void setDateFilter(PaymentDateFilter f) => emit(state.copyWith(dateFilter: f));

  void setStatusFilter(PaymentStatusFilter f) => emit(state.copyWith(statusFilter: f));

  List<PaymentRow> filtered() {
    var list = state.items;
    switch (state.statusFilter) {
      case PaymentStatusFilter.paid:
        list = list.where((p) => p.status == PaymentStatus.paid).toList();
      case PaymentStatusFilter.pending:
        list = list.where((p) => p.status == PaymentStatus.pending).toList();
      case PaymentStatusFilter.overdue:
        list = list.where((p) => p.status == PaymentStatus.overdue).toList();
      case PaymentStatusFilter.cancelled:
        list = list.where((p) => p.status == PaymentStatus.cancelled).toList();
      case PaymentStatusFilter.all:
        list = List.of(list);
    }
    return list;
  }

  Future<void> markPaid(String id) async {
    await _db.markOwnerPaymentPaid(id);
    await load();
  }
}
