import 'package:flutter/material.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    required this.name,
    this.size = AppLayout.avatarList,
    super.key,
  });

  final String name;
  final double size;

  String _initials() {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      if (s.length >= 2) return s.substring(0, 2).toUpperCase();
      return s.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Avatar for $name',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Text(
          _initials(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontSize: size * 0.35,
              ),
        ),
      ),
    );
  }
}
