import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  await Hive.initFlutter();
  await Hive.openBox<String>('rentflow_session');
  await Hive.openBox<String>('rentflow_cache');

  // Override via --dart-define=SUPABASE_URL / SUPABASE_ANON_KEY.
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zhgsapsueoepabhfxsuw.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    // Replace with your real anon key from:
    // Supabase Dashboard → Project Settings → API → anon public
    // It starts with eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpoZ3NhcHN1ZW9lcGFiaGZ4c3V3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1MTQ0MDEsImV4cCI6MjA5MjA5MDQwMX0.XZrz3OPBIkt_9g5xDDdRfWgxxrW8Od46wBoEFLJXmP0',
  );
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Firebase: run `dart run flutterfire configure` then call
  // `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`
  // from a generated `firebase_options.dart` (Phase 4).

  runApp(await builder());
}
