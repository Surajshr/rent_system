import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/features/auth/domain/auth_repository.dart';

class RenterProfilePage extends StatelessWidget {
  const RenterProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionRepository>().readUser();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ListTile(
            title: Text(user?.displayName ?? 'Renter'),
            subtitle: Text(user?.phoneOrEmail ?? ''),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
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
