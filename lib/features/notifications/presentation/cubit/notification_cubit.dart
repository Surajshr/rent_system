import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum NotificationTone { success, error, info }

class InAppNotification extends Equatable {
  const InAppNotification({
    required this.title,
    required this.body,
    required this.tone,
  });

  final String title;
  final String body;
  final NotificationTone tone;

  Color backgroundColor() {
    switch (tone) {
      case NotificationTone.success:
        return const Color(0xFF10B981);
      case NotificationTone.error:
        return const Color(0xFFEF4444);
      case NotificationTone.info:
        return const Color(0xFF2563EB);
    }
  }

  @override
  List<Object?> get props => [title, body, tone];
}

/// In-app banner queue; wire FCM in Phase 4.
class NotificationCubit extends Cubit<InAppNotification?> {
  NotificationCubit() : super(null);

  void dismiss() => emit(null);

  void showDemoRentDue() {
    emit(
      const InAppNotification(
        title: 'Rent Payment Due',
        body: '₹5,000 due by Mar 31. Only 5 days left.',
        tone: NotificationTone.info,
      ),
    );
  }
}
