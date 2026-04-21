import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/features/notifications/presentation/cubit/notification_cubit.dart';

class NotificationBannerHost extends StatefulWidget {
  const NotificationBannerHost({required this.child, super.key});

  final Widget child;

  @override
  State<NotificationBannerHost> createState() => _NotificationBannerHostState();
}

class _NotificationBannerHostState extends State<NotificationBannerHost> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationCubit, InAppNotification?>(
      listenWhen: (p, c) => p != c && c != null,
      listener: (context, notification) {
        _timer?.cancel();
        _timer = Timer(const Duration(seconds: 5), () {
          if (mounted) context.read<NotificationCubit>().dismiss();
        });
      },
      child: Stack(
        children: [
          widget.child,
          BlocBuilder<NotificationCubit, InAppNotification?>(
            builder: (context, notification) {
              if (notification == null) return const SizedBox.shrink();
              final top = MediaQuery.paddingOf(context).top + AppSpacing.sm;
              return Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: top,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: notification.backgroundColor(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications, color: Colors.white, size: 16),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                notification.body,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          onPressed: () => context.read<NotificationCubit>().dismiss(),
                          tooltip: 'Dismiss',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
