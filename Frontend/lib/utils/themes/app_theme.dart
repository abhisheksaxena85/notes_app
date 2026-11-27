import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/local/shared_preference/preference_keys.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

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
  static ThemeData get lightTheme => _build(DaymarkPalette.light);

  static ThemeData get darkTheme => _build(DaymarkPalette.dark);

  /// Backward compatible default theme method
  static ThemeData defaultAppTheme() => lightTheme;

  static ThemeData _build(DaymarkPalette p) {
    final interFont = GoogleFonts.inter().fontFamily;
    final colorScheme = ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      primaryContainer: p.accentSoft,
      onPrimaryContainer: p.accent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer: p.accent,
      tertiary: p.success,
      onTertiary: p.onAccent,
      error: p.danger,
      onError: p.onAccent,
      errorContainer: p.dangerSoft,
      onErrorContainer: p.danger,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.muted,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surface,
      surfaceContainerHighest: p.surfaceMuted,
      outline: p.chipBorder,
      outlineVariant: p.line,
      shadow: Colors.black,
      scrim: p.scrim,
      inverseSurface: p.ink,
      onInverseSurface: p.background,
      inversePrimary: p.accentSoft,
      surfaceTint: Colors.transparent,
    );

    final textTheme = TextTheme(
      headlineMedium: DaymarkText.display,
      headlineSmall: DaymarkText.title,
      titleLarge: DaymarkText.sheetTitle,
      titleMedium: DaymarkText.section,
      titleSmall: DaymarkText.bodyStrong,
      bodyLarge: DaymarkText.body,
      bodyMedium: DaymarkText.preview,
      bodySmall: DaymarkText.meta,
      labelLarge: DaymarkText.button,
      labelMedium: DaymarkText.label,
      labelSmall: DaymarkText.overline,
    ).apply(fontFamily: interFont, bodyColor: p.ink, displayColor: p.ink);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    final chipShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: BorderSide(color: p.chipBorder),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      fontFamily: interFont,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      cardColor: p.surface,
      dividerColor: p.divider,
      disabledColor: p.disabled,
      hintColor: p.muted,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: p.ink, size: 20),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.25),
        selectionHandleColor: p.accent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 0,
        iconTheme: IconThemeData(color: p.ink),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.background,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: DaymarkText.custom(15, FontWeight.w400).copyWith(color: p.muted),
        labelStyle: DaymarkText.label.copyWith(color: p.muted),
        floatingLabelStyle: DaymarkText.label.copyWith(color: p.accent),
        errorStyle: DaymarkText.meta.copyWith(color: p.danger),
        prefixIconColor: p.muted,
        suffixIconColor: p.muted,
        border: border(p.line),
        enabledBorder: border(p.line),
        disabledBorder: border(p.line),
        focusedBorder: border(p.accent, 1.5),
        errorBorder: border(p.danger),
        focusedErrorBorder: border(p.danger, 1.5),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: p.accentSoft,
        disabledColor: p.surfaceMuted,
        checkmarkColor: p.accent,
        side: BorderSide(color: p.chipBorder),
        shape: chipShape,
        labelStyle: DaymarkText.chip().copyWith(color: p.inkSecondary),
        secondaryLabelStyle: DaymarkText.chip(selected: true).copyWith(color: p.accent),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: p.scrim,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: p.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.cardBorder),
        ),
        titleTextStyle: DaymarkText.sheetTitle.copyWith(color: p.ink),
        contentTextStyle: DaymarkText.preview.copyWith(color: p.inkSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: DaymarkText.custom(14, FontWeight.w500).copyWith(color: p.background),
        actionTextColor: p.isDark ? p.accent : p.accentSoft,
        closeIconColor: p.background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.onAccent : p.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accent : p.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.transparent : p.chipBorder,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accent : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(p.onAccent),
        side: BorderSide(color: p.accent, width: 1.6),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accent : p.muted,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceMuted,
        circularTrackColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.buttonDisabled,
          disabledForegroundColor: p.onButtonDisabled,
          minimumSize: const Size.fromHeight(52),
          textStyle: DaymarkText.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.buttonDisabled,
          disabledForegroundColor: p.onButtonDisabled,
          elevation: 0,
          textStyle: DaymarkText.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          side: BorderSide(color: p.line),
          textStyle: DaymarkText.custom(14.5, FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          textStyle: DaymarkText.custom(14, FontWeight.w600),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.inkSecondary,
        textColor: p.ink,
        titleTextStyle: DaymarkText.custom(14.5, FontWeight.w500).copyWith(color: p.ink),
        subtitleTextStyle: DaymarkText.meta.copyWith(color: p.muted),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        textStyle: DaymarkText.custom(14, FontWeight.w500).copyWith(color: p.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.cardBorder),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        headerBackgroundColor: p.surface,
        headerForegroundColor: p.ink,
        dividerColor: p.divider,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.onAccent;
          if (states.contains(WidgetState.disabled)) return p.disabled;
          return p.ink;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accent : null,
        ),
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.onAccent : p.accent,
        ),
        todayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accent : null,
        ),
        todayBorder: BorderSide(color: p.accent),
        yearForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.onAccent : p.ink,
        ),
        yearBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accent : null,
        ),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: p.accent),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: p.muted),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        dialBackgroundColor: p.surfaceMuted,
        dialHandColor: p.accent,
        dialTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.onAccent : p.ink,
        ),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accentSoft : p.surfaceMuted,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accent : p.ink,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accentSoft : Colors.transparent,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.accent : p.muted,
        ),
        dayPeriodBorderSide: BorderSide(color: p.chipBorder),
        entryModeIconColor: p.muted,
        helpTextStyle: DaymarkText.label.copyWith(color: p.muted),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: p.accent),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: p.muted),
      ),
    );
  }
}
