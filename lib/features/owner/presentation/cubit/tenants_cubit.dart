import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_system/core/errors/app_exception.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/features/owner/domain/entities/owner_models.dart';

enum TenantListFilter { all, paid, due, overdue }

class TenantsState extends Equatable {
  const TenantsState({
    this.items = const [],
    this.query = '',
    this.filter = TenantListFilter.all,
    this.loading = false,
    this.actionError,
  });

  final List<TenantItem> items;
  final String query;
  final TenantListFilter filter;
  final bool loading;
  /// Non-null when an add/link action fails — cleared after display.
  final String? actionError;

  TenantsState copyWith({
    List<TenantItem>? items,
    String? query,
    TenantListFilter? filter,
    bool? loading,
    String? actionError,
    bool clearError = false,
  }) {
    return TenantsState(
      items: items ?? this.items,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
      actionError: clearError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [items, query, filter, loading, actionError];
}

class TenantsCubit extends Cubit<TenantsState> {
  TenantsCubit({
    required SessionRepository session,
    required RentflowSupabaseService db,
  })  : _session = session,
        _db = db,
        super(const TenantsState(loading: true)) {
    load();
  }

  final SessionRepository _session;
  final RentflowSupabaseService _db;

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true));
    final uid = _session.readUser()?.userId ?? '';
    if (uid.isEmpty) {
      if (!isClosed) emit(state.copyWith(items: [], loading: false));
      return;
    }
    try {
      final items = await _db.fetchOwnerTenants(uid);
      if (!isClosed) emit(state.copyWith(items: items, loading: false));
    } on Exception {
      if (!isClosed) emit(state.copyWith(items: [], loading: false));
    }
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  void setQuery(String q) => emit(state.copyWith(query: q));

  void setFilter(TenantListFilter f) => emit(state.copyWith(filter: f));

  List<TenantItem> visible() {
    var list = state.items.where((t) {
      final q = state.query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return t.name.toLowerCase().contains(q) ||
          t.unit.toLowerCase().contains(q) ||
          t.email.toLowerCase().contains(q);
    });
    switch (state.filter) {
      case TenantListFilter.paid:
        list = list.where((t) => t.status == TenantPayStatus.paid);
      case TenantListFilter.due:
        list = list.where((t) => t.status == TenantPayStatus.due);
      case TenantListFilter.overdue:
        list = list.where((t) => t.status == TenantPayStatus.overdue);
      case TenantListFilter.all:
        break;
    }
    return list.toList();
  }

  // ── Add tenant ─────────────────────────────────────────────────────────────

  Future<bool> addTenant({
    required String propertyId,
    required String name,
    required String unit,
    required double monthlyRent,
    String phone = '',
    String email = '',
    DateTime? moveInDate,
  }) async {
    final uid = _session.readUser()?.userId ?? '';
    if (uid.isEmpty) return false;
    try {
      await _db.insertTenant(
        ownerId: uid,
        propertyId: propertyId,
        name: name,
        unit: unit,
        monthlyRent: monthlyRent,
        phone: phone,
        email: email,
        moveInDate: moveInDate,
      );
      await load();
      return true;
    } on AppException catch (e) {
      emit(state.copyWith(actionError: e.message));
      return false;
    } on Exception {
      emit(state.copyWith(actionError: 'Could not add tenant. Try again.'));
      return false;
    }
  }

  // ── Edit tenant ────────────────────────────────────────────────────────────

  Future<bool> updateTenant({
    required String tenantId,
    required String name,
    required String unit,
    required double monthlyRent,
    String phone = '',
    String email = '',
  }) async {
    try {
      await _db.updateTenant(
        tenantId: tenantId,
        name: name,
        unit: unit,
        monthlyRent: monthlyRent,
        phone: phone,
        email: email,
      );
      await load();
      return true;
    } on AppException catch (e) {
      emit(state.copyWith(actionError: e.message));
      return false;
    } on Exception {
      emit(state.copyWith(actionError: 'Could not update tenant. Try again.'));
      return false;
    }
  }

  // ── Link / unlink renter ───────────────────────────────────────────────────

  Future<bool> linkRenter({
    required String tenantId,
    required String renterEmail,
  }) async {
    try {
      await _db.linkRenterByEmail(
        tenantId: tenantId,
        renterEmail: renterEmail,
      );
      await load();
      return true;
    } on AppException catch (e) {
      emit(state.copyWith(actionError: e.message));
      return false;
    } on Exception {
      emit(state.copyWith(actionError: 'Could not link renter. Try again.'));
      return false;
    }
  }

  Future<bool> unlinkRenter(String tenantId) async {
    try {
      await _db.unlinkRenter(tenantId);
      await load();
      return true;
    } on AppException catch (e) {
      emit(state.copyWith(actionError: e.message));
      return false;
    } on Exception {
      emit(state.copyWith(actionError: 'Could not unlink renter. Try again.'));
      return false;
    }
  }

  void clearError() => emit(state.copyWith(clearError: true));
}
