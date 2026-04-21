import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/utils/currency_formatter.dart';
import 'package:rent_system/features/owner/domain/entities/owner_models.dart';
import 'package:rent_system/features/owner/presentation/cubit/properties_cubit.dart';
import 'package:rent_system/l10n/l10n.dart';

class OwnerPropertiesPage extends StatelessWidget {
  const OwnerPropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.myProperties),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l.addProperty,
            onPressed: () => _showPropertySheet(context),
          ),
        ],
      ),
      body: BlocBuilder<PropertiesCubit, PropertiesState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final cubit = context.read<PropertiesCubit>();
          final items = cubit.filteredSorted();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        children: PropertyFilter.values.map((f) {
                          final selected = state.filter == f;
                          final filterLabel = switch (f) {
                            PropertyFilter.all => context.l10n.all,
                            PropertyFilter.occupied => context.l10n.occupied,
                            PropertyFilter.vacant => context.l10n.vacant,
                          };
                          return ChoiceChip(
                            label: Text(filterLabel),
                            selected: selected,
                            onSelected: (_) => cubit.setFilter(f),
                          );
                        }).toList(),
                      ),
                    ),
                    DropdownButton<PropertySort>(
                      value: state.sort,
                      items: PropertySort.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) cubit.setSort(v);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? _empty(context)
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) {
                          final p = items[i];
                          return _PropertyCard(property: p);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apartment, size: 96, color: AppColors.neutral400),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.noPropertiesYet,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => _showPropertySheet(context),
              child: Text(context.l10n.addFirstProperty),
            ),
          ],
        ),
      ),
    );
  }

  void _showPropertySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<PropertiesCubit>(),
        child: const _AddPropertySheet(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Property sheet — proper StatefulWidget with Form + FocusNodes
// ─────────────────────────────────────────────────────────────────────────────

class _AddPropertySheet extends StatefulWidget {
  const _AddPropertySheet();

  @override
  State<_AddPropertySheet> createState() => _AddPropertySheetState();
}

class _AddPropertySheetState extends State<_AddPropertySheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController(text: '1');
  final _rentCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _locFocus = FocusNode();
  final _unitsFocus = FocusNode();
  final _rentFocus = FocusNode();
  final _addrFocus = FocusNode();

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    _unitsCtrl.dispose();
    _rentCtrl.dispose();
    _addrCtrl.dispose();
    _nameFocus.dispose();
    _locFocus.dispose();
    _unitsFocus.dispose();
    _rentFocus.dispose();
    _addrFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final units = int.tryParse(_unitsCtrl.text.trim()) ?? 1;
    final rent = double.tryParse(_rentCtrl.text.trim()) ?? 0;

    await context.read<PropertiesCubit>().addProperty(
      name: name,
      location: _locCtrl.text.trim(),
      unitsTotal: units < 1 ? 1 : units,
      baseRent: rent,
      address: _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.propertySaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.addProperty,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Property Name
              TextFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: '${l.propertyName} *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.propertyNameRequired
                    : null,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_locFocus),
              ),
              const SizedBox(height: AppSpacing.md),

              // Location
              TextFormField(
                controller: _locCtrl,
                focusNode: _locFocus,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.location),
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_unitsFocus),
              ),
              const SizedBox(height: AppSpacing.md),

              // Unit Count
              TextFormField(
                controller: _unitsCtrl,
                focusNode: _unitsFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.unitCount),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Enter a valid unit count';
                  return null;
                },
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_rentFocus),
              ),
              const SizedBox(height: AppSpacing.md),

              // Base Rent
              TextFormField(
                controller: _rentCtrl,
                focusNode: _rentFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.baseRent,
                  prefixText: '₹ ',
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter a valid rent amount';
                  return null;
                },
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_addrFocus),
              ),
              const SizedBox(height: AppSpacing.md),

              // Address
              TextFormField(
                controller: _addrCtrl,
                focusNode: _addrFocus,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '${l.address} (optional)',
                ),
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(l.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(l.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final PropertyItem property;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppLayout.radiusButton),
              child: Container(
                width: 64,
                height: 64,
                color: AppColors.neutral100,
                child: const Icon(
                  Icons.apartment,
                  size: 36,
                  color: AppColors.neutral400,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    property.location,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tenants: ${property.tenantsOccupied}/${property.unitsTotal}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    formatInr(property.baseRent),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$v (demo)')));
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit Property')),
                PopupMenuItem(value: 'tenants', child: Text('View Tenants')),
                PopupMenuItem(value: 'delete', child: Text('Delete Property')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
