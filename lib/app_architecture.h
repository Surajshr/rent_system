/*
  RentFlow — architecture contract (reference for lib/ layout)

  lib/
  ├── app_architecture.h   (this file)
  ├── core/
  │   ├── constants/       (colors, spacing, layout, shadows)
  │   ├── errors/          (AppException, AppFailure)
  │   ├── extensions/
  │   ├── session/         (Hive-backed session)
  │   └── utils/
  ├── features/
  │   ├── auth/
  │   ├── owner/
  │   ├── renter/
  │   ├── notifications/
  │   └── common/          (constants/app_images.dart, shared widgets)
  ├── config/
  │   ├── routes/          (GoRouter, named routes)
  │   └── theme/           (RentflowTheme, design tokens)
  ├── l10n/
  ├── app/
  └── main*.dart

  Principles: presentation uses BLoC/Cubit; routing via go_router named routes;
  persistence: Hive (session/cache), Supabase/Firebase when configured.
*/
