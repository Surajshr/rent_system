import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rent_system/config/routes/route_names.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/features/auth/data/supabase_auth_repository.dart';
import 'package:rent_system/features/auth/domain/auth_repository.dart';
import 'package:rent_system/features/auth/domain/user_role.dart';
import 'package:rent_system/features/auth/presentation/cubit/login_cubit.dart';
import 'package:rent_system/features/auth/presentation/cubit/signup_cubit.dart';
import 'package:rent_system/features/auth/presentation/pages/landing_page.dart';
import 'package:rent_system/features/auth/presentation/pages/login_page.dart';
import 'package:rent_system/features/auth/presentation/pages/signup_page.dart';
import 'package:rent_system/features/owner/presentation/bloc/owner_dashboard_bloc.dart';
import 'package:rent_system/features/owner/presentation/cubit/bill_generation_cubit.dart';
import 'package:rent_system/features/owner/presentation/cubit/payment_tracking_cubit.dart';
import 'package:rent_system/features/owner/presentation/cubit/properties_cubit.dart';
import 'package:rent_system/features/owner/presentation/cubit/tenants_cubit.dart';
import 'package:rent_system/features/owner/presentation/pages/bill_generation_page.dart';
import 'package:rent_system/features/owner/presentation/pages/owner_dashboard_page.dart';
import 'package:rent_system/features/owner/presentation/pages/owner_payments_page.dart';
import 'package:rent_system/features/owner/presentation/pages/owner_profile_page.dart';
import 'package:rent_system/features/owner/presentation/pages/owner_properties_page.dart';
import 'package:rent_system/features/owner/presentation/pages/owner_shell_page.dart';
import 'package:rent_system/features/owner/presentation/pages/owner_tenants_page.dart';
import 'package:rent_system/features/renter/presentation/bloc/renter_dashboard_bloc.dart';
import 'package:rent_system/features/renter/presentation/cubit/payment_cubit.dart';
import 'package:rent_system/features/renter/presentation/cubit/payment_history_cubit.dart';
import 'package:rent_system/features/renter/presentation/cubit/renter_bills_cubit.dart';
import 'package:rent_system/features/renter/presentation/pages/renter_bill_detail_page.dart';
import 'package:rent_system/features/renter/presentation/pages/renter_bills_page.dart';
import 'package:rent_system/features/renter/presentation/pages/renter_dashboard_page.dart';
import 'package:rent_system/features/renter/presentation/pages/renter_pay_rent_page.dart';
import 'package:rent_system/features/renter/presentation/pages/renter_payment_history_page.dart';
import 'package:rent_system/features/renter/presentation/pages/renter_profile_page.dart';
import 'package:rent_system/features/renter/presentation/pages/renter_shell_page.dart';
import 'package:rent_system/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:rent_system/features/splash/presentation/pages/splash_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter({required RentflowSupabaseService db}) {
  final session = SessionRepository(Hive.box<String>('rentflow_session'));
  final auth = SupabaseAuthRepository(session: session, db: db);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => RepositoryProvider.value(
          value: session,
          child: BlocProvider(
            create: (_) {
              final cubit = SplashCubit(session, db);
              unawaited(cubit.start());
              return cubit;
            },
            child: const SplashPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/landing',
        name: RouteNames.landing,
        builder: (_, __) => const LandingPage(),
      ),
      GoRoute(
        path: '/auth/login',
        name: RouteNames.login,
        builder: (context, state) {
          final role = state.extra is UserRole ? state.extra! as UserRole : UserRole.owner;
          return BlocProvider(
            create: (_) => LoginCubit(auth, role),
            child: const LoginPage(),
          );
        },
      ),
      GoRoute(
        path: '/auth/signup',
        name: RouteNames.signup,
        builder: (context, state) {
          final role = state.extra is UserRole ? state.extra! as UserRole : UserRole.owner;
          return BlocProvider(
            create: (_) => SignupCubit(auth, role),
            child: const SignupPage(),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RepositoryProvider.value(
            value: session,
            child: MultiRepositoryProvider(
              providers: [
                RepositoryProvider<AuthRepository>.value(value: auth),
              ],
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => OwnerDashboardBloc(session: session, db: db)
                      ..add(const OwnerDashboardStarted()),
                  ),
                  BlocProvider(
                    create: (_) => PropertiesCubit(session: session, db: db),
                  ),
                  BlocProvider(
                    create: (_) => TenantsCubit(session: session, db: db),
                  ),
                  BlocProvider(
                    create: (_) => PaymentTrackingCubit(session: session, db: db),
                  ),
                ],
                child: OwnerShellPage(navigationShell: navigationShell),
              ),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/dashboard',
                name: RouteNames.ownerDashboard,
                builder: (_, __) => const OwnerDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/properties',
                name: RouteNames.ownerProperties,
                builder: (_, __) => const OwnerPropertiesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/tenants',
                name: RouteNames.ownerTenants,
                builder: (_, __) => const OwnerTenantsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/payments',
                name: RouteNames.ownerPayments,
                builder: (_, __) => const OwnerPaymentsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/profile',
                name: RouteNames.ownerProfile,
                builder: (_, __) => const OwnerProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/owner/bill-generation',
        name: RouteNames.ownerBillGeneration,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => RepositoryProvider.value(
          value: session,
          child: BlocProvider(
            create: (_) => BillGenerationCubit(session: session, db: db),
            child: const BillGenerationPage(),
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RepositoryProvider.value(
            value: session,
            child: MultiRepositoryProvider(
              providers: [
                RepositoryProvider<AuthRepository>.value(value: auth),
              ],
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => RenterDashboardBloc(session: session, db: db)
                      ..add(const RenterDashboardStarted()),
                  ),
                  BlocProvider(
                    create: (_) => RenterBillsCubit(session: session, db: db),
                  ),
                  BlocProvider(
                    create: (_) => PaymentHistoryCubit(session: session, db: db),
                  ),
                ],
                child: RenterShellPage(navigationShell: navigationShell),
              ),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/renter/dashboard',
                name: RouteNames.renterDashboard,
                builder: (_, __) => const RenterDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/renter/bills',
                name: RouteNames.renterBills,
                builder: (_, __) => const RenterBillsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/renter/payments',
                name: RouteNames.renterPayments,
                builder: (_, __) => const RenterPaymentHistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/renter/profile',
                name: RouteNames.renterProfile,
                builder: (_, __) => const RenterProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/renter/bill/:id',
        name: RouteNames.renterBillDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return RepositoryProvider.value(
            value: session,
            child: RenterBillDetailPage(billId: id, db: db),
          );
        },
      ),
      GoRoute(
        path: '/renter/pay',
        name: RouteNames.renterPayRent,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final billId = state.extra is String ? state.extra! as String : null;
          return RepositoryProvider.value(
            value: session,
            child: BlocProvider(
              create: (_) => PaymentCubit(
                db: db,
                session: session,
                initialBillId: billId,
              ),
              child: const RenterPayRentPage(),
            ),
          );
        },
      ),
    ],
  );
}
