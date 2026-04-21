import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/utils/currency_formatter.dart';
import 'package:rent_system/features/owner/presentation/cubit/bill_generation_cubit.dart';

class BillGenerationPage extends StatefulWidget {
  const BillGenerationPage({super.key});

  @override
  State<BillGenerationPage> createState() => _BillGenerationPageState();
}

class _BillGenerationPageState extends State<BillGenerationPage> {
  // Each charge row gets two controllers: description + amount.
  final List<TextEditingController> _chargeLabelCtrls = [];
  final List<TextEditingController> _chargeAmountCtrls = [];

  // Same for deductions.
  final List<TextEditingController> _deductLabelCtrls = [];
  final List<TextEditingController> _deductAmountCtrls = [];

  @override
  void dispose() {
    for (final c in [
      ..._chargeLabelCtrls,
      ..._chargeAmountCtrls,
      ..._deductLabelCtrls,
      ..._deductAmountCtrls,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Controller management ──────────────────────────────────────────────────

  void _addChargeControllers() {
    _chargeLabelCtrls.add(TextEditingController());
    _chargeAmountCtrls.add(TextEditingController());
  }

  void _removeChargeControllers(int index) {
    _chargeLabelCtrls[index].dispose();
    _chargeAmountCtrls[index].dispose();
    _chargeLabelCtrls.removeAt(index);
    _chargeAmountCtrls.removeAt(index);
  }

  void _addDeductControllers() {
    _deductLabelCtrls.add(TextEditingController());
    _deductAmountCtrls.add(TextEditingController());
  }

  void _removeDeductControllers(int index) {
    _deductLabelCtrls[index].dispose();
    _deductAmountCtrls[index].dispose();
    _deductLabelCtrls.removeAt(index);
    _deductAmountCtrls.removeAt(index);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionHeader(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
  );

  Widget _summaryRow(
    BuildContext context,
    String label,
    double amount, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : null,
              color: color,
            ),
          ),
          Text(
            '${amount < 0 ? '−' : ''}${formatInr(amount.abs())}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Bill')),
      body: BlocBuilder<BillGenerationCubit, BillGenerationState>(
        builder: (context, state) {
          // Show success screen while bill info is present.
          if (state.isSuccess) {
            return _BillSuccessScreen(state: state);
          }

          final cubit = context.read<BillGenerationCubit>();
          final df = DateFormat('MMM d, y');

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ── Select Tenant ──────────────────────────────────────────────
              _sectionHeader(context, 'Select Tenant'),
              if (state.tenants.isEmpty)
                const Text(
                  'No tenants found. Add tenants to your properties first.',
                  style: TextStyle(color: AppColors.neutral400),
                )
              else
                DropdownButtonFormField<String>(
                  value: state.selectedTenantId,
                  decoration: const InputDecoration(),
                  items: state.tenants
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(
                            '${t.name} · ${t.unit} (${formatInr(t.rentAmount)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) cubit.selectTenant(v);
                  },
                ),

              // ── Base Rent ──────────────────────────────────────────────────
              _sectionHeader(context, 'Rent Details'),
              TextFormField(
                key: ValueKey('base-${state.selectedTenantId}'),
                initialValue: state.baseRent.toStringAsFixed(0),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Base Rent',
                  prefixText: '₹ ',
                ),
                onChanged: (v) => cubit.setBaseRent(double.tryParse(v) ?? 0),
              ),

              // ── Additional Charges ─────────────────────────────────────────
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Additional Charges',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(_addChargeControllers);
                      cubit.addCharge();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),

              if (state.charges.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'No extra charges. Tap Add to include electricity, water, etc.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral400,
                    ),
                  ),
                )
              else
                ...List.generate(state.charges.length, (i) {
                  // Guard: ensure controllers exist for this index.
                  while (_chargeLabelCtrls.length <= i) _addChargeControllers();
                  return _LineRow(
                    key: ValueKey('charge-$i'),
                    labelCtrl: _chargeLabelCtrls[i],
                    amountCtrl: _chargeAmountCtrls[i],
                    labelHint: 'e.g. Electricity, Water',
                    color: AppColors.warning,
                    onChanged: (desc, amt) => cubit.updateCharge(
                      i,
                      ChargeLine(description: desc, amount: amt),
                    ),
                    onDelete: () {
                      setState(() => _removeChargeControllers(i));
                      cubit.removeCharge(i);
                    },
                  );
                }),

