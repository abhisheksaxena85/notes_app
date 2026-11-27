import 'package:flutter/material.dart';

/// The single accent colour of the app (design/README.md §1). Blue is the
/// default; switching to dark orange is a one-line change to [current].
enum DaymarkAccent {
  blue(light: Color(0xFF2F6BDB), dark: Color(0xFF6B9BF2)),
  darkOrange(light: Color(0xFFB9501A), dark: Color(0xFFE0793A));

  const DaymarkAccent({required this.light, required this.dark});

  final Color light;
  final Color dark;

  /// The accent the whole app uses.
  static const DaymarkAccent current = DaymarkAccent.blue;
}

/// Daymark colour tokens (design/README.md §1). Never use raw hex colours in
/// widgets; read these through `context.daymark`.
class DaymarkPalette {
  final Brightness brightness;

  /// Scaffold.
  final Color background;

  /// Cards, sheets.
  final Color surface;

  /// Bottom-nav bar fill.
  final Color navSurface;

  /// Search field, segmented-control track.
  final Color surfaceMuted;

  /// Tag chips and the note type tile.
  final Color tagFill;

  /// 32 px neutral icon tiles in settings rows, close button.
  final Color iconTile;

  /// Primary text and icons.
  final Color ink;

  /// Body previews, unselected chip text.
  final Color inkSecondary;

  /// Meta text, inactive nav, placeholders.
  final Color muted;

  /// Out-of-month days, disabled icons.
  final Color disabled;

  /// Hairlines (input borders, nav top border).
  final Color line;

  /// Card borders.
  final Color cardBorder;

  /// Dividers inside grouped cards.
  final Color divider;

  /// Unselected filter and category chips.
  final Color chipBorder;

  final Color accent;

  /// Text and icons on an [accent] fill.
  final Color onAccent;

  /// [accent] mixed over [surface] (12 % light, 20 % dark).
  final Color accentSoft;

  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;

  /// Outline of destructive outlined buttons (delete, sign out).
  final Color dangerBorder;

  /// Behind bottom sheets and the add menu.
  final Color scrim;

  final Color skeletonBase;
  final Color skeletonHighlight;

  /// Disabled primary button fill and text.
  final Color buttonDisabled;
  final Color onButtonDisabled;

  /// Label pills of the FAB add menu.
  final Color menuPill;

  DaymarkPalette._({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.navSurface,
    required this.surfaceMuted,
    required this.tagFill,
    required this.iconTile,
    required this.ink,
    required this.inkSecondary,
    required this.muted,
    required this.disabled,
    required this.line,
    required this.cardBorder,
    required this.divider,
    required this.chipBorder,
    required this.accent,
    required this.onAccent,
    required double accentSoftMix,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.dangerBorder,
    required this.scrim,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.buttonDisabled,
    required this.onButtonDisabled,
    required this.menuPill,
  }) : accentSoft = Color.lerp(surface, accent, accentSoftMix)!;

  bool get isDark => brightness == Brightness.dark;

  static final DaymarkPalette light = DaymarkPalette._(
    brightness: Brightness.light,
    background: const Color(0xFFF3F3F1),
    surface: const Color(0xFFFBFBFA),
    navSurface: const Color(0xFFFBFBFA),
    surfaceMuted: const Color(0xFFEAEAE7),
    tagFill: const Color(0xFFEDEDEA),
    iconTile: const Color(0xFFEFEFEC),
    ink: const Color(0xFF2A2B2F),
    inkSecondary: const Color(0xFF45474D),
    muted: const Color(0xFF6A6C72),
    disabled: const Color(0xFFB4B5B9),
    line: const Color(0xFFE3E3DF),
    cardBorder: const Color(0xFFE6E6E2),
    divider: const Color(0xFFECECE8),
    chipBorder: const Color(0xFFDCDCD8),
    accent: DaymarkAccent.current.light,
    onAccent: const Color(0xFFFBFBFA),
    accentSoftMix: 0.12,
    success: const Color(0xFF2F7A52),
    successSoft: const Color(0xFFE6F0EA),
    danger: const Color(0xFFB8433B),
    dangerSoft: const Color(0xFFF6E6E4),
    dangerBorder: const Color(0xFFE3D3D1),
    scrim: const Color.fromRGBO(32, 33, 36, 0.38),
    skeletonBase: const Color(0xFFE6E6E2),
    skeletonHighlight: const Color(0xFFF2F2EF),
    buttonDisabled: const Color(0xFFE3E3DF),
    onButtonDisabled: const Color(0xFF8A8C91),
    menuPill: const Color(0xFFFBFBFA),
  );

  static final DaymarkPalette dark = DaymarkPalette._(
    brightness: Brightness.dark,
    background: const Color(0xFF1C1D20),
    surface: const Color(0xFF25262A),
    navSurface: const Color(0xFF222327),
    surfaceMuted: const Color(0xFF2A2B2F),
    tagFill: const Color(0xFF2A2B2F),
    iconTile: const Color(0xFF2E2F34),
    ink: const Color(0xFFE8E8E5),
    inkSecondary: const Color(0xFFC4C5C9),
    muted: const Color(0xFFA0A2A8),
    disabled: const Color(0xFF5E6066),
    line: const Color(0xFF34363C),
    cardBorder: const Color(0xFF323338),
    divider: const Color(0xFF34363C),
    chipBorder: const Color(0xFF3A3B41),
    accent: DaymarkAccent.current.dark,
    onAccent: const Color(0xFF1C1D20),
    accentSoftMix: 0.20,
    success: const Color(0xFF5FB386),
    successSoft: const Color(0xFF22332A),
    danger: const Color(0xFFE8897F),
    dangerSoft: const Color(0xFF3A2826),
    dangerBorder: const Color(0xFF4A3330),
    scrim: const Color.fromRGBO(0, 0, 0, 0.5),
    skeletonBase: const Color(0xFF2C2D31),
    skeletonHighlight: const Color(0xFF38393E),
    buttonDisabled: const Color(0xFF2E2F34),
    onButtonDisabled: const Color(0xFF5E6066),
    menuPill: const Color(0xFF34353A),
  );
}

class AppColors {
  /// Resolves the DaymarkPalette for the current BuildContext's theme.
  static DaymarkPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? DaymarkPalette.dark : DaymarkPalette.light;
  }
}

extension DaymarkContext on BuildContext {
  DaymarkPalette get daymark => AppColors.of(this);
}
