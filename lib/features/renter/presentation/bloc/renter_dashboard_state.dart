part of 'renter_dashboard_bloc.dart';

class RenterDashboardState extends Equatable {
  const RenterDashboardState._({
    required this.loading,
    this.hasLease = false,
    this.primaryBillId,
    this.propertyName = '',
    this.landlordName = '',
    this.landlordPhone = '',
    this.landlordEmail = '',
    this.currentAmount = 0,
    this.dueLabel = '',
    this.daysRemaining = 0,
    this.isPaid = false,
    this.nextPaymentDate = '',
    this.nextPaymentAmount = 0,
    this.lastPaidDate = '',
    this.lastPaidAmount = 0,
    this.lastBillRef = '',
    this.annualTotal = 0,
    this.annualPaid = 0,
    this.annualRemaining = 0,
  });

  const RenterDashboardState.loading() : this._(loading: true);

  const RenterDashboardState.ready({
    required bool hasLease,
    required String? primaryBillId,
    required String propertyName,
    required String landlordName,
    required String landlordPhone,
    required String landlordEmail,
    required double currentAmount,
    required String dueLabel,
    required int daysRemaining,
    required bool isPaid,
    required String nextPaymentDate,
    required double nextPaymentAmount,
    required String lastPaidDate,
    required double lastPaidAmount,
    required String lastBillRef,
    required double annualTotal,
    required double annualPaid,
    required double annualRemaining,
  }) : this._(
          loading: false,
          hasLease: hasLease,
          primaryBillId: primaryBillId,
          propertyName: propertyName,
          landlordName: landlordName,
          landlordPhone: landlordPhone,
          landlordEmail: landlordEmail,
          currentAmount: currentAmount,
          dueLabel: dueLabel,
          daysRemaining: daysRemaining,
          isPaid: isPaid,
          nextPaymentDate: nextPaymentDate,
          nextPaymentAmount: nextPaymentAmount,
          lastPaidDate: lastPaidDate,
          lastPaidAmount: lastPaidAmount,
          lastBillRef: lastBillRef,
          annualTotal: annualTotal,
          annualPaid: annualPaid,
          annualRemaining: annualRemaining,
        );

  final bool loading;
  final bool hasLease;
  final String? primaryBillId;
  final String propertyName;
  final String landlordName;
  final String landlordPhone;
  final String landlordEmail;
  final double currentAmount;
  final String dueLabel;
  final int daysRemaining;
  final bool isPaid;
  final String nextPaymentDate;
  final double nextPaymentAmount;
  final String lastPaidDate;
  final double lastPaidAmount;
  final String lastBillRef;
  final double annualTotal;
  final double annualPaid;
  final double annualRemaining;

  double get annualProgress =>
      annualTotal == 0 ? 0 : (annualPaid / annualTotal).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => [
        loading,
        hasLease,
        primaryBillId,
        propertyName,
        landlordName,
        landlordPhone,
        landlordEmail,
        currentAmount,
        dueLabel,
        daysRemaining,
        isPaid,
        nextPaymentDate,
        nextPaymentAmount,
        lastPaidDate,
        lastPaidAmount,
        lastBillRef,
        annualTotal,
        annualPaid,
        annualRemaining,
      ];
}
