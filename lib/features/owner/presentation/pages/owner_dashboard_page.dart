import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_shadows.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/utils/currency_formatter.dart';
import 'package:rent_system/features/common/widgets/initials_avatar.dart';
import 'package:rent_system/features/owner/presentation/bloc/owner_dashboard_bloc.dart';
import 'package:rent_system/features/owner/presentation/pages/owner_shell_page.dart';
import 'package:rent_system/l10n/l10n.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.read<SessionRepository>().readUser();
    final name = session?.displayName ?? 'there';
    final date = DateFormat('EEEE, MMM d').format(DateTime.now());

    return BlocBuilder<OwnerDashboardBloc, OwnerDashboardState>(
      builder: (context, state) {
        if (state.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<OwnerDashboardBloc>().add(
                  const OwnerDashboardRefreshed(),
                );
                await context.read<OwnerDashboardBloc>().stream.firstWhere(
                  (s) => !s.loading,
                );
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.greeting(name),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              date,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        label: 'Notifications, 3 unread',
                        button: true,
                        child: Badge.count(
                          count: 3,
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.05,
                    children: [
                      _statCard(
                        context,
                        icon: Icons.home_work_outlined,
                        iconColor: AppColors.primary,
                        value: '${state.totalProperties}',
                        label: l.activeProperties,
                        sub: l.manageAll,
                        subColor: AppColors.primary,
                        onSub: () =>
                            context.goNamed(RouteNames.ownerProperties),
                      ),
                      _statCard(
                        context,
                        icon: Icons.groups_2_outlined,
                        iconColor: AppColors.primary,
                        value: '${state.activeTenants}',
                        label: l.tenants,
                        sub: state.newTenantsLabel,
                        subColor: AppColors.neutral700,
                      ),
                      _statCard(
                        context,
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: AppColors.secondary,
                        value: formatInr(state.collectedThisMonth),
                        label: l.collected,
                        sub: l.vsTarget(formatInr(state.collectionTarget)),
                        subColor: AppColors.neutral700,
                      ),
                      _statCard(
                        context,
                        icon: Icons.schedule,
                        iconColor: AppColors.warning,
                        value: formatInr(state.pendingAmount),
                        label: l.pending,
                        sub: state.overduePropertiesLabel,
                        subColor: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l.quickActions,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _quickAction(
                    context,
                    icon: Icons.add_home_work_outlined,
                    label: l.addProperty,
                    onTap: () => context.goNamed(RouteNames.ownerProperties),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _quickAction(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: l.generateBill,
                    onTap: () =>
                        context.pushNamed(RouteNames.ownerBillGeneration),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _quickAction(
                    context,
                    icon: Icons.payments_outlined,
                    label: l.viewPayments,
                    onTap: () => context.goOwnerPayments(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.recentActivity,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(l.viewAll),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...state.activities.map(
                    (a) => Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        leading: InitialsAvatar(name: a.subtitle),
                        title: Text('${a.title} · ${a.subtitle}'),
                        subtitle: Text(
                          a.timeLabel,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        trailing: Text(
                          formatInr(a.amount),
                          style: Theme.of(
                            context,
                          ).textTheme.displayMedium?.copyWith(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String sub,
    required Color subColor,
    VoidCallback? onSub,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.radiusCard),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppShadows.elevation1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: AppLayout.iconPrimary),
            const Spacer(),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            if (onSub != null)
              TextButton(
                onPressed: onSub,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  sub,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: subColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Text(
                sub,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: subColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: AppLayout.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: AppLayout.iconPrimary),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: AppColors.neutral900,
        ),
      ),
    );
  }
}
