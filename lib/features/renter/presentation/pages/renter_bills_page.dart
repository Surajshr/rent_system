import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/utils/currency_formatter.dart';
import 'package:rent_system/features/common/widgets/status_badge.dart';
import 'package:rent_system/features/renter/domain/entities/renter_models.dart';
import 'package:rent_system/features/renter/presentation/cubit/renter_bills_cubit.dart';

class RenterBillsPage extends StatelessWidget {
  const RenterBillsPage({super.key});

  BadgeTone _tone(RenterBillStatus s) {
    switch (s) {
      case RenterBillStatus.paid:
        return BadgeTone.success;
      case RenterBillStatus.pending:
        return BadgeTone.warning;
      case RenterBillStatus.overdue:
        return BadgeTone.error;
    }
  }

  String _label(RenterBillStatus s) => s.name[0].toUpperCase() + s.name.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bills & Invoices')),
      body: BlocBuilder<RenterBillsCubit, RenterBillsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final cubit = context.read<RenterBillsCubit>();
          final items = cubit.visible();
          return Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: RenterBillFilter.values.map((f) {
                    final selected = state.filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: Text(f.name[0].toUpperCase() + f.name.substring(1)),
                        selected: selected,
                        onSelected: (_) => cubit.setFilter(f),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.checklist, size: 88, color: AppColors.neutral400),
                            const SizedBox(height: AppSpacing.md),
                            Text('No bills yet', style: Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) {
                          final b = items[i];
                          return Card(
                            child: InkWell(
                              onTap: () => context.pushNamed(
                                RouteNames.renterBillDetail,
                                pathParameters: {'id': b.id},
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppLayout.cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Generated on ${b.generatedOn}',
                                          style: Theme.of(context).textTheme.labelSmall,
                                        ),
                                        Text(
                                          '#${b.id}',
                                          style: Theme.of(context).textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      formatInr(b.amount),
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            color: AppColors.primary,
                                          ),
                                    ),
                                    Text('Due by ${b.dueDate}', style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        StatusBadge(label: _label(b.status), tone: _tone(b.status)),
                                        Row(
                                          children: [
                                            Text('View Details', style: Theme.of(context).textTheme.bodyMedium),
                                            const Icon(Icons.chevron_right),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
