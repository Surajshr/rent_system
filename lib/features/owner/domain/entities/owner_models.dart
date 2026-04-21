import 'package:equatable/equatable.dart';

enum TenantPayStatus { paid, due, overdue }

enum PaymentStatus { paid, pending, overdue, cancelled }

class PropertyItem extends Equatable {
  const PropertyItem({
    required this.id,
    required this.name,
    required this.location,
    required this.tenantsOccupied,
    required this.unitsTotal,
    required this.baseRent,
  });

  final String id;
  final String name;
  final String location;
  final int tenantsOccupied;
  final int unitsTotal;
  final double baseRent;

  bool get isVacant => tenantsOccupied == 0;

  @override
  List<Object?> get props => [id, name, location, tenantsOccupied, unitsTotal, baseRent];
}

class TenantItem extends Equatable {
  const TenantItem({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.propertyName,
    required this.unit,
    required this.phone,
    required this.rentAmount,
    required this.status,
    this.email = '',
    this.renterProfileId,
  });

  final String id;
  final String propertyId;
  final String name;
  final String propertyName;
  final String unit;
  final String phone;
  final double rentAmount;
  final TenantPayStatus status;
  final String email;
  /// Non-null once a renter account has been linked to this tenant row.
  final String? renterProfileId;

  bool get isLinked => renterProfileId != null && renterProfileId!.isNotEmpty;

  @override
  List<Object?> get props =>
      [id, propertyId, name, propertyName, unit, phone, rentAmount, status, email, renterProfileId];
}

class PaymentRow extends Equatable {
  const PaymentRow({
    required this.id,
    required this.propertyName,
    required this.tenantName,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.billRef,
    this.paidDate,
  });

  final String id;
  final String propertyName;
  final String tenantName;
  final double amount;
  final String dueDate;
  final PaymentStatus status;
  final String billRef;
  final String? paidDate;

  @override
  List<Object?> get props =>
      [id, propertyName, tenantName, amount, dueDate, status, billRef, paidDate];
}

class ActivityItem extends Equatable {
  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.timeLabel,
  });

  final String title;
  final String subtitle;
  final double amount;
  final String timeLabel;

  @override
  List<Object?> get props => [title, subtitle, amount, timeLabel];
}

class BillLine extends Equatable {
  const BillLine({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  List<Object?> get props => [label, amount];
}
