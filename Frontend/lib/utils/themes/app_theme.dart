import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/local/shared_preference/preference_keys.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    try {
      final isDark = getIt<Preference>().getBool(PreferenceKeys.IS_DARK_THEME);
      if (isDark == true) {
        return ThemeMode.dark;
      } else if (isDark == false) {
        return ThemeMode.light;
      }
    } catch (_) {}
    return ThemeMode.light;
  }

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setTheme(next);
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    try {
      getIt<Preference>().setBool(
        PreferenceKeys.IS_DARK_THEME,
        mode == ThemeMode.dark,
      );
    } catch (_) {}
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class AppTheme {
  static ThemeData get lightTheme {
    const palette = DaymarkPalette.light;
    final interFont = GoogleFonts.inter().fontFamily;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: interFont,
      scaffoldBackgroundColor: palette.background,
      cardColor: palette.surface,
      dividerColor: palette.line,
      colorScheme: ColorScheme.light(
        surface: palette.surface,
        primary: palette.accent,
        onPrimary: Colors.white,
        onSurface: palette.ink,
        outline: palette.line,
        error: palette.danger,
      ),
      textTheme: const TextTheme().apply(
        fontFamily: interFont,
        bodyColor: palette.ink,
        displayColor: palette.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 0.h,
        iconTheme: IconThemeData(color: palette.ink),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: palette.line),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: palette.ink,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: palette.muted,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const palette = DaymarkPalette.dark;
    final interFont = GoogleFonts.inter().fontFamily;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: interFont,
      scaffoldBackgroundColor: palette.background,
      cardColor: palette.surface,
      dividerColor: palette.line,
      colorScheme: ColorScheme.dark(
        surface: palette.surface,
        primary: palette.accent,
        onPrimary: palette.background,
        onSurface: palette.ink,
        outline: palette.line,
        error: palette.danger,
      ),
      textTheme: const TextTheme().apply(
        fontFamily: interFont,
        bodyColor: palette.ink,
        displayColor: palette.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 0.h,
        iconTheme: IconThemeData(color: palette.ink),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: palette.line),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: palette.ink,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: palette.muted,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  /// Backward compatible default theme method
  static ThemeData defaultAppTheme() => lightTheme;
}
