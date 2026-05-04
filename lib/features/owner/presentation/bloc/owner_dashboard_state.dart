part of 'owner_dashboard_bloc.dart';

class OwnerDashboardState extends Equatable {
  const OwnerDashboardState._({
    required this.loading,
    this.totalProperties = 0,
    this.activeTenants = 0,
    this.collectedThisMonth = 0,
    this.pendingAmount = 0,
    this.collectionTarget = 0,
    this.overduePropertiesLabel = '',
    this.newTenantsLabel = '',
    this.activities = const [],
    this.dashboardImages = const [],
    this.cashVerifications = const [],
  });

  const OwnerDashboardState.loading() : this._(loading: true);

  const OwnerDashboardState.ready({
    required int totalProperties,
    required int activeTenants,
    required double collectedThisMonth,
    required double pendingAmount,
    required double collectionTarget,
    required String overduePropertiesLabel,
    required String newTenantsLabel,
    required List<ActivityItem> activities,
    List<StorageImageRef> dashboardImages = const [],
    List<CashVerificationRow> cashVerifications = const [],
  }) : this._(
         loading: false,
         totalProperties: totalProperties,
         activeTenants: activeTenants,
         collectedThisMonth: collectedThisMonth,
         pendingAmount: pendingAmount,
         collectionTarget: collectionTarget,
         overduePropertiesLabel: overduePropertiesLabel,
         newTenantsLabel: newTenantsLabel,
         activities: activities,
         dashboardImages: dashboardImages,
         cashVerifications: cashVerifications,
       );

  final bool loading;
  final int totalProperties;
  final int activeTenants;
  final double collectedThisMonth;
  final double pendingAmount;

  /// Expected monthly roll (sum of tenants' monthly rent) for comparison in UI.
  final double collectionTarget;
  final String overduePropertiesLabel;
  final String newTenantsLabel;
  final List<ActivityItem> activities;

  /// Resolved image URLs from Supabase Storage for the dashboard gallery.
  final List<StorageImageRef> dashboardImages;
  final List<CashVerificationRow> cashVerifications;

  @override
  List<Object?> get props => [
    loading,
    totalProperties,
    activeTenants,
    collectedThisMonth,
    pendingAmount,
    collectionTarget,
    overduePropertiesLabel,
    newTenantsLabel,
    activities,
    dashboardImages,
    cashVerifications,
  ];
}