              // ── Deductions ─────────────────────────────────────────────────
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Deductions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(_addDeductControllers);
                      cubit.addDeduction();
                    },
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),

              if (state.deductions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'No deductions. Tap Add to deduct advance payment, discount, etc.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral400,
                    ),
                  ),
                )
              else
                ...List.generate(state.deductions.length, (i) {
                  while (_deductLabelCtrls.length <= i) _addDeductControllers();
                  return _LineRow(
                    key: ValueKey('deduct-$i'),
                    labelCtrl: _deductLabelCtrls[i],
                    amountCtrl: _deductAmountCtrls[i],
                    labelHint: 'e.g. Advance paid, Discount',
                    color: AppColors.secondary,
                    onChanged: (desc, amt) => cubit.updateDeduction(
                      i,
                      ChargeLine(description: desc, amount: amt),
                    ),
                    onDelete: () {
                      setState(() => _removeDeductControllers(i));
                      cubit.removeDeduction(i);
                    },
                  );
                }),

              // ── Live Summary ───────────────────────────────────────────────
              const SizedBox(height: AppSpacing.xl),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _summaryRow(context, 'Base Rent', state.baseRent),
                      if (state.chargesTotal > 0)
                        _summaryRow(
                          context,
                          'Additional Charges (+)',
                          state.chargesTotal,
                          color: AppColors.warning,
                        ),
                      if (state.deductionsTotal > 0)
                        _summaryRow(
                          context,
                          'Deductions (−)',
                          -state.deductionsTotal,
                          color: AppColors.secondary,
                        ),
                      const Divider(),
                      _summaryRow(
                        context,
                        'Total Due',
                        state.total,
                        bold: true,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Due Date ───────────────────────────────────────────────────
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Due Date',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                subtitle: Text(df.format(state.dueDate ?? DateTime.now())),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month_outlined),
                  tooltip: 'Pick due date',
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.dueDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) cubit.setDueDate(picked);
                  },
                ),
              ),

              // ── Notes ──────────────────────────────────────────────────────
              TextField(
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText:
                      'E.g. Please pay via bank transfer by the due date.',
                ),
                onChanged: cubit.setNotes,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Actions ────────────────────────────────────────────────────
              ElevatedButton(
                onPressed: state.submitting || state.selectedTenantId == null
                    ? null
                    : cubit.submit,
                child: state.submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Generate & Send Bill'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bill Success Screen
// ─────────────────────────────────────────────────────────────────────────────

class _BillSuccessScreen extends StatelessWidget {
  const _BillSuccessScreen({required this.state});

  final BillGenerationState state;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, y');
    final charges = state.sentCharges ?? [];
    final deductions = state.sentDeductions ?? [];
    final total = state.sentTotal ?? 0;
    final dueDate = state.sentDueDate;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.xl),

          // ── Success icon + headline ──────────────────────────────────────
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 52,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Bill Generated!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The bill has been created for ${state.sentTenantName}.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Bill summary card ────────────────────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppLayout.radiusCard),
              border: Border.all(color: AppColors.neutral200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bill reference
                  if (state.sentBillNumber != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bill #',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          state.sentBillNumber!,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.lg),
                  ],

                  // Tenant & property
                  _infoRow(context, 'Tenant', state.sentTenantName ?? ''),
                  if (state.sentPropertyName != null)
                    _infoRow(context, 'Property', state.sentPropertyName!),
                  if (dueDate != null)
                    _infoRow(context, 'Due Date', df.format(dueDate)),

                  const Divider(height: AppSpacing.lg),

                  // Breakdown
                  _amountRow(
                    context,
                    'Base Rent',
                    total -
                        (state.sentCharges ?? []).fold(
                          0.0,
                          (a, b) => a + b.amount,
                        ) +
                        (state.sentDeductions ?? []).fold(
                          0.0,
                          (a, b) => a + b.amount,
                        ),
                  ),

                  if (charges.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Additional Charges',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.neutral400,
                      ),
                    ),
                    ...charges
                        .where((c) => c.amount > 0)
                        .map(
                          (c) => _amountRow(
                            context,
                            c.description.isEmpty ? 'Charge' : c.description,
                            c.amount,
                            color: AppColors.warning,
                          ),
                        ),
                  ],

                  if (deductions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Deductions',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.neutral400,
                      ),
                    ),
                    ...deductions
                        .where((d) => d.amount > 0)
                        .map(
                          (d) => _amountRow(
                            context,
                            d.description.isEmpty ? 'Deduction' : d.description,
                            -d.amount,
                            color: AppColors.secondary,
                          ),
                        ),
                  ],

                  const Divider(height: AppSpacing.lg),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Due',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        formatInr(total),
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Actions ──────────────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: () {
              context.read<BillGenerationCubit>().clearSent();
            },
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Generate New Bill'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => context.goNamed(RouteNames.ownerDashboard),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Go to Dashboard'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.neutral700),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    BuildContext context,
    String label,
    double amount, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            '${amount < 0 ? '−' : ''}${formatInr(amount.abs())}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable row for a single charge / deduction line
// ─────────────────────────────────────────────────────────────────────────────

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.labelCtrl,
    required this.amountCtrl,
    required this.labelHint,
    required this.color,
    required this.onChanged,
    required this.onDelete,
    super.key,
  });

  final TextEditingController labelCtrl;
  final TextEditingController amountCtrl;
  final String labelHint;
  final Color color;
  final void Function(String description, double amount) onChanged;
  final VoidCallback onDelete;

  double get _currentAmount => double.tryParse(amountCtrl.text) ?? 0;
  String get _currentLabel => labelCtrl.text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: labelCtrl,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: labelHint,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral400,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              onChanged: (_) => onChanged(_currentLabel, _currentAmount),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Amount
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: amountCtrl,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                prefixStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onChanged: (_) => onChanged(_currentLabel, _currentAmount),
            ),
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.neutral400,
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
