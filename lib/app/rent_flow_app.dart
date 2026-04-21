import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rent_system/config/routes/app_router.dart';
import 'package:rent_system/config/screen/design_size.dart';
import 'package:rent_system/config/theme/rentflow_theme.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/features/common/cubit/connectivity_cubit.dart';
import 'package:rent_system/features/common/cubit/locale_cubit.dart';
import 'package:rent_system/features/common/widgets/connectivity_banner.dart';
import 'package:rent_system/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:rent_system/features/notifications/presentation/widgets/notification_banner_host.dart';
import 'package:rent_system/l10n/l10n.dart';

class RentFlowApp extends StatefulWidget {
  const RentFlowApp({super.key});

  @override
  State<RentFlowApp> createState() => _RentFlowAppState();
}

class _RentFlowAppState extends State<RentFlowApp> {
  late final RentflowSupabaseService _db = RentflowSupabaseService();
  late final GoRouter _router = createAppRouter(db: _db);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NotificationCubit()),
        BlocProvider(create: (_) => ConnectivityCubit()),
        BlocProvider(
          create: (_) => LocaleCubit(Hive.box<String>('rentflow_session')),
        ),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return ScreenUtilInit(
            designSize: DesignSize.mobile,
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, _) {
              return MaterialApp.router(
                theme: RentflowTheme.light(),
                routerConfig: _router,
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) {
                  final content = child ?? const SizedBox.shrink();
                  return NotificationBannerHost(
                    child: ConnectivityBanner(child: content),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
