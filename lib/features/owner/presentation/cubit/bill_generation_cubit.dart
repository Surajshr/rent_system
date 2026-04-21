import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/features/owner/domain/entities/owner_models.dart';

class ChargeLine extends Equatable {
  const ChargeLine({this.description = '', this.amount = 0});

  final String description;
  final double amount;

  ChargeLine copyWith({String? description, double? amount}) {
    return ChargeLine(
      description: description ?? this.description,
      amount: amount ?? this.amount,
    );
  }

  @override
  List<Object?> get props => [description, amount];
}

class BillGenerationState extends Equatable {
  const BillGenerationState({
    this.tenants = const [],
    this.selectedTenantId,
    this.baseRent = 0,
    this.charges = const [ChargeLine()],
    this.deductions = const [ChargeLine()],
    this.dueDate,
    this.notes = '',
    this.submitting = false,
    this.sentTenantName,
    this.sentBillNumber,
    this.sentTotal,
    this.sentDueDate,
    this.sentCharges,
    this.sentDeductions,
    this.sentPropertyName,
  });

  final List<TenantItem> tenants;
  final String? selectedTenantId;
  final double baseRent;
  final List<ChargeLine> charges;
  final List<ChargeLine> deductions;
  final DateTime? dueDate;
  final String notes;
  final bool submitting;
  // Success snapshot — non-null once a bill has been generated.
  final String? sentTenantName;
  final String? sentBillNumber;
  final double? sentTotal;
  final DateTime? sentDueDate;
  final List<ChargeLine>? sentCharges;
  final List<ChargeLine>? sentDeductions;
  final String? sentPropertyName;

  bool get isSuccess => sentTenantName != null;

  double get chargesTotal =>
      charges.fold<double>(0, (a, b) => a + (b.amount > 0 ? b.amount : 0));

  double get deductionsTotal =>
      deductions.fold<double>(0, (a, b) => a + (b.amount > 0 ? b.amount : 0));

  double get total => baseRent + chargesTotal - deductionsTotal;

  TenantItem? get selectedTenant {
    if (selectedTenantId == null) return null;
    try {
      return tenants.firstWhere((t) => t.id == selectedTenantId);
    } on Exception {
      return null;
    }
  }

  BillGenerationState copyWith({
    List<TenantItem>? tenants,
    String? selectedTenantId,
    double? baseRent,
    List<ChargeLine>? charges,
    List<ChargeLine>? deductions,
    DateTime? dueDate,
    String? notes,
    bool? submitting,
    String? sentTenantName,
    String? sentBillNumber,
    double? sentTotal,
    DateTime? sentDueDate,
    List<ChargeLine>? sentCharges,
    List<ChargeLine>? sentDeductions,
    String? sentPropertyName,
  }) {
    return BillGenerationState(
      tenants: tenants ?? this.tenants,
      selectedTenantId: selectedTenantId ?? this.selectedTenantId,
      baseRent: baseRent ?? this.baseRent,
      charges: charges ?? this.charges,
      deductions: deductions ?? this.deductions,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      submitting: submitting ?? this.submitting,
      sentTenantName: sentTenantName ?? this.sentTenantName,
      sentBillNumber: sentBillNumber ?? this.sentBillNumber,
      sentTotal: sentTotal ?? this.sentTotal,
      sentDueDate: sentDueDate ?? this.sentDueDate,
      sentCharges: sentCharges ?? this.sentCharges,
      sentDeductions: sentDeductions ?? this.sentDeductions,
      sentPropertyName: sentPropertyName ?? this.sentPropertyName,
    );
  }

  @override
  List<Object?> get props => [
        tenants,
        selectedTenantId,
        baseRent,
        charges,
        deductions,
        dueDate,
        notes,
        submitting,
        sentTenantName,
        sentBillNumber,
        sentTotal,
        sentDueDate,
        sentCharges,
        sentDeductions,
        sentPropertyName,
      ];
}

class BillGenerationCubit extends Cubit<BillGenerationState> {
  BillGenerationCubit({
    required SessionRepository session,
    required RentflowSupabaseService db,
  })  : _session = session,
        _db = db,
        super(BillGenerationState(
          charges: const [],
          deductions: const [],
          dueDate: _lastDayOfMonth(DateTime.now()),
        )) {
    load();
  }

