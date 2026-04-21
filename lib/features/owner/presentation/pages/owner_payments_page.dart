import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/utils/currency_formatter.dart';
import 'package:rent_system/features/common/widgets/status_badge.dart';
import 'package:rent_system/features/owner/domain/entities/owner_models.dart';
import 'package:rent_system/features/owner/presentation/cubit/payment_tracking_cubit.dart';
import 'package:rent_system/l10n/l10n.dart';

class OwnerPaymentsPage extends StatelessWidget {
  const OwnerPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.payments),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: BlocBuilder<PaymentTrackingCubit, PaymentTrackingState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final cubit = context.read<PaymentTrackingCubit>();
          final rows = cubit.filtered();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _summary(
                context,
                collected: state.totalCollected,
                pending: state.totalPending,
                overdue: state.totalOverdue,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxl),
                  child:                   Text(
                    context.l10n.noPaymentsRecorded,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              else
                ...rows.map((p) => _PaymentTile(payment: p)),
            ],
          );
        },
      ),
    );
  }

  Widget _summary(
    BuildContext context, {
    required double collected,
    required double pending,
    required double overdue,
  }) {
    return Row(
      children: [
        Expanded(
          child: _pill(
            context,
            title: context.l10n.collected,
            value: formatInr(collected),
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _pill(
            context,
            title: context.l10n.pending,
            value: formatInr(pending),
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _pill(
            context,
            title: context.l10n.overdue,
            value: formatInr(overdue),
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _pill(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppLayout.radiusCard),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final PaymentRow payment;

  BadgeTone _tone(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:
        return BadgeTone.success;
      case PaymentStatus.pending:
        return BadgeTone.warning;
      case PaymentStatus.overdue:
        return BadgeTone.error;
      case PaymentStatus.cancelled:
        return BadgeTone.neutral;
    }
  }

  String _label(PaymentStatus s) => s.name[0].toUpperCase() + s.name.substring(1);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentTrackingCubit>();
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppLayout.cardPadding),
        title: Text(payment.propertyName, style: Theme.of(context).textTheme.headlineSmall),
        subtitle: Text(payment.tenantName, style: Theme.of(context).textTheme.bodySmall),
        isThreeLine: false,
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatInr(payment.amount),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xs),
            StatusBadge(label: _label(payment.status), tone: _tone(payment.status)),
          ],
        ),
        onTap: () {
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
                    Text('${payment.tenantName}', style: Theme.of(ctx).textTheme.headlineSmall),
                    Text('Due ${payment.dueDate}', style: Theme.of(ctx).textTheme.bodySmall),
                    Text(formatInr(payment.amount), style: Theme.of(ctx).textTheme.displayMedium),
                    if (payment.paidDate != null) Text('Paid ${payment.paidDate}'),
                    Text('Bill reference #${payment.billRef}'),
                    const SizedBox(height: AppSpacing.lg),
                    if (payment.status == PaymentStatus.pending)
                      ElevatedButton(
                        onPressed: () {
                          cubit.markPaid(payment.id);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Mark as Paid'),
                      ),
                    OutlinedButton(onPressed: () {}, child: const Text('Send Reminder')),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Delete Bill', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
