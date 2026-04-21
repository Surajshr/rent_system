part of 'owner_dashboard_bloc.dart';

abstract class OwnerDashboardEvent extends Equatable {
  const OwnerDashboardEvent();

  @override
  List<Object?> get props => [];
}

class OwnerDashboardStarted extends OwnerDashboardEvent {
  const OwnerDashboardStarted();
}

class OwnerDashboardRefreshed extends OwnerDashboardEvent {
  const OwnerDashboardRefreshed();
}
