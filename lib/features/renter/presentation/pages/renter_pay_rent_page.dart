import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/utils/currency_formatter.dart';
import 'package:rent_system/features/renter/presentation/cubit/payment_cubit.dart';
import 'package:rent_system/l10n/l10n.dart';

class RenterPayRentPage extends StatelessWidget {
  const RenterPayRentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.payRentTitle)),
      body: BlocConsumer<PaymentCubit, PaymentState>(
        listenWhen: (p, c) => p.success != c.success && c.success,
        listener: (context, state) {
          final inv = state.invoice;
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l.paymentSuccessful),
              content: Text('${formatInr(inv?.amount ?? 0)}\nRef: ${state.reference}'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.goNamed(RouteNames.renterDashboard);
                  },
                  child: Text(l.returnToDashboard),
                ),
              ],
            ),
          );
        },
        builder: (context, state) {
          if (state.invoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.invoiceError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(state.invoiceError!, textAlign: TextAlign.center),
              ),
            );
          }
          final inv = state.invoice;
          if (inv == null) return Center(child: Text(l.noInvoiceFound));
          final cubit = context.read<PaymentCubit>();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inv.propertyName, style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        formatInr(inv.amount),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                      ),
                      Text('${l.dueBy(inv.dueLabel)}', style: Theme.of(context).textTheme.bodySmall),
                      Text('${l.billRef} #${inv.billNumber}', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l.paymentMethod, style: Theme.of(context).textTheme.headlineSmall),
              RadioListTile<PayMethod>(
                title: Text(l.bankTransfer),
                value: PayMethod.bank,
                groupValue: state.method,
                onChanged: (v) => cubit.selectMethod(v ?? PayMethod.bank),
              ),
              if (state.method == PayMethod.bank) ...[
                Text('${l.fullName}: ${cubit.bankAccountName()}'),
                Text('A/C: ${cubit.bankAccountNumber()}'),
                Text('IFSC: ${cubit.bankIfsc()}'),
                Text('${l.address}: ${cubit.bankBranch()}'),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () async {
                    final text =
                        '${cubit.bankAccountName()}\n${cubit.bankAccountNumber()}\n${cubit.bankIfsc()}\n${cubit.bankBranch()}';
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.copiedToClipboard)),
                      );
                    }
                  },
                  child: Text(l.copyDetails),
                ),
              ],
              RadioListTile<PayMethod>(
                title: Text(l.upi),
                value: PayMethod.upi,
                groupValue: state.method,
                onChanged: (v) => cubit.selectMethod(v ?? PayMethod.upi),
              ),
              if (state.method == PayMethod.upi)
                ListTile(
                  title: Text(cubit.upiId()),
                  trailing: TextButton(
                    onPressed: () {},
                    child: Text(l.openUpiApp),
                  ),
                ),
              RadioListTile<PayMethod>(
                title: Text(l.debitCard),
                value: PayMethod.card,
                groupValue: state.method,
                onChanged: (v) => cubit.selectMethod(v ?? PayMethod.card),
              ),
              RadioListTile<PayMethod>(
                title: Text(l.cheque),
                value: PayMethod.cheque,
                groupValue: state.method,
                onChanged: (v) => cubit.selectMethod(v ?? PayMethod.cheque),
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    state.error!,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: state.processing ? null : cubit.submit,
                child: state.processing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : Text(l.payButtonLabel),
              ),
            ],
          );
        },
      ),
    );
  }
}
