import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/core/utils/currency_formatter.dart';
import 'package:rent_system/features/common/widgets/status_badge.dart';
import 'package:rent_system/features/renter/domain/entities/renter_models.dart';
import 'package:rent_system/l10n/l10n.dart';

class RenterBillDetailPage extends StatefulWidget {
  const RenterBillDetailPage({
    required this.billId,
    required this.db,
    super.key,
  });

  final String billId;
  final RentflowSupabaseService db;

  @override
  State<RenterBillDetailPage> createState() => _RenterBillDetailPageState();
}

class _RenterBillDetailPageState extends State<RenterBillDetailPage> {
  Future<RenterBill?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= () {
      final uid = context.read<SessionRepository>().readUser()?.userId ?? '';
      if (uid.isEmpty || widget.billId.isEmpty) {
        return Future<RenterBill?>.value(null);
      }
      return widget.db.fetchBillForRenter(renterProfileId: uid, billId: widget.billId);
    }();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RenterBill?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final bill = snapshot.data;
        if (bill == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bill')),
            body: const Center(child: Text('Bill not found or you do not have access.')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text('${context.l10n.bills} ${bill.id.substring(0, 8)}…')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(context.l10n.rentBreakdown, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              _line(context, context.l10n.baseRent, bill.baseRent),
              const SizedBox(height: AppSpacing.sm),
              Text(context.l10n.additionalCharges, style: Theme.of(context).textTheme.labelLarge),
              ...bill.charges.entries.map((e) => _line(context, e.key, e.value)),
              const SizedBox(height: AppSpacing.sm),
              Text(context.l10n.deductions, style: Theme.of(context).textTheme.labelLarge),
              ...bill.deductions.entries.map((e) => _line(context, e.key, -e.value)),
              const Divider(),
              _line(context, context.l10n.totalDue, bill.amount, bold: true),
              const SizedBox(height: AppSpacing.lg),
              Text('${context.l10n.generated}: ${bill.generatedOn}', style: Theme.of(context).textTheme.bodySmall),
              Text('${context.l10n.dueDate}: ${bill.dueDate}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              StatusBadge(
                label: bill.status.name[0].toUpperCase() + bill.status.name.substring(1),
                tone: bill.status == RenterBillStatus.paid
                    ? BadgeTone.success
                    : bill.status == RenterBillStatus.overdue
                        ? BadgeTone.error
                        : BadgeTone.warning,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: bill.status == RenterBillStatus.paid
                    ? null
                    : () => context.pushNamed(RouteNames.renterPayRent, extra: bill.id),
                child: Text(context.l10n.payNow),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(onPressed: () {}, child: Text(context.l10n.downloadInvoice)),
              OutlinedButton(onPressed: () {}, child: Text(context.l10n.shareBill)),
              TextButton(onPressed: () {}, child: Text(context.l10n.contactLandlord)),
            ],
          ),
        );
      },
    );
  }

  Widget _line(BuildContext context, String label, double amount, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        Text(
          formatInr(amount.abs()),
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
        ),
      ],
    );
  }
}
