import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/features/auth/domain/user_role.dart';
import 'package:rent_system/features/auth/presentation/cubit/login_cubit.dart';
import 'package:rent_system/l10n/l10n.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocListener<LoginCubit, LoginState>(
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
            onPressed: () =>
                context.canPop() ? context.pop() : context.goNamed(RouteNames.landing),
          ),
          title: Text(l.signIn),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              // ── Email / Phone ──────────────────────────────────────────
              Text(l.phoneOrEmail, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              BlocBuilder<LoginCubit, LoginState>(
                buildWhen: (p, c) => p.identifierError != c.identifierError,
                builder: (context, state) => TextFormField(
                  focusNode: _identifierFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: l.phoneOrEmailHint,
                    errorText: state.identifierError,
                  ),
                  onChanged: context.read<LoginCubit>().identifierChanged,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_passwordFocus),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Password ───────────────────────────────────────────────
              Text(l.password, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              BlocBuilder<LoginCubit, LoginState>(
                buildWhen: (p, c) =>
                    p.obscurePassword != c.obscurePassword ||
                    p.passwordError != c.passwordError,
                builder: (context, state) {
                  final cubit = context.read<LoginCubit>();
                  return TextFormField(
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.done,
                    obscureText: state.obscurePassword,
                    decoration: InputDecoration(
                      hintText: l.passwordHint,
                      errorText: state.passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          state.obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: AppLayout.iconPrimary,
                        ),
                        tooltip: state.obscurePassword
                            ? l.showPassword
                            : l.hidePassword,
                        onPressed: cubit.toggleObscure,
                      ),
                    ),
                    onChanged: cubit.passwordChanged,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                      cubit.submit();
                    },
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xs),
              Text(l.passwordHintNote, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xl),

              // ── Form-level error ───────────────────────────────────────
              BlocBuilder<LoginCubit, LoginState>(
                buildWhen: (p, c) => p.formError != c.formError,
                builder: (context, state) {
                  if (state.formError == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
              BlocBuilder<LoginCubit, LoginState>(
                buildWhen: (p, c) => p.submitting != c.submitting,
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state.submitting
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            context.read<LoginCubit>().submit();
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
                        : Text(l.signIn),
                  );
                },
              ),

              // ── Forgot password ────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    l.forgotPassword,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),

              // ── Sign-up link ───────────────────────────────────────────
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l.noAccount, style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: () {
                      final role = context.read<LoginCubit>().role;
                      context.pushNamed(RouteNames.signup, extra: role);
                    },
                    child: Text(l.signUp),
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
