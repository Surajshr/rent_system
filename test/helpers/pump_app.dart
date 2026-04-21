import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_system/config/screen/design_size.dart';
import 'package:rent_system/l10n/l10n.dart';

extension PumpApp on WidgetTester {
  /// Pumps [widget] with the same [ScreenUtilInit] + l10n as production.
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      ScreenUtilInit(
        designSize: DesignSize.mobile,
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) {
          return MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: widget,
          );
        },
      ),
    );
  }
}
