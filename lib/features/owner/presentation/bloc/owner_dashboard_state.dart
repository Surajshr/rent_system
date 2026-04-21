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
        );

  final bool loading;
  final int totalProperties;
  final int activeTenants;
  final double collectedThisMonth;
  final double pendingAmount;
  /// Expected monthly rent roll (sum of tenant [monthly_rent]) for comparison in UI.
  final double collectionTarget;
  final String overduePropertiesLabel;
  final String newTenantsLabel;
  final List<ActivityItem> activities;

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
      ];
}
