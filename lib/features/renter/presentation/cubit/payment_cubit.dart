import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_system/core/errors/app_exception.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart'
    show PayRentInvoiceSummary, RentflowSupabaseService;

enum PayMethod { bank, upi, card, cheque }

class PaymentState extends Equatable {
  const PaymentState({
    this.method = PayMethod.bank,
    this.invoiceLoading = true,
    this.invoice,
    this.invoiceError,
    this.processing = false,
    this.success = false,
    this.error,
    this.reference,
  });

  final PayMethod method;
  final bool invoiceLoading;
  final PayRentInvoiceSummary? invoice;
  final String? invoiceError;
  final bool processing;
  final bool success;
  final String? error;
  final String? reference;

  PaymentState copyWith({
    PayMethod? method,
    bool? invoiceLoading,
    PayRentInvoiceSummary? invoice,
    String? invoiceError,
    bool? processing,
    bool? success,
    String? error,
    String? reference,
  }) {
    return PaymentState(
      method: method ?? this.method,
      invoiceLoading: invoiceLoading ?? this.invoiceLoading,
      invoice: invoice ?? this.invoice,
      invoiceError: invoiceError,
      processing: processing ?? this.processing,
      success: success ?? this.success,
      error: error,
      reference: reference ?? this.reference,
    );
  }

  @override
  List<Object?> get props =>
      [method, invoiceLoading, invoice, invoiceError, processing, success, error, reference];
}

class PaymentCubit extends Cubit<PaymentState> {
  PaymentCubit({
    required RentflowSupabaseService db,
    required SessionRepository session,
    String? initialBillId,
  })  : _db = db,
        _session = session,
        _initialBillId = initialBillId,
        super(const PaymentState()) {
    load();
  }

  final RentflowSupabaseService _db;
  final SessionRepository _session;
  final String? _initialBillId;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(invoiceLoading: true, invoiceError: null));
    final uid = _session.readUser()?.userId ?? '';
    if (uid.isEmpty) {
      if (!isClosed) {
        emit(state.copyWith(invoiceLoading: false, invoiceError: 'Not signed in'));
      }
      return;
    }
    try {
      PayRentInvoiceSummary? summary;
      final billId = _initialBillId;
      if (billId != null && billId.isNotEmpty) {
        summary = await _db.fetchPayRentSummary(renterProfileId: uid, billId: billId);
      }
      if (!isClosed) summary ??= await _loadDefaultInvoice(uid);
      if (isClosed) return;
      if (summary == null) {
        emit(
          state.copyWith(
            invoiceLoading: false,
            invoiceError: 'No pending bill found. Ask your landlord to generate a bill.',
          ),
        );
        return;
      }
      emit(state.copyWith(invoiceLoading: false, invoice: summary));
    } on AppException catch (e) {
      if (!isClosed) emit(state.copyWith(invoiceLoading: false, invoiceError: e.message));
    } on Exception {
      if (!isClosed) {
        emit(state.copyWith(
          invoiceLoading: false,
          invoiceError: 'Could not load bill details.',
        ));
      }
    }
  }

  Future<PayRentInvoiceSummary?> _loadDefaultInvoice(String uid) async {
    final lease = await _db.fetchRenterLeaseSummary(uid);
    final bid = lease.primaryBillId;
    if (bid == null) return null;
    return _db.fetchPayRentSummary(renterProfileId: uid, billId: bid);
  }

  void selectMethod(PayMethod m) => emit(state.copyWith(method: m, error: null));

  Future<void> submit() async {
    final inv = state.invoice;
    if (inv == null) return;
    emit(state.copyWith(processing: true, error: null, success: false));
    try {
      final label = switch (state.method) {
        PayMethod.bank => 'Bank transfer',
        PayMethod.upi => 'UPI',
        PayMethod.card => 'Card',
        PayMethod.cheque => 'Cheque',
      };
      final ref = await _db.recordRenterPayment(paymentId: inv.paymentId, methodLabel: label);
      emit(state.copyWith(processing: false, success: true, reference: ref));
    } on AppException catch (e) {
      emit(state.copyWith(processing: false, error: e.message));
    } on Exception {
      emit(state.copyWith(processing: false, error: 'Payment could not be recorded.'));
    }
  }

  void reset() => emit(const PaymentState());

  String bankAccountName() => state.invoice?.landlordName ?? 'Landlord';

  String bankAccountNumber() => 'XXXX1234';

  String bankIfsc() => 'HDFC0001234';

  String bankBranch() => '—';

  String upiId() => 'rentflow@upi';
}
