import 'package:flutter/material.dart';

/// Daymark Notes App Design Palette Tokens
class DaymarkPalette {
  final Color background;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color accentSoft;
  final Color line;
  final Color danger;
  final Brightness brightness;

  const DaymarkPalette({
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentSoft,
    required this.line,
    required this.danger,
    required this.brightness,
  });

  static const DaymarkPalette light = DaymarkPalette(
    background: Color(0xFFF6F7F5),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF252A27),
    muted: Color(0xFF858D87),
    accent: Color(0xFF5E7668),
    accentSoft: Color(0xFFEAF0EB),
    line: Color(0xFFE8ECE8),
    danger: Color(0xFFB95E58),
    brightness: Brightness.light,
  );

  static const DaymarkPalette dark = DaymarkPalette(
    background: Color(0xFF151816),
    surface: Color(0xFF202522),
    ink: Color(0xFFF0F3F1),
    muted: Color(0xFF8A948C),
    accent: Color(0xFF739280),
    accentSoft: Color(0xFF26342B),
    line: Color(0xFF2D352F),
    danger: Color(0xFFD9726C),
    brightness: Brightness.dark,
  );
}

class AppColors {
  /// Resolves the DaymarkPalette dynamically for the current BuildContext.
  static DaymarkPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? DaymarkPalette.dark : DaymarkPalette.light;
  }

  /// Default Light Palette
  static const Color backgroundLight = Color(0xFFF6F7F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color inkLight = Color(0xFF252A27);
  static const Color mutedLight = Color(0xFF858D87);
  static const Color accentLight = Color(0xFF5E7668);
  static const Color accentSoftLight = Color(0xFFEAF0EB);
  static const Color lineLight = Color(0xFFE8ECE8);
  static const Color dangerLight = Color(0xFFB95E58);

  /// Dark Palette
  static const Color backgroundDark = Color(0xFF151816);
  static const Color surfaceDark = Color(0xFF202522);
  static const Color inkDark = Color(0xFFF0F3F1);
  static const Color mutedDark = Color(0xFF8A948C);
  static const Color accentDark = Color(0xFF739280);
  static const Color accentSoftDark = Color(0xFF26342B);
  static const Color lineDark = Color(0xFF2D352F);
  static const Color dangerDark = Color(0xFFD9726C);

  /// Default System Colors
  static Color white = Colors.white;
  static Color black = Colors.black;
  static Color red = Colors.red;
  static Color blue = Colors.blue;
  static Color green = Colors.green;
  static Color yellow = Colors.yellow;

  /// Legacy compatibility colors mapped to Daymark tokens
  static Color bgColor = backgroundLight;
  static Color whiteColor = surfaceLight;
  static Color secondaryTextColor = mutedLight;
  static Color brandColor = accentLight;
  static Color iconColor = mutedLight;
  static Color iconTextColor = inkLight;

  // Neutral Color
  static const Color neutral100 = Color(0xff000000);
  static const Color neutral90 = Color(0xff3D3D3D);
  static const Color neutral80 = Color(0xff575757);
  static const Color neutral70 = Color(0xff6C6C6C);
  static const Color neutral60 = Color(0xffA9A9A9);
  static const Color neutral50 = Color(0xffBDBDBD);
  static const Color neutral40 = Color(0xffCDCDCD);
  static const Color neutral30 = Color(0xffDDDDDD);
  static const Color neutral20 = Color(0xffEAEAEA);
  static const Color neutral10 = Color(0xffF4F4F4);
  static const Color neutral05 = Color(0xffFBFBFB);

  // State Colors
  static const Color errorColor = dangerLight;
  static const Color successColor = Color(0xff0A5B2F);
  static const Color redBg = Color(0xFFFCF4F6);
  static const Color redBgLight = Color(0xFFFFE7E6);
  static const Color greenBg = Color(0xFFE9F2DA);
  static const Color greenBgLight = Color(0xFFE0F3E9);
  static const Color yellowBg = Color(0xFFFEFBF4);
  static const Color yellowBgLight = Color(0xFFFFF7E4);
  static const Color yellowBgDark = Color(0xFFF5EDD9);
  static const Color warningColor = Color(0xFFEAA300);

  // Peri Color
  static const Color priBlue00 = Color(0xffE6EDF5);
  static const Color priBlue10 = Color(0xffA8D4FD);
  static const Color priBlue20 = Color(0xff166BBA);
  static const Color priBlue30 = Color(0xff135A9C);
  static const Color priBlue40 = Color(0xff033666);
  static const Color priPurple40 = Color(0xff4A2D94);
}

extension DaymarkContext on BuildContext {
  DaymarkPalette get daymark => AppColors.of(this);
}
