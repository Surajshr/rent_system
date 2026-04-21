import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/features/common/constants/app_images.dart';
import 'package:rent_system/features/splash/presentation/cubit/splash_cubit.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listenWhen: (p, c) => p.target != c.target && c.target != SplashTarget.none,
      listener: (context, state) {
        switch (state.target) {
          case SplashTarget.landing:
            context.goNamed(RouteNames.landing);
          case SplashTarget.ownerHome:
            context.goNamed(RouteNames.ownerDashboard);
          case SplashTarget.renterHome:
            context.goNamed(RouteNames.renterDashboard);
          case SplashTarget.none:
            break;
        }
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC2563EB),
                AppColors.white,
              ],
              stops: [0, 0.35],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppImages.appIcon,
                  width: 128,
                  height: 128,
                  semanticLabel: 'RentFlow app icon',
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'RentFlow',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: AppColors.primary,
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
