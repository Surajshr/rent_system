import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_spacing.dart';

/// Material 3 theme using RentFlow design tokens.
///
/// Fonts are bundled under [assets/fonts] (see pubspec). Sizes use
/// ScreenUtil (`.sp`, `.r`, `.w`, `.h`); use only under `ScreenUtilInit`.
class RentflowTheme {
  static const String _poppins = 'Poppins';
  static const String _inter = 'Inter';

  static TextTheme _textTheme() {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _poppins,
        fontSize: 32.sp,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        color: AppColors.neutral900,
      ),
      displayMedium: TextStyle(
        fontFamily: _poppins,
        fontSize: 28.sp,
        fontWeight: FontWeight.w600,
        height: 36 / 28,
        color: AppColors.neutral900,
      ),
      headlineSmall: TextStyle(
        fontFamily: _poppins,
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: AppColors.neutral900,
      ),
      bodyLarge: TextStyle(
        fontFamily: _inter,
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.neutral900,
      ),
      bodyMedium: TextStyle(
        fontFamily: _inter,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.neutral700,
      ),
      bodySmall: TextStyle(
        fontFamily: _inter,
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 18 / 12,
        color: AppColors.neutral700,
      ),
      labelLarge: TextStyle(
        fontFamily: _poppins,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.2,
        color: AppColors.neutral900,
      ),
      labelSmall: TextStyle(
        fontFamily: _inter,
        fontSize: 10.sp,
        fontWeight: FontWeight.w400,
        height: 14 / 10,
        color: AppColors.neutral700,
      ),
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.white,
    );

    final textTheme = _textTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: _inter,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.neutral900,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusCard.r),
          side: const BorderSide(color: AppColors.neutral200),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral100,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg.w,
          vertical: AppSpacing.md.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusInput.r),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusInput.r),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusInput.r),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: AppLayout.borderFocus.w,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusInput.r),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.neutral400),
        labelStyle: textTheme.bodyMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(AppLayout.buttonHeight.h),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppLayout.radiusButton.r),
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: AppColors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(AppLayout.buttonHeight.h),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppLayout.radiusButton.r),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.bodyMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
