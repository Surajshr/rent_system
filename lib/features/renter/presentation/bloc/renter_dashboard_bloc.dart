import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';

part 'renter_dashboard_event.dart';
part 'renter_dashboard_state.dart';

class RenterDashboardBloc
    extends Bloc<RenterDashboardEvent, RenterDashboardState> {
  RenterDashboardBloc({
    required SessionRepository session,
    required RentflowSupabaseService db,
  })  : _session = session,
        _db = db,
        super(const RenterDashboardState.loading()) {
    on<RenterDashboardStarted>(_onStarted);
    on<RenterDashboardRefreshed>(_onStarted);
  }

  final SessionRepository _session;
  final RentflowSupabaseService _db;

  Future<void> _onStarted(
    RenterDashboardEvent event,
    Emitter<RenterDashboardState> emit,
  ) async {
    emit(const RenterDashboardState.loading());
    final uid = _session.readUser()?.userId ?? '';
    if (uid.isEmpty) {
      emit(
        const RenterDashboardState.ready(
          hasLease: false,
          primaryBillId: null,
          propertyName: '',
          landlordName: '',
          landlordPhone: '',
          landlordEmail: '',
          currentAmount: 0,
          dueLabel: '',
          daysRemaining: 0,
          isPaid: false,
          nextPaymentDate: '',
          nextPaymentAmount: 0,
          lastPaidDate: '',
          lastPaidAmount: 0,
          lastBillRef: '',
          annualTotal: 0,
          annualPaid: 0,
          annualRemaining: 0,
        ),
      );
      return;
    }
    try {
      final lease = await _db.fetchRenterLeaseSummary(uid);
      if (!lease.hasLease) {
        emit(
          const RenterDashboardState.ready(
            hasLease: false,
            primaryBillId: null,
            propertyName: 'No lease linked yet',
            landlordName: '',
            landlordPhone: '',
            landlordEmail: '',
            currentAmount: 0,
            dueLabel: '',
            daysRemaining: 0,
            isPaid: false,
            nextPaymentDate: '',
            nextPaymentAmount: 0,
            lastPaidDate: '',
            lastPaidAmount: 0,
            lastBillRef: '',
            annualTotal: 0,
            annualPaid: 0,
            annualRemaining: 0,
          ),
        );
        return;
      }
      emit(
        RenterDashboardState.ready(
          hasLease: true,
          primaryBillId: lease.primaryBillId,
          propertyName: lease.propertyName,
          landlordName: lease.landlordName,
          landlordPhone: lease.landlordPhone,
          landlordEmail: lease.landlordEmail,
          currentAmount: lease.currentAmount,
          dueLabel: lease.dueLabel,
          daysRemaining: lease.daysRemaining,
          isPaid: lease.isPaid,
          nextPaymentDate: lease.nextPaymentDate,
          nextPaymentAmount: lease.nextPaymentAmount,
          lastPaidDate: lease.lastPaidDate,
          lastPaidAmount: lease.lastPaidAmount,
          lastBillRef: lease.lastBillRef,
          annualTotal: lease.annualTotal,
          annualPaid: lease.annualPaid,
          annualRemaining: lease.annualRemaining,
        ),
      );
    } on Exception {
      emit(
        const RenterDashboardState.ready(
          hasLease: false,
          primaryBillId: null,
          propertyName: '',
          landlordName: '',
          landlordPhone: '',
          landlordEmail: '',
          currentAmount: 0,
          dueLabel: '',
          daysRemaining: 0,
          isPaid: false,
          nextPaymentDate: '',
          nextPaymentAmount: 0,
          lastPaidDate: '',
          lastPaidAmount: 0,
          lastBillRef: '',
          annualTotal: 0,
          annualPaid: 0,
          annualRemaining: 0,
        ),
      );
    }
  }
}