  final SessionRepository _session;
  final RentflowSupabaseService _db;

  static DateTime _lastDayOfMonth(DateTime d) {
    final next = DateTime(d.year, d.month + 1, 1);
    return next.subtract(const Duration(days: 1));
  }

  Future<void> load() async {
    final uid = _session.readUser()?.userId ?? '';
    if (uid.isEmpty) {
      if (!isClosed) {
        emit(state.copyWith(tenants: [], selectedTenantId: null, baseRent: 0));
      }
      return;
    }
    try {
      final tenants = await _db.fetchOwnerTenants(uid);
      if (isClosed) return;
      final first = tenants.isNotEmpty ? tenants.first : null;
      emit(
        state.copyWith(
          tenants: tenants,
          selectedTenantId: first?.id,
          baseRent: first?.rentAmount ?? 0,
        ),
      );
    } on Exception {
      if (!isClosed) {
        emit(state.copyWith(tenants: [], selectedTenantId: null, baseRent: 0));
      }
    }
  }

  void selectTenant(String id) {
    TenantItem? match;
    for (final t in state.tenants) {
      if (t.id == id) {
        match = t;
        break;
      }
    }
    if (match == null) return;
    emit(state.copyWith(selectedTenantId: id, baseRent: match.rentAmount));
  }

  void setBaseRent(double v) => emit(state.copyWith(baseRent: v));

  void updateCharge(int index, ChargeLine line) {
    final next = [...state.charges];
    if (index >= 0 && index < next.length) next[index] = line;
    emit(state.copyWith(charges: next));
  }

  void addCharge() =>
      emit(state.copyWith(charges: [...state.charges, const ChargeLine()]));

  void removeCharge(int index) {
    final next = [...state.charges];
    if (index >= 0 && index < next.length) next.removeAt(index);
    emit(state.copyWith(charges: next));
  }

  void updateDeduction(int index, ChargeLine line) {
    final next = [...state.deductions];
    if (index >= 0 && index < next.length) next[index] = line;
    emit(state.copyWith(deductions: next));
  }

  void addDeduction() =>
      emit(state.copyWith(deductions: [...state.deductions, const ChargeLine()]));

  void removeDeduction(int index) {
    final next = [...state.deductions];
    if (index >= 0 && index < next.length) next.removeAt(index);
    emit(state.copyWith(deductions: next));
  }

  void setDueDate(DateTime d) => emit(state.copyWith(dueDate: d));

  void setNotes(String n) => emit(state.copyWith(notes: n));

  Future<void> submit() async {
    final tenant = state.selectedTenant;
    if (tenant == null) return;
    emit(state.copyWith(submitting: true));
    final uid = _session.readUser()?.userId ?? '';
    if (uid.isEmpty || tenant.propertyId.isEmpty) {
      emit(state.copyWith(submitting: false));
      return;
    }
    try {
      final lineItems = <String, dynamic>{
        'base_rent': state.baseRent,
        'charges': state.charges
            .map((c) => {'description': c.description, 'amount': c.amount})
            .toList(),
        'deductions': state.deductions
            .map((c) => {'description': c.description, 'amount': c.amount})
            .toList(),
      };
      final billNumber = await _db.createBillWithPayment(
        ownerId: uid,
        tenantId: tenant.id,
        propertyId: tenant.propertyId,
        totalAmount: state.total,
        dueDate: state.dueDate ?? DateTime.now(),
        notes: state.notes,
        lineItems: lineItems,
      );
      emit(
        state.copyWith(
          submitting: false,
          sentTenantName: tenant.name,
          sentBillNumber: billNumber,
          sentTotal: state.total,
          sentDueDate: state.dueDate,
          sentCharges: List.of(state.charges),
          sentDeductions: List.of(state.deductions),
          sentPropertyName: tenant.propertyName,
        ),
      );
    } on Exception {
      emit(state.copyWith(submitting: false));
    }
  }

  /// Resets form to a fresh state while keeping the tenant list loaded.
  void clearSent() {
    emit(
      BillGenerationState(
        tenants: state.tenants,
        selectedTenantId: state.selectedTenantId,
        baseRent: state.selectedTenant?.rentAmount ?? 0,
        charges: const [],
        deductions: const [],
        dueDate: _lastDayOfMonth(DateTime.now()),
        notes: '',
      ),
    );
  }
}
