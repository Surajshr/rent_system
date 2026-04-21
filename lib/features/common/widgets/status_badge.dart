import 'package:flutter/material.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_spacing.dart';

enum BadgeTone { success, warning, error, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.tone,
    super.key,
  });

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.success => (AppColors.secondary, AppColors.white),
      BadgeTone.warning => (AppColors.warning, AppColors.neutral900),
      BadgeTone.error => (AppColors.error, AppColors.white),
      BadgeTone.neutral => (AppColors.neutral100, AppColors.neutral700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: fg,
              fontSize: 12,
            ),
      ),
    );
  }
}
