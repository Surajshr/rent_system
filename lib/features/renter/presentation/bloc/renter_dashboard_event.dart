part of 'renter_dashboard_bloc.dart';

abstract class RenterDashboardEvent extends Equatable {
  const RenterDashboardEvent();

  @override
  List<Object?> get props => [];
}

class RenterDashboardStarted extends RenterDashboardEvent {
  const RenterDashboardStarted();
}

class RenterDashboardRefreshed extends RenterDashboardEvent {
  const RenterDashboardRefreshed();
}
