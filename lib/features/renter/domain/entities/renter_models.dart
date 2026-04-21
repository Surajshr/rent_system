import 'package:equatable/equatable.dart';

enum RenterBillStatus { paid, pending, overdue }

class RenterBill extends Equatable {
  const RenterBill({
    required this.id,
    required this.generatedOn,
    required this.dueDate,
    required this.amount,
    required this.status,
    required this.baseRent,
    required this.charges,
    required this.deductions,
  });

  final String id;
  final String generatedOn;
  final String dueDate;
  final double amount;
  final RenterBillStatus status;
  final double baseRent;
  final Map<String, double> charges;
  final Map<String, double> deductions;

  @override
  List<Object?> get props => [id, generatedOn, dueDate, amount, status, baseRent, charges, deductions];
}

class RenterPaymentHistoryItem extends Equatable {
  const RenterPaymentHistoryItem({
    required this.billDate,
    required this.amount,
    required this.status,
    required this.transactionId,
    required this.method,
    required this.paidOn,
    required this.billRef,
  });

  final String billDate;
  final double amount;
  final String status;
  final String transactionId;
  final String method;
  final String paidOn;
  final String billRef;

  @override
  List<Object?> get props => [billDate, amount, status, transactionId, method, paidOn, billRef];
}
