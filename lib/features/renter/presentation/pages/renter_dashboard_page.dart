import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_shadows.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/utils/currency_formatter.dart';
import 'package:rent_system/features/renter/presentation/bloc/renter_dashboard_bloc.dart';
import 'package:rent_system/l10n/l10n.dart';

class RenterDashboardPage extends StatelessWidget {
  const RenterDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionRepository>().readUser();
    final name = session?.displayName ?? 'there';

    return BlocBuilder<RenterDashboardBloc, RenterDashboardState>(
      builder: (context, state) {
        if (state.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text('Hi, $name', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(state.propertyName, style: Theme.of(context).textTheme.bodySmall),
                if (!state.hasLease) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.noLeaseDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppLayout.radiusCard),
                    boxShadow: AppShadows.elevation2,
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              state.isPaid ? Icons.check_circle : Icons.schedule,
                              color: state.isPaid ? AppColors.secondary : AppColors.warning,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(context.l10n.rentDue, style: Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          formatInr(state.currentAmount),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 34),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(context.l10n.dueBy(state.dueLabel), style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          context.l10n.daysRemaining(state.daysRemaining),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondary),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: !state.hasLease || state.primaryBillId == null
                                ? null
                                : () => context.pushNamed(
                                      RouteNames.renterPayRent,
                                      extra: state.primaryBillId,
                                    ),
                            child: Text(context.l10n.payNow),
                          ),
                        ),
                        TextButton(
                          onPressed: !state.hasLease || state.primaryBillId == null
                              ? null
                              : () => context.pushNamed(
                                    RouteNames.renterBillDetail,
                                    pathParameters: {'id': state.primaryBillId!},
                                  ),
                          child: Text(context.l10n.viewBillDetails),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.1,
                  children: [
                    _smallCard(
                      context,
                      title: context.l10n.nextPayment,
                      lines: [
                        state.nextPaymentDate,
                        formatInr(state.nextPaymentAmount),
                        context.l10n.recurringMonthly,
                      ],
                    ),
                    _smallCard(
                      context,
                      title: context.l10n.lastPaymentPaid,
                      lines: [
                        state.lastPaidDate,
                        formatInr(state.lastPaidAmount),
                        state.lastBillRef,
                      ],
                    ),
                    _smallCard(
                      context,
                      title: context.l10n.annualRent,
                      lines: [
                        'Total ${formatInr(state.annualTotal)}',
                        'Paid ${formatInr(state.annualPaid)}',
                        'Remaining ${formatInr(state.annualRemaining)}',
                        '${(state.annualProgress * 100).round()}% paid',
                      ],
                    ),
                    _smallCard(
                      context,
                      title: context.l10n.landlordInfo,
                      lines: [
                        state.landlordName,
                        state.landlordPhone,
                        state.landlordEmail,
                      ],
                      onTapLine: (line) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Contact: $line')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _smallCard(
    BuildContext context, {
    required String title,
    required List<String> lines,
    void Function(String line)? onTapLine,
  }) {
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
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            ...lines.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: InkWell(
                  onTap: onTapLine == null ? null : () => onTapLine(l),
                  child: Text(l, style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
