import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/features/auth/domain/auth_repository.dart';
import 'package:rent_system/features/common/cubit/locale_cubit.dart';
import 'package:rent_system/l10n/l10n.dart';

class OwnerProfilePage extends StatelessWidget {
  const OwnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = context.read<SessionRepository>().readUser();
    final localeCubit = context.read<LocaleCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l.profile)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ListTile(
            title: Text(user?.displayName ?? 'Owner'),
            subtitle: Text(user?.phoneOrEmail ?? ''),
          ),
          const Divider(),
          BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              final isNe = locale.languageCode == 'ne';
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(l.changeLanguage),
                subtitle: Text(isNe ? l.languageNepali : l.languageEnglish),
                trailing: Switch(
                  value: isNe,
                  onChanged: (_) => localeCubit.toggle(),
                ),
                onTap: localeCubit.toggle,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l.stayUpdated),
            subtitle: Text(l.enableNotificationsSubtitle),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l.stayUpdated),
                  content: Text(l.rentflowNotifyDesc),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.notNow),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.grant),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l.signOut),
            onTap: () async {
              await context.read<AuthRepository>().signOut();
              if (context.mounted) {
                context.goNamed(RouteNames.landing);
              }
            },
          ),
        ],
      ),
    );
  }
}
