import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/utils/auth_validators.dart';
import 'package:rent_system/features/auth/domain/user_role.dart';
import 'package:rent_system/features/auth/presentation/cubit/signup_cubit.dart';
import 'package:rent_system/l10n/l10n.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Color _strengthColor(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.fair:
        return AppColors.warning;
      case PasswordStrength.strong:
        return AppColors.secondary;
    }
  }

  String _strengthLabel(BuildContext context, PasswordStrength s) {
    final l = context.l10n;
    switch (s) {
      case PasswordStrength.weak:
        return l.weak;
      case PasswordStrength.fair:
        return l.fair;
      case PasswordStrength.strong:
        return l.strong;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocListener<SignupCubit, SignupState>(
      listenWhen: (p, c) => p.success != c.success && c.success,
      listener: (context, state) {
        if (state.role == UserRole.owner) {
          context.goNamed(RouteNames.ownerDashboard);
        } else {
          context.goNamed(RouteNames.renterDashboard);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(l.createAccount),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                // ── Full Name ──────────────────────────────────────────────
                _LabeledField(
                  label: l.fullName,
                  child: BlocBuilder<SignupCubit, SignupState>(
                    buildWhen: (p, c) => p.fullNameError != c.fullNameError,
                    builder: (context, state) => TextFormField(
                      focusNode: _nameFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: l.fullNameHint,
                        errorText: state.fullNameError,
                      ),
                      onChanged: context.read<SignupCubit>().fullNameChanged,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_emailFocus),
                    ),
                  ),
                ),

                // ── Email (required) ───────────────────────────────────────
                _LabeledField(
                  label: l.email,
                  child: BlocBuilder<SignupCubit, SignupState>(
                    buildWhen: (p, c) => p.emailError != c.emailError,
                    builder: (context, state) => TextFormField(
                      focusNode: _emailFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: l.emailHint,
                        errorText: state.emailError,
                      ),
                      onChanged: context.read<SignupCubit>().emailChanged,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_phoneFocus),
                    ),
                  ),
                ),

                // ── Phone (optional) ───────────────────────────────────────
                _LabeledField(
                  label: '${l.phone} (${l.optionalField})',
                  child: BlocBuilder<SignupCubit, SignupState>(
                    buildWhen: (p, c) => p.phoneError != c.phoneError,
                    builder: (context, state) => TextFormField(
                      focusNode: _phoneFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: l.phoneHint,
                        errorText: state.phoneError,
                      ),
                      onChanged: context.read<SignupCubit>().phoneChanged,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_passFocus),
                    ),
                  ),
                ),

                // ── Password ───────────────────────────────────────────────
                _LabeledField(
                  label: l.password,
                  child: BlocBuilder<SignupCubit, SignupState>(
                    buildWhen: (p, c) =>
                        p.password != c.password ||
                        p.obscure != c.obscure ||
                        p.passwordError != c.passwordError,
                    builder: (context, state) {
                      final cubit = context.read<SignupCubit>();
                      final strength = cubit.strength();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            focusNode: _passFocus,
                            textInputAction: TextInputAction.next,
                            obscureText: state.obscure,
                            decoration: InputDecoration(
                              hintText: l.minEightChars,
                              errorText: state.passwordError,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  state.obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: AppLayout.iconPrimary,
                                ),
                                tooltip: state.obscure
                                    ? l.showPassword
                                    : l.hidePassword,
                                onPressed: cubit.toggleObscure,
                              ),
                            ),
                            onChanged: cubit.passwordChanged,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context)
                                    .requestFocus(_confirmFocus),
                          ),
                          if (state.password.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: _strengthColor(strength)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppLayout.radiusInput,
                                ),
                              ),
                              child: Text(
                                _strengthLabel(context, strength),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: _strengthColor(strength)),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                // ── Confirm Password ───────────────────────────────────────
                _LabeledField(
                  label: l.confirmPassword,
                  child: BlocBuilder<SignupCubit, SignupState>(
                    buildWhen: (p, c) =>
                        p.obscureConfirm != c.obscureConfirm ||
                        p.confirmPasswordError != c.confirmPasswordError,
                    builder: (context, state) {
                      final cubit = context.read<SignupCubit>();
                      return TextFormField(
                        focusNode: _confirmFocus,
                        textInputAction: TextInputAction.done,
                        obscureText: state.obscureConfirm,
                        decoration: InputDecoration(
                          errorText: state.confirmPasswordError,
                          suffixIcon: IconButton(
                            icon: Icon(
                              state.obscureConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: AppLayout.iconPrimary,
                            ),
                            tooltip: state.obscureConfirm
                                ? l.showPassword
                                : l.hidePassword,
                            onPressed: cubit.toggleObscureConfirm,
                          ),
                        ),
                        onChanged: cubit.confirmChanged,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).unfocus(),
                      );
                    },
                  ),
                ),

                // ── Terms ──────────────────────────────────────────────────
                const SizedBox(height: AppSpacing.sm),
                BlocBuilder<SignupCubit, SignupState>(
                  buildWhen: (p, c) =>
                      p.agreedToTerms != c.agreedToTerms ||
                      p.termsError != c.termsError,
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: state.agreedToTerms,
                          onChanged: (v) => context
                              .read<SignupCubit>()
                              .termsChanged(agreed: v ?? false),
                          title: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${l.iAgreeTo} ',
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(l.termsAndConditions),
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (state.termsError != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: AppSpacing.xs),
                            child: Text(
                              state.termsError!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                // ── Form-level error ───────────────────────────────────────
                BlocBuilder<SignupCubit, SignupState>(
                  buildWhen: (p, c) => p.formError != c.formError,
                  builder: (context, state) {
                    if (state.formError == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppSpacing.sm, bottom: AppSpacing.md),
                      child: Text(
                        state.formError!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.error),
                      ),
                    );
                  },
                ),

                // ── Submit ─────────────────────────────────────────────────
                BlocBuilder<SignupCubit, SignupState>(
                  buildWhen: (p, c) => p.submitting != c.submitting,
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.submitting
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              context.read<SignupCubit>().submit();
                            },
                      child: state.submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(l.createAccount),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(l.alreadyHaveAccount),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin wrapper that renders a label above any child widget.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
