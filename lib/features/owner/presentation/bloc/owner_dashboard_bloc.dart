import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/features/owner/domain/entities/owner_models.dart';

part 'owner_dashboard_event.dart';
part 'owner_dashboard_state.dart';

class OwnerDashboardBloc
    extends Bloc<OwnerDashboardEvent, OwnerDashboardState> {
  OwnerDashboardBloc({
    required SessionRepository session,
    required RentflowSupabaseService db,
  }) : _session = session,
       _db = db,
       super(const OwnerDashboardState.loading()) {
    on<OwnerDashboardStarted>(_onStarted);
    on<OwnerDashboardRefreshed>(_onStarted);
  }

  final SessionRepository _session;
  final RentflowSupabaseService _db;

  Future<void> _onStarted(
    OwnerDashboardEvent event,
    Emitter<OwnerDashboardState> emit,
  ) async {
    emit(const OwnerDashboardState.loading());
    final uid = _session.readUser()?.userId ?? '';
    if (uid.isEmpty) {
      emit(
        const OwnerDashboardState.ready(
          totalProperties: 0,
          activeTenants: 0,
          collectedThisMonth: 0,
          pendingAmount: 0,
          collectionTarget: 0,
          overduePropertiesLabel: '0 payments overdue',
          newTenantsLabel: '+0 this month',
          activities: [],
        ),
      );
      return;
    }
    try {
      final metrics = await _db.fetchOwnerDashboardMetrics(uid);
      final target = await _db.sumTenantMonthlyRentForOwner(uid);
      final activities = await _db.fetchRecentActivities(uid);
      var cashVerifications = const <CashVerificationRow>[];
      try {
        cashVerifications = await _db.fetchOwnerCashVerifications(uid);
      } on Exception {
        cashVerifications = const <CashVerificationRow>[];
      }
      var dashboardImages = const <StorageImageRef>[];
      try {
        dashboardImages = await _db.fetchStorageImageFiles(
          bucket: RentflowSupabaseService.kQrCodesBucket,
          folderPath: RentflowSupabaseService.kPaymentQrFolder,
        );
      } on Exception {
        dashboardImages = const <StorageImageRef>[];
      }
      final overdueCount = metrics['overdueCount'] as int? ?? 0;
      final newTenants = metrics['newTenantsThisMonth'] as int? ?? 0;
      emit(
        OwnerDashboardState.ready(
          totalProperties: metrics['totalProperties'] as int? ?? 0,
          activeTenants: metrics['activeTenants'] as int? ?? 0,
          collectedThisMonth:
              (metrics['collectedThisMonth'] as num?)?.toDouble() ?? 0,
          pendingAmount: (metrics['pendingAmount'] as num?)?.toDouble() ?? 0,
          collectionTarget: target,
          overduePropertiesLabel: '$overdueCount payments overdue',
          newTenantsLabel: '+$newTenants this month',
          activities: activities,
          dashboardImages: dashboardImages,
          cashVerifications: cashVerifications,
        ),
      );
    } on Exception {
      emit(
        const OwnerDashboardState.ready(
          totalProperties: 0,
          activeTenants: 0,
          collectedThisMonth: 0,
          pendingAmount: 0,
          collectionTarget: 0,
          overduePropertiesLabel: '—',
          newTenantsLabel: '—',
          activities: [],
        ),
      );
    }
  }
}
