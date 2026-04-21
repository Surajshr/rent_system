import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/utils/currency_formatter.dart';
import 'package:rent_system/features/common/widgets/status_badge.dart';
import 'package:rent_system/features/renter/domain/entities/renter_models.dart';
import 'package:rent_system/features/renter/presentation/cubit/payment_history_cubit.dart';

class RenterPaymentHistoryPage extends StatelessWidget {
  const RenterPaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: BlocBuilder<PaymentHistoryCubit, PaymentHistoryState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return Center(
              child: Text('No payments recorded yet', style: Theme.of(context).textTheme.bodyLarge),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _summaryTile(
                      context,
                      'Total Paid YTD',
                      formatInr(state.totalYtd),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _summaryTile(
                      context,
                      'Average Payment',
                      formatInr(state.average),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...state.items.map((p) {
                final paid = p.status.toLowerCase() == 'paid';
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppLayout.cardPadding),
                    leading: Text(p.billDate, style: Theme.of(context).textTheme.bodySmall),
                    title: Text(formatInr(p.amount), style: Theme.of(context).textTheme.headlineSmall),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StatusBadge(
                          label: p.status,
                          tone: paid ? BadgeTone.success : BadgeTone.error,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(p.transactionId, style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                    onTap: () => _details(context, p),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryTile(BuildContext context, String title, String value) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppLayout.radiusCard),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  void _details(BuildContext context, RenterPaymentHistoryItem p) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(formatInr(p.amount), style: Theme.of(ctx).textTheme.displayMedium),
              Text('Bill #${p.billRef}', style: Theme.of(ctx).textTheme.bodySmall),
              Text('Payment Date: ${p.paidOn}', style: Theme.of(ctx).textTheme.bodySmall),
              Text('Method: ${p.method}', style: Theme.of(ctx).textTheme.bodySmall),
              Text('Transaction ID: ${p.transactionId}', style: Theme.of(ctx).textTheme.bodySmall),
              Text('Status: ${p.status} ✓', style: Theme.of(ctx).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: () {}, child: const Text('Download Receipt')),
              OutlinedButton(onPressed: () {}, child: const Text('Share Receipt')),
            ],
          ),
        );
      },
    );
  }
}
