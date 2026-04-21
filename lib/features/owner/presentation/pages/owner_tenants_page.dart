import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/utils/currency_formatter.dart';
import 'package:rent_system/features/common/widgets/initials_avatar.dart';
import 'package:rent_system/features/common/widgets/status_badge.dart';
import 'package:rent_system/features/owner/domain/entities/owner_models.dart';
import 'package:rent_system/features/owner/presentation/cubit/properties_cubit.dart';
import 'package:rent_system/features/owner/presentation/cubit/tenants_cubit.dart';
import 'package:rent_system/l10n/l10n.dart';

class OwnerTenantsPage extends StatelessWidget {
  const OwnerTenantsPage({super.key});

  BadgeTone _tone(TenantPayStatus s) {
    switch (s) {
      case TenantPayStatus.paid:
        return BadgeTone.success;
      case TenantPayStatus.due:
        return BadgeTone.warning;
      case TenantPayStatus.overdue:
        return BadgeTone.error;
    }
  }

  String _statusLabel(BuildContext context, TenantPayStatus s) {
    final l = context.l10n;
    switch (s) {
      case TenantPayStatus.paid:
        return l.paid;
      case TenantPayStatus.due:
        return l.due;
      case TenantPayStatus.overdue:
        return l.overdue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocListener<TenantsCubit, TenantsState>(
      listenWhen: (p, c) => c.actionError != null && p.actionError != c.actionError,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.actionError!),
            backgroundColor: AppColors.error,
          ),
        );
        context.read<TenantsCubit>().clearError();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.tenants)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddTenantSheet(context),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add Tenant'),
        ),
        body: BlocBuilder<TenantsCubit, TenantsState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final cubit = context.read<TenantsCubit>();
            final items = cubit.visible();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.searchTenants,
                    ),
                    onChanged: cubit.setQuery,
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    children: TenantListFilter.values.map((f) {
                      final selected = state.filter == f;
                      final label = switch (f) {
                        TenantListFilter.all => context.l10n.all,
                        TenantListFilter.paid => context.l10n.paid,
                        TenantListFilter.due => context.l10n.due,
                        TenantListFilter.overdue => context.l10n.overdue,
                      };
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(label),
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
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.group_outlined,
                                    size: 96, color: AppColors.neutral400),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No tenants yet.',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Tap the + button to add a tenant to your property.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) =>
                              _TenantCard(
                                tenant: items[i],
                                statusLabel: _statusLabel(context, items[i].status),
                                tone: _tone(items[i].status),
                                onTap: () => _showTenantSheet(context, items[i]),
                              ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Add Tenant bottom sheet ────────────────────────────────────────────────

  void _showAddTenantSheet(BuildContext context) {
    // Capture references before showModalBottomSheet — the builder runs inside
    // a separate element subtree where the original context may be deactivated.
    final properties = context.read<PropertiesCubit>().state.items;
    final tenantsCubit = context.read<TenantsCubit>();

    if (properties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a property first before adding tenants.'),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: tenantsCubit,
        child: _AddTenantSheet(properties: properties),
      ),
    );
  }

  // ─── Tenant detail / link sheet ─────────────────────────────────────────────

  void _showTenantSheet(BuildContext context, TenantItem t) {
    // Same: capture before the sheet builder runs.
    final tenantsCubit = context.read<TenantsCubit>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: tenantsCubit,
        child: _TenantDetailSheet(tenant: t),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tenant Card
// ─────────────────────────────────────────────────────────────────────────────

class _TenantCard extends StatelessWidget {
  const _TenantCard({
    required this.tenant,
    required this.statusLabel,
    required this.tone,
    required this.onTap,
  });

  final TenantItem tenant;
  final String statusLabel;
  final BadgeTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayout.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppLayout.cardPadding),
          child: Row(
            children: [
              InitialsAvatar(name: tenant.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tenant.name,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${tenant.unit} · ${tenant.propertyName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (tenant.phone.isNotEmpty)
                      Text(tenant.phone,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatInr(tenant.rentAmount),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  StatusBadge(label: statusLabel, tone: tone),
                  const SizedBox(height: AppSpacing.xs),
                  if (tenant.isLinked)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link,
                            size: 12, color: AppColors.secondary),
                        const SizedBox(width: 2),
                        Text(
                          'Linked',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.secondary,
                                  ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_off,
                            size: 12, color: AppColors.neutral400),
                        const SizedBox(width: 2),
                        Text(
                          'Not linked',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.neutral400,
                                  ),
                        ),
                      ],
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
// Add Tenant Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddTenantSheet extends StatefulWidget {
  const _AddTenantSheet({required this.properties});

  final List<PropertyItem> properties;

  @override
  State<_AddTenantSheet> createState() => _AddTenantSheetState();
}

class _AddTenantSheetState extends State<_AddTenantSheet> {
  final _nameFocus = FocusNode();
  final _unitFocus = FocusNode();
  final _rentFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  late String _selectedPropertyId = widget.properties.first.id;
  String _name = '';
  String _unit = '';
  String _rent = '';
  String _phone = '';
  String _email = '';
  DateTime? _moveIn;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameFocus.dispose();
    _unitFocus.dispose();
    _rentFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final rent = double.tryParse(_rent.trim());
    if (_name.trim().isEmpty) {
      setState(() => _error = 'Tenant name is required');
      return;
    }
    if (_unit.trim().isEmpty) {
      setState(() => _error = 'Unit is required');
      return;
    }
    if (rent == null || rent <= 0) {
      setState(() => _error = 'Enter a valid monthly rent');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await context.read<TenantsCubit>().addTenant(
          propertyId: _selectedPropertyId,
          name: _name.trim(),
          unit: _unit.trim(),
          monthlyRent: rent,
          phone: _phone.trim(),
          email: _email.trim(),
          moveInDate: _moveIn,
        );
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenant added successfully')),
        );
      } else {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Tenant',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),

            // Property selector
            Text('Property', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _selectedPropertyId,
              decoration: const InputDecoration(),
              items: widget.properties
                  .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedPropertyId = v);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Name
            Text('Tenant Name *',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Full name'),
              onChanged: (v) => _name = v,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_unitFocus),
            ),
            const SizedBox(height: AppSpacing.md),

            // Unit
            Text('Unit / Room *', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              focusNode: _unitFocus,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'e.g. Unit 101, Room A'),
              onChanged: (v) => _unit = v,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_rentFocus),
            ),
            const SizedBox(height: AppSpacing.md),

            // Monthly rent
            Text('Monthly Rent *',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              focusNode: _rentFocus,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0', prefixText: '₹ '),
              onChanged: (v) => _rent = v,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_phoneFocus),
            ),
            const SizedBox(height: AppSpacing.md),

            // Phone (optional)
            Text('Phone (optional)',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              focusNode: _phoneFocus,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '+977 9800000000'),
              onChanged: (v) => _phone = v,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_emailFocus),
            ),
            const SizedBox(height: AppSpacing.md),

            // Email (optional)
            Text('Email (optional)',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              focusNode: _emailFocus,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(hintText: 'tenant@example.com'),
              onChanged: (v) => _email = v,
              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Move-in date
            Text('Move-in Date (optional)',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _moveIn = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Text(
                  _moveIn == null
                      ? 'Tap to select'
                      : '${_moveIn!.day}/${_moveIn!.month}/${_moveIn!.year}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _moveIn == null
                            ? AppColors.neutral400
                            : AppColors.neutral900,
                      ),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.error),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
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
                        : const Text('Add Tenant'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tenant Detail + Edit + Link Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _TenantDetailSheet extends StatefulWidget {
  const _TenantDetailSheet({required this.tenant});

  final TenantItem tenant;

  @override
  State<_TenantDetailSheet> createState() => _TenantDetailSheetState();
}

class _TenantDetailSheetState extends State<_TenantDetailSheet> {
  // ── Edit state ─────────────────────────────────────────────────────────────
  bool _isEditing = false;

  late final _nameCtrl = TextEditingController(text: widget.tenant.name);
  late final _unitCtrl = TextEditingController(text: widget.tenant.unit);
  late final _rentCtrl =
      TextEditingController(text: widget.tenant.rentAmount.toStringAsFixed(0));
  late final _phoneCtrl = TextEditingController(text: widget.tenant.phone);
  late final _emailCtrl = TextEditingController(text: widget.tenant.email);

  final _nameFocus = FocusNode();
  final _unitFocus = FocusNode();
  final _rentFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _saving = false;
  String? _editError;

  // ── Link state ─────────────────────────────────────────────────────────────
  bool _showLinkForm = false;
  String _renterEmail = '';
  bool _linking = false;
  String? _linkError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _rentCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _nameFocus.dispose();
    _unitFocus.dispose();
    _rentFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // ── Edit helpers ───────────────────────────────────────────────────────────

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editError = null;
    });
    Future.microtask(() => _nameFocus.requestFocus());
  }

  void _cancelEditing() {
    // Reset controllers to original values.
    _nameCtrl.text = widget.tenant.name;
    _unitCtrl.text = widget.tenant.unit;
    _rentCtrl.text = widget.tenant.rentAmount.toStringAsFixed(0);
    _phoneCtrl.text = widget.tenant.phone;
    _emailCtrl.text = widget.tenant.email;
    setState(() {
      _isEditing = false;
      _editError = null;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveEdits() async {
    final name = _nameCtrl.text.trim();
    final unit = _unitCtrl.text.trim();
    final rent = double.tryParse(_rentCtrl.text.trim());

    if (name.isEmpty) {
      setState(() => _editError = 'Tenant name is required');
      return;
    }
    if (unit.isEmpty) {
      setState(() => _editError = 'Unit is required');
      return;
    }
    if (rent == null || rent <= 0) {
      setState(() => _editError = 'Enter a valid monthly rent');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _editError = null;
    });

    final ok = await context.read<TenantsCubit>().updateTenant(
          tenantId: widget.tenant.id,
          name: name,
          unit: unit,
          monthlyRent: rent,
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );

    if (mounted) {
      if (ok) {
        setState(() {
          _isEditing = false;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenant details updated')),
        );
      } else {
        setState(() => _saving = false);
      }
    }
  }

  // ── Link helpers ───────────────────────────────────────────────────────────

  Future<void> _link() async {
    if (_renterEmail.trim().isEmpty) {
      setState(() => _linkError = "Enter the renter's email address");
      return;
    }
    setState(() {
      _linking = true;
      _linkError = null;
    });
    final ok = await context.read<TenantsCubit>().linkRenter(
          tenantId: widget.tenant.id,
          renterEmail: _renterEmail.trim(),
        );
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Renter account linked successfully')),
        );
      } else {
        setState(() {
          _linking = false;
          _linkError =
              context.read<TenantsCubit>().state.actionError ?? 'Failed';
        });
      }
    }
  }

  Future<void> _unlink() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Renter?'),
        content: Text(
          '${widget.tenant.name} will no longer be able to see their '
          'bills and payments on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _linking = true);
    final ok =
        await context.read<TenantsCubit>().unlinkRenter(widget.tenant.id);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Renter unlinked')),
        );
      } else {
        setState(() => _linking = false);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = widget.tenant;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                InitialsAvatar(name: t.name, size: AppLayout.avatarProfile),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                        '${t.unit} · ${t.propertyName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Edit / Done button
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit tenant details',
                    onPressed: _startEditing,
                  )
                else
                  TextButton(
                    onPressed: _saving ? null : _cancelEditing,
                    child: const Text('Cancel'),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── View mode ──────────────────────────────────────────────────
            if (!_isEditing) ...[
              _infoRow(context, 'Unit', t.unit),
              _infoRow(context, 'Monthly Rent', formatInr(t.rentAmount)),
              if (t.phone.isNotEmpty) _infoRow(context, 'Phone', t.phone),
              if (t.email.isNotEmpty) _infoRow(context, 'Email', t.email),
              _infoRow(context, 'Property', t.propertyName),
            ],

            // ── Edit mode ──────────────────────────────────────────────────
            if (_isEditing) ...[
              _editField('Tenant Name *', _nameCtrl, _nameFocus,
                  next: _unitFocus),
              _editField('Unit / Room *', _unitCtrl, _unitFocus,
                  next: _rentFocus),
              _editField('Monthly Rent *', _rentCtrl, _rentFocus,
                  keyboard: TextInputType.number,
                  prefixText: '₹ ',
                  next: _phoneFocus),
              _editField('Phone (optional)', _phoneCtrl, _phoneFocus,
                  keyboard: TextInputType.phone, next: _emailFocus),
              _editField('Email (optional)', _emailCtrl, _emailFocus,
                  keyboard: TextInputType.emailAddress,
                  isDone: true),
              if (_editError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _editError!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _saving ? null : _saveEdits,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ],

            const Divider(height: AppSpacing.xl),

            // ── Link / unlink section ──────────────────────────────────────
            Row(
              children: [
                Icon(
                  t.isLinked ? Icons.link : Icons.link_off,
                  color:
                      t.isLinked ? AppColors.secondary : AppColors.neutral400,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    t.isLinked
                        ? 'Renter account linked'
                        : 'No renter account linked',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: t.isLinked
                              ? AppColors.secondary
                              : AppColors.neutral700,
                        ),
                  ),
                ),
              ],
            ),

            if (t.isLinked) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The renter can see their bills and make payments on their device.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _linking ? null : _unlink,
                icon: const Icon(Icons.link_off, size: 18),
                label: const Text('Unlink Renter Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              if (!_showLinkForm) ...[
                Text(
                  'Link a renter account so the tenant can view bills and '
                  'pay rent from the RentFlow app.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showLinkForm = true),
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Link Renter Account'),
                ),
              ] else ...[
                Text(
                  'Enter the email address the renter used to sign up.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Renter's email",
                    hintText: 'renter@example.com',
                    errorText: _linkError,
                  ),
                  onChanged: (v) => _renterEmail = v,
                  onFieldSubmitted: (_) => _link(),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _linking
                            ? null
                            : () => setState(() {
                                  _showLinkForm = false;
                                  _linkError = null;
                                }),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _linking ? null : _link,
                        child: _linking
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text('Link'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.neutral700)),
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

  Widget _editField(
    String label,
    TextEditingController ctrl,
    FocusNode focus, {
    TextInputType keyboard = TextInputType.text,
    String? prefixText,
    FocusNode? next,
    bool isDone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: ctrl,
            focusNode: focus,
            keyboardType: keyboard,
            textCapitalization: keyboard == TextInputType.text
                ? TextCapitalization.words
                : TextCapitalization.none,
            textInputAction:
                isDone ? TextInputAction.done : TextInputAction.next,
            decoration: InputDecoration(prefixText: prefixText),
            onFieldSubmitted: (_) {
              if (next != null) {
                FocusScope.of(context).requestFocus(next);
              } else {
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ],
      ),
    );
  }
}
