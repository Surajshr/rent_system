import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/features/auth/domain/user_role.dart';
import 'package:rent_system/features/common/constants/app_images.dart';
import 'package:rent_system/features/common/cubit/locale_cubit.dart';
import 'package:rent_system/l10n/l10n.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    AppImages.appIcon,
                    width: 48,
                    height: 48,
                    semanticLabel: 'RentFlow',
                  ),
                  _LanguageToggle(),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l.welcomeTitle, style: text.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.welcomeSubtitle,
                style: text.bodyLarge?.copyWith(color: AppColors.neutral700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 200,
                    color: AppColors.primary.withValues(alpha: 0.35),
                    semanticLabel: 'Property illustration',
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pushNamed(
                    RouteNames.login,
                    extra: UserRole.owner,
                  ),
                  child: Text(l.imAnOwner),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pushNamed(
                    RouteNames.login,
                    extra: UserRole.renter,
                  ),
                  child: Text(l.imARenter),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      l.privacy,
                      style: text.labelSmall?.copyWith(color: AppColors.neutral700),
                    ),
                  ),
                  Text(' · ', style: text.labelSmall),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      l.terms,
                      style: text.labelSmall?.copyWith(color: AppColors.neutral700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.buttonHeight / 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LocaleCubit>();
    final isNe = context.watch<LocaleCubit>().isNepali;
    return GestureDetector(
      onTap: cubit.toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16, color: AppColors.neutral700),
            const SizedBox(width: 4),
            Text(
              isNe ? 'EN' : 'ने',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
